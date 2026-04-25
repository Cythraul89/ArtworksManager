package com.example.artworksmanager.ui.addedit

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.view.*
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.fragment.findNavController
import androidx.navigation.fragment.navArgs
import com.bumptech.glide.Glide
import com.example.artworksmanager.ArtworksManagerApp
import com.example.artworksmanager.databinding.FragmentAddEditBinding
import com.google.android.material.datepicker.MaterialDatePicker
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

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

    private val pickMedia = registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        uri?.let { copyAndSetPhoto(it) }
    }

    private val takePicture = registerForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (success && pendingCameraPath.isNotEmpty()) {
            currentPhotoPath = pendingCameraPath
            showPhotoPreview(currentPhotoPath)
        }
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentAddEditBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val isEdit = args.artworkId != 0L
        binding.toolbar.title = if (isEdit) "Edit Artwork" else "Add Artwork"
        binding.toolbar.setNavigationOnClickListener { confirmDiscard() }

        // Medium dropdown
        val adapter = android.widget.ArrayAdapter(
            requireContext(),
            android.R.layout.simple_list_item_1,
            resources.getStringArray(com.example.artworksmanager.R.array.mediums)
        )
        binding.mediumAutoComplete.setAdapter(adapter)

        // Photo picker
        binding.photoCard.setOnClickListener { showPhotoSourceDialog() }

        // Date picker
        binding.acquisitionDateInput.setOnClickListener { showDatePicker() }
        binding.acquisitionDateLayout.setEndIconOnClickListener { showDatePicker() }

        // Save
        binding.saveButton.setOnClickListener { trySave() }

        if (isEdit) {
            viewModel.load(args.artworkId)
            viewLifecycleOwner.lifecycleScope.launch {
                viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                    viewModel.artwork.collect { artwork ->
                        artwork?.let { prefill(it) }
                    }
                }
            }
        }

        // Navigate after save
        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.savedId.collect { id ->
                    if (id != null) {
                        Snackbar.make(requireView(), com.example.artworksmanager.R.string.artwork_saved, Snackbar.LENGTH_SHORT).show()
                        if (args.artworkId == 0L) {
                            // New artwork — navigate forward to detail
                            findNavController().navigate(
                                AddEditFragmentDirections.actionAddEditToDetail(id)
                            )
                        } else {
                            // Edit — pop back to existing detail (it auto-reloads from DB)
                            findNavController().popBackStack()
                        }
                    }
                }
            }
        }
    }

    private fun prefill(a: com.example.artworksmanager.data.Artwork) {
        binding.titleInput.setText(a.title)
        binding.artistInput.setText(a.artist)
        binding.yearInput.setText(a.year?.toString() ?: "")
        binding.mediumAutoComplete.setText(a.medium, false)
        binding.heightInput.setText(a.heightCm?.toString() ?: "")
        binding.widthInput.setText(a.widthCm?.toString() ?: "")
        binding.depthInput.setText(a.depthCm?.toString() ?: "")
        binding.locationInput.setText(a.location)
        binding.priceInput.setText(a.purchasePrice?.toString() ?: "")
        binding.descriptionInput.setText(a.description)
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

    private fun showPhotoSourceDialog() {
        MaterialAlertDialogBuilder(requireContext())
            .setItems(arrayOf(
                getString(com.example.artworksmanager.R.string.take_photo),
                getString(com.example.artworksmanager.R.string.choose_gallery)
            )) { _, which ->
                if (which == 0) launchCamera() else launchGallery()
            }
            .show()
    }

    private fun launchGallery() {
        pickMedia.launch(androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia.ImageOnly)
    }

    private fun launchCamera() {
        val photoFile = File(requireContext().filesDir, "artworks/cam_${System.currentTimeMillis()}.jpg")
            .also { it.parentFile?.mkdirs() }
        pendingCameraPath = photoFile.absolutePath
        val uri = FileProvider.getUriForFile(
            requireContext(),
            "${requireContext().packageName}.fileprovider",
            photoFile
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

    private fun trySave() {
        val title = binding.titleInput.text?.toString()?.trim() ?: ""
        if (title.isEmpty()) {
            binding.titleLayout.error = getString(com.example.artworksmanager.R.string.error_title_required)
            binding.scrollView.smoothScrollTo(0, 0)
            return
        }
        binding.titleLayout.error = null

        viewModel.save(
            id           = args.artworkId,
            title        = title,
            artist       = binding.artistInput.text?.toString()?.trim() ?: "",
            year         = binding.yearInput.text?.toString()?.toIntOrNull(),
            medium       = binding.mediumAutoComplete.text?.toString()?.trim() ?: "",
            heightCm     = binding.heightInput.text?.toString()?.toFloatOrNull(),
            widthCm      = binding.widthInput.text?.toString()?.toFloatOrNull(),
            depthCm      = binding.depthInput.text?.toString()?.toFloatOrNull(),
            location     = binding.locationInput.text?.toString()?.trim() ?: "",
            acquisitionDate = selectedDateMs,
            purchasePrice   = binding.priceInput.text?.toString()?.toDoubleOrNull(),
            description  = binding.descriptionInput.text?.toString()?.trim() ?: "",
            photoPath    = currentPhotoPath
        )
    }

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
