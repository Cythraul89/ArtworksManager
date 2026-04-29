package com.example.artworksmanager.ui.addedit

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.view.*
import android.widget.Toast
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.fragment.findNavController
import androidx.navigation.fragment.navArgs
import androidx.recyclerview.widget.LinearLayoutManager
import com.bumptech.glide.Glide
import com.example.artworksmanager.ArtworksManagerApp
import com.example.artworksmanager.databinding.FragmentAddEditBinding
import com.example.artworksmanager.data.AppPreferences
import com.example.artworksmanager.data.ArtworkPhoto
import com.example.artworksmanager.data.Currency
import com.google.android.material.datepicker.MaterialDatePicker
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

/**
 * Fragment for creating a new artwork or editing an existing one, identified by the
 * [AddEditFragmentArgs.artworkId] nav argument (0 means new).
 */
class AddEditFragment : Fragment() {

    private var _binding: FragmentAddEditBinding? = null
    private val binding get() = _binding!!

    private val args: AddEditFragmentArgs by navArgs()
    private val viewModel: AddEditViewModel by viewModels {
        AddEditViewModel.factory((requireActivity().application as ArtworksManagerApp).repository)
    }

    private var currentPhotoPath = ""
    private var selectedDateMs: Long? = null
    private var pendingCameraPath = ""

    // Additional photos state
    // Each entry: existing DB record (null for newly added) paired with its local path.
    private val photoItems = mutableListOf<Pair<ArtworkPhoto?, String>>()
    private val photosToDelete = mutableListOf<ArtworkPhoto>()
    private var pickingAdditionalPhoto = false

    private val additionalPhotoAdapter: AdditionalPhotoAdapter = AdditionalPhotoAdapter { position ->
        val (record, _) = photoItems.removeAt(position)
        additionalPhotoAdapter.removeAt(position)
        if (record != null) photosToDelete.add(record)
    }

