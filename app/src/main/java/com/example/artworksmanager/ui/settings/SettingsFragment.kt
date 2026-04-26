package com.example.artworksmanager.ui.settings

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewModelScope
import com.example.artworksmanager.ArtworksManagerApp
import com.example.artworksmanager.R
import com.example.artworksmanager.data.ArtworkRepository
import com.example.artworksmanager.databinding.FragmentSettingsBinding
import com.example.artworksmanager.util.PdfExporter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class SettingsFragment : Fragment() {

    private var _binding: FragmentSettingsBinding? = null
    private val binding get() = _binding!!

    private val viewModel: SettingsViewModel by viewModels {
        SettingsViewModel.factory((requireActivity().application as ArtworksManagerApp).repository)
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentSettingsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.exportRow.setOnClickListener { exportPdf() }
        binding.nextcloudRow.setOnClickListener {
            Toast.makeText(requireContext(), R.string.nextcloud_coming_soon, Toast.LENGTH_SHORT).show()
        }
    }

    private fun exportPdf() {
        binding.exportProgress.visibility = View.VISIBLE
        binding.exportRow.isEnabled = false

        viewLifecycleOwner.lifecycleScope.launch {
            val ctx = requireContext()
            try {
                // Query Room directly rather than reading the StateFlow's cached
                // value: getAllArtworks().first() suspends until Room emits the
                // real result, so it works even on the very first tap.
                val artworks = withContext(Dispatchers.IO) {
                    viewModel.loadArtworksNow()
                }
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

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}

class SettingsViewModel(private val repository: ArtworkRepository) : ViewModel() {

    /** One-shot DB read — suspends until Room emits the first result. */
    suspend fun loadArtworksNow() = repository.getAllArtworks().first()

    companion object {
        fun factory(repository: ArtworkRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>) =
                SettingsViewModel(repository) as T
        }
    }
}
