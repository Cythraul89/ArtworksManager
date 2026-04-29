package com.example.artworksmanager.ui.settings

import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import com.example.artworksmanager.ArtworksManagerApp
import com.example.artworksmanager.R
import com.example.artworksmanager.data.AppPreferences
import com.example.artworksmanager.data.ArtworkRepository
import com.example.artworksmanager.data.Currency
import com.example.artworksmanager.databinding.FragmentSettingsBinding
import com.example.artworksmanager.data.ArtworkPhoto
import com.example.artworksmanager.util.BackupExporter
import com.example.artworksmanager.util.BackupImporter
import com.example.artworksmanager.util.PdfExporter
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Fragment for the settings screen, providing currency selection, PDF export,
 * zip backup export/import, and a placeholder for future Nextcloud sync integration.
 */
class SettingsFragment : Fragment() {

    private var _binding: FragmentSettingsBinding? = null
    private val binding get() = _binding!!

    private val viewModel: SettingsViewModel by viewModels {
        SettingsViewModel.factory((requireActivity().application as ArtworksManagerApp).repository)
    }

    private val prefs: AppPreferences
        get() = (requireActivity().application as ArtworksManagerApp).preferences

    private val createBackupDocument = registerForActivityResult(
        ActivityResultContracts.CreateDocument("application/zip")
    ) { uri -> if (uri != null) writeBackupToUri(uri) }

    private val openBackupDocument = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri -> if (uri != null) confirmAndImport(uri) }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentSettingsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        updateCurrencyLabel()
        binding.currencyRow.setOnClickListener { showCurrencyDialog() }

        binding.exportRow.setOnClickListener { exportPdf() }
        binding.backupExportRow.setOnClickListener { launchBackupPicker() }
        binding.backupImportRow.setOnClickListener { openBackupDocument.launch(arrayOf("application/zip")) }
        binding.nextcloudRow.setOnClickListener {
            Toast.makeText(requireContext(), R.string.nextcloud_coming_soon, Toast.LENGTH_SHORT).show()
        }
    }

    private fun updateCurrencyLabel() {
        binding.currencyValue.text = prefs.currency.label
    }

    /** Shows a single-choice dialog to select the display currency. */
    private fun showCurrencyDialog() {
        val currencies = Currency.entries
        val labels = currencies.map { it.label }.toTypedArray()
        val current = currencies.indexOf(prefs.currency).coerceAtLeast(0)
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(R.string.pref_currency_dialog_title)
            .setSingleChoiceItems(labels, current) { dialog, which ->
                prefs.currency = currencies[which]
                updateCurrencyLabel()
                dialog.dismiss()
            }
            .show()
    }

    /** Fetches all artworks, generates a PDF via [PdfExporter], and opens the system share sheet. */
    private fun exportPdf() {
        binding.exportProgress.visibility = View.VISIBLE
        binding.exportRow.isEnabled = false

        viewLifecycleOwner.lifecycleScope.launch {
            val ctx = requireContext()
            try {
                val artworks = withContext(Dispatchers.IO) { viewModel.loadArtworksNow() }
                if (artworks.isEmpty()) {
                    Toast.makeText(ctx, "No artworks to export", Toast.LENGTH_SHORT).show()
                } else {
                    val exporter = PdfExporter(ctx)
                    val uri = withContext(Dispatchers.IO) { exporter.generateUri(artworks) }
                    exporter.share(uri)
                }
            } catch (e: Exception) {
                Toast.makeText(ctx, R.string.export_error, Toast.LENGTH_SHORT).show()
            }
            binding.exportProgress.visibility = View.GONE
            binding.exportRow.isEnabled = true
        }
    }

    /** Opens the SAF file-picker so the user chooses where to save the backup zip. */
    private fun launchBackupPicker() {
        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        createBackupDocument.launch("artworks_backup_$timestamp.zip")
    }

    /** Fetches artworks and writes the backup zip to the SAF [uri] chosen by the user. */
    private fun writeBackupToUri(uri: Uri) {
        binding.backupProgress.visibility = View.VISIBLE
        binding.backupExportRow.isEnabled = false

        viewLifecycleOwner.lifecycleScope.launch {
            val ctx = requireContext()
            try {
                val artworks = withContext(Dispatchers.IO) { viewModel.loadArtworksNow() }
                val photosByArtwork = withContext(Dispatchers.IO) { viewModel.loadAllPhotosNow() }
                withContext(Dispatchers.IO) { BackupExporter(ctx).writeTo(uri, artworks, photosByArtwork) }
                Toast.makeText(ctx, R.string.backup_success, Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                Toast.makeText(ctx, R.string.backup_error, Toast.LENGTH_SHORT).show()
            }
            binding.backupProgress.visibility = View.GONE
            binding.backupExportRow.isEnabled = true
        }
    }

    /** Shows a confirmation dialog before replacing the collection with [uri]. */
    private fun confirmAndImport(uri: Uri) {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(R.string.import_confirm_title)
            .setMessage(R.string.import_confirm_message)
            .setNegativeButton(R.string.cancel, null)
            .setPositiveButton(R.string.import_replace) { _, _ -> doImport(uri) }
            .show()
    }

    /** Reads the backup zip at [uri], replaces the current collection, and reports the result. */
    private fun doImport(uri: Uri) {
        binding.backupImportProgress.visibility = View.VISIBLE
        binding.backupImportRow.isEnabled = false

        viewLifecycleOwner.lifecycleScope.launch {
            val ctx = requireContext()
            try {
                val data = withContext(Dispatchers.IO) { BackupImporter(ctx).importFrom(uri) }
                withContext(Dispatchers.IO) { viewModel.replaceAll(data.artworks, data.photos) }
                Toast.makeText(
                    ctx,
                    ctx.getString(R.string.import_success, data.artworks.size),
                    Toast.LENGTH_SHORT
                ).show()
            } catch (e: Exception) {
                Toast.makeText(ctx, R.string.import_error, Toast.LENGTH_SHORT).show()
            }
            binding.backupImportProgress.visibility = View.GONE
            binding.backupImportRow.isEnabled = true
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}

/**
 * ViewModel for [SettingsFragment] that provides a one-shot artwork query
 * used to populate the PDF export and backup, and a replace-all for import.
 */
class SettingsViewModel(private val repository: ArtworkRepository) : ViewModel() {

    /** One-shot DB read — suspends until Room emits the first result. */
    suspend fun loadArtworksNow() = repository.getAllArtworks().first()

    /** One-shot read of all additional photos grouped by artwork id. */
    suspend fun loadAllPhotosNow(): Map<Long, List<ArtworkPhoto>> = repository.getAllPhotosNow()

    /** Atomically clears the collection and inserts [artworks] and their [photos]. */
    suspend fun replaceAll(artworks: List<com.example.artworksmanager.data.Artwork>, photos: List<ArtworkPhoto> = emptyList()) =
        repository.replaceAll(artworks, photos)

    companion object {
        fun factory(repository: ArtworkRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>) =
                SettingsViewModel(repository) as T
        }
    }
}