    private val pickMedia = registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        uri?.let {
            if (pickingAdditionalPhoto) { pickingAdditionalPhoto = false; addAdditionalPhotoFromUri(it) }
            else copyAndSetPhoto(it)
        }
    }

    private val takePicture = registerForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (success && pendingCameraPath.isNotEmpty()) {
            val path = pendingCameraPath
            pendingCameraPath = ""
            if (pickingAdditionalPhoto) {
                pickingAdditionalPhoto = false
                photoItems.add(Pair(null, path))
                additionalPhotoAdapter.addPhoto(path)
            } else {
                currentPhotoPath = path
                showPhotoPreview(currentPhotoPath)
            }
        }
    }

    private val requestCameraPermission = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) launchCamera()
        else Toast.makeText(requireContext(), "Camera permission is required to take photos", Toast.LENGTH_SHORT).show()
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentAddEditBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        ViewCompat.setOnApplyWindowInsetsListener(binding.scrollView) { v, insets ->
            val imeBottom = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
            v.updatePadding(bottom = imeBottom)
            insets
        }

        val isEdit = args.artworkId != 0
        binding.toolbar.title = if (isEdit) "Edit Artwork" else "Add Artwork"
        binding.toolbar.setNavigationOnClickListener { confirmDiscard() }

        // Type dropdown
        binding.typeAutoComplete.setAdapter(
            android.widget.ArrayAdapter(
                requireContext(), android.R.layout.simple_list_item_1,
                resources.getStringArray(com.example.artworksmanager.R.array.artwork_types)
            )
        )

        // Medium dropdown
        binding.mediumAutoComplete.setAdapter(
            android.widget.ArrayAdapter(
                requireContext(), android.R.layout.simple_list_item_1,
                resources.getStringArray(com.example.artworksmanager.R.array.mediums)
            )
        )

        // Currency dropdown
        val currencies = Currency.entries.toList()
        binding.currencyAutoComplete.setAdapter(
            android.widget.ArrayAdapter(
                requireContext(), android.R.layout.simple_list_item_1,
                currencies.map { it.code }.toTypedArray()
            )
        )
        val defaultCurrency = AppPreferences(requireContext()).currency
        binding.currencyAutoComplete.setText(defaultCurrency.code, false)
        binding.priceLayout.prefixText = defaultCurrency.symbol
        binding.currencyAutoComplete.setOnItemClickListener { _, _, position, _ ->
            binding.priceLayout.prefixText = currencies[position].symbol
        }

        // Main photo picker
        binding.photoCard.setOnClickListener { showPhotoSourceDialog(forAdditional = false) }

        // Additional photos RecyclerView
        binding.additionalPhotosRecycler.layoutManager =
            LinearLayoutManager(requireContext(), LinearLayoutManager.HORIZONTAL, false)
        binding.additionalPhotosRecycler.adapter = additionalPhotoAdapter

        // Add more photos button
        binding.addMorePhotosButton.setOnClickListener { showPhotoSourceDialog(forAdditional = true) }

        // Date picker
        binding.acquisitionDateInput.setOnClickListener { showDatePicker() }
        binding.acquisitionDateLayout.setEndIconOnClickListener { showDatePicker() }

        binding.saveButton.setOnClickListener { trySave() }

        if (isEdit) {
            viewModel.load(args.artworkId.toLong())
            viewLifecycleOwner.lifecycleScope.launch {
                viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                    launch { viewModel.artwork.collect { it?.let { a -> prefill(a) } } }
                    launch {
                        viewModel.additionalPhotos.collect { photos ->
                            photoItems.clear()
                            photoItems.addAll(photos.map { Pair(it, it.photoPath) })
                            additionalPhotoAdapter.submitList(photoItems.map { it.second })
                        }
                    }
                }
            }
        }

        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.savedId.collect { id ->
                    if (id != null) {
                        Snackbar.make(requireView(), com.example.artworksmanager.R.string.artwork_saved, Snackbar.LENGTH_SHORT).show()
                        if (args.artworkId == 0) {
                            findNavController().navigate(
                                AddEditFragmentDirections.actionAddEditToDetail(id.toInt())
                            )
                        } else {
                            findNavController().popBackStack()
                        }
                    }
                }
            }
        }
    }

    /** Populates all form fields from an existing [Artwork] when editing. */
    private fun prefill(a: com.example.artworksmanager.data.Artwork) {
        binding.titleInput.setText(a.title)
        binding.artistInput.setText(a.artist)
        binding.yearInput.setText(a.year?.toString() ?: "")
        if (a.type.isNotEmpty()) binding.typeAutoComplete.setText(a.type, false)
        binding.mediumAutoComplete.setText(a.medium, false)
        binding.heightInput.setText(a.heightCm?.toString() ?: "")
        binding.widthInput.setText(a.widthCm?.toString() ?: "")
        binding.depthInput.setText(a.depthCm?.toString() ?: "")
        binding.locationInput.setText(a.location)
        binding.priceInput.setText(a.purchasePrice?.toString() ?: "")
        binding.descriptionInput.setText(a.description)
        val artworkCurrency = if (a.currency.isNotEmpty()) Currency.fromCode(a.currency)
                              else AppPreferences(requireContext()).currency
        binding.currencyAutoComplete.setText(artworkCurrency.code, false)
        binding.priceLayout.prefixText = artworkCurrency.symbol
        if (a.acquisitionDate != null) {
            selectedDateMs = a.acquisitionDate
            binding.acquisitionDateInput.setText(
                SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date(a.acquisitionDate))
            )
        }
        if (a.photoPath.isNotEmpty()) {
            currentPhotoPath = a.photoPath
            showPhotoPreview(a.photoPath)
        }
    }

    private fun showPhotoSourceDialog(forAdditional: Boolean) {
        pickingAdditionalPhoto = forAdditional
        MaterialAlertDialogBuilder(requireContext())
            .setItems(arrayOf(
                getString(com.example.artworksmanager.R.string.take_photo),
                getString(com.example.artworksmanager.R.string.choose_gallery)
            )) { _, which ->
                if (which == 0) checkCameraPermissionAndLaunch() else launchGallery()
            }
            .show()
    }

    private fun checkCameraPermissionAndLaunch() {
        if (ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.CAMERA)
            == PackageManager.PERMISSION_GRANTED) launchCamera()
        else requestCameraPermission.launch(Manifest.permission.CAMERA)
    }

    private fun launchGallery() {
        pickMedia.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
    }

    private fun launchCamera() {
        val photoFile = File(requireContext().filesDir, "artworks/cam_${System.currentTimeMillis()}.jpg")
            .also { it.parentFile?.mkdirs() }
        pendingCameraPath = photoFile.absolutePath
        val uri = FileProvider.getUriForFile(
            requireContext(), "${requireContext().packageName}.fileprovider", photoFile
        )
        takePicture.launch(uri)
    }

    private fun copyAndSetPhoto(sourceUri: Uri) {
        val dest = File(requireContext().filesDir, "artworks/${System.currentTimeMillis()}.jpg")
            .also { it.parentFile?.mkdirs() }
        requireContext().contentResolver.openInputStream(sourceUri)?.use { input ->
            FileOutputStream(dest).use { out -> input.copyTo(out) }
        }
        currentPhotoPath = dest.absolutePath
        showPhotoPreview(currentPhotoPath)
    }

    private fun addAdditionalPhotoFromUri(sourceUri: Uri) {
        val dest = File(requireContext().filesDir, "artworks/${System.currentTimeMillis()}.jpg")
            .also { it.parentFile?.mkdirs() }
        requireContext().contentResolver.openInputStream(sourceUri)?.use { input ->
            FileOutputStream(dest).use { out -> input.copyTo(out) }
        }
        val path = dest.absolutePath
        photoItems.add(Pair(null, path))
        additionalPhotoAdapter.addPhoto(path)
    }

    private fun showPhotoPreview(path: String) {
        Glide.with(binding.photoPreview).load(File(path)).centerCrop().into(binding.photoPreview)
        binding.photoHint.visibility = View.GONE
        binding.photoPreview.visibility = View.VISIBLE
    }

    private fun showDatePicker() {
        MaterialDatePicker.Builder.datePicker()
            .setTitleText("Acquisition date")
            .apply { if (selectedDateMs != null) setSelection(selectedDateMs) }
            .build()
            .apply {
                addOnPositiveButtonClickListener { ms ->
                    selectedDateMs = ms
                    binding.acquisitionDateInput.setText(
                        SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date(ms))
                    )
                }
            }
            .show(parentFragmentManager, "date_picker")
    }

    /** Validates the form and delegates persistence to the ViewModel. */
    private fun trySave() {
        val title = binding.titleInput.text?.toString()?.trim() ?: ""
        if (title.isEmpty()) {
            binding.titleLayout.error = getString(com.example.artworksmanager.R.string.error_title_required)
            binding.scrollView.smoothScrollTo(0, 0)
            return
        }
        binding.titleLayout.error = null

        viewModel.save(
            id              = args.artworkId.toLong(),
            title           = title,
            artist          = binding.artistInput.text?.toString()?.trim() ?: "",
            year            = binding.yearInput.text?.toString()?.toIntOrNull(),
            type            = binding.typeAutoComplete.text?.toString()?.trim() ?: "",
            medium          = binding.mediumAutoComplete.text?.toString()?.trim() ?: "",
            heightCm        = binding.heightInput.text?.toString()?.toFloatOrNull(),
            widthCm         = binding.widthInput.text?.toString()?.toFloatOrNull(),
            depthCm         = binding.depthInput.text?.toString()?.toFloatOrNull(),
            location        = binding.locationInput.text?.toString()?.trim() ?: "",
            acquisitionDate = selectedDateMs,
            currency        = binding.currencyAutoComplete.text?.toString()?.trim() ?: "",
            purchasePrice   = binding.priceInput.text?.toString()?.toDoubleOrNull(),
            description     = binding.descriptionInput.text?.toString()?.trim() ?: "",
            photoPath       = currentPhotoPath,
            photosToDelete  = photosToDelete.toList(),
            newPhotoPaths   = photoItems.filter { it.first == null }.map { it.second }
        )
    }

    /** Shows a discard-changes dialog if the user has entered any data; pops back immediately otherwise. */
    private fun confirmDiscard() {
        val dirty = binding.titleInput.text?.isNotEmpty() == true ||
                    binding.artistInput.text?.isNotEmpty() == true
        if (!dirty) { findNavController().popBackStack(); return }
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(com.example.artworksmanager.R.string.discard_changes)
            .setNegativeButton(com.example.artworksmanager.R.string.keep_editing, null)
            .setPositiveButton(com.example.artworksmanager.R.string.discard) { _, _ ->
                findNavController().popBackStack()
            }
            .show()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
