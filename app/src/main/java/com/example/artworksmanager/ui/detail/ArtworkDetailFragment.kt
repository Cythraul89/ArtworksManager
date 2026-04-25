package com.example.artworksmanager.ui.detail

import android.os.Bundle
import android.view.*
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.fragment.findNavController
import androidx.navigation.fragment.navArgs
import com.bumptech.glide.Glide
import com.example.artworksmanager.ArtworksManagerApp
import com.example.artworksmanager.R
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.databinding.FragmentArtworkDetailBinding
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar
import kotlinx.coroutines.launch
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class ArtworkDetailFragment : Fragment() {

    private var _binding: FragmentArtworkDetailBinding? = null
    private val binding get() = _binding!!

    private val args: ArtworkDetailFragmentArgs by navArgs()

    private val viewModel: ArtworkDetailViewModel by viewModels {
        ArtworkDetailViewModel.factory((requireActivity().application as ArtworksManagerApp).repository)
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentArtworkDetailBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        viewModel.load(args.artworkId)

        binding.toolbar.setNavigationOnClickListener { findNavController().popBackStack() }
        binding.toolbar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_edit   -> { navigateToEdit(); true }
                R.id.action_delete -> { showDeleteDialog(); true }
                else -> false
            }
        }
        binding.toolbar.inflateMenu(R.menu.detail_menu)

        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.artwork.collect { artwork -> artwork?.let { bindArtwork(it) } }
            }
        }
    }

    private fun bindArtwork(a: Artwork) {
        binding.toolbar.title = a.title
        binding.title.text  = a.title
        binding.artistYear.text = buildString {
            if (a.artist.isNotEmpty()) append(a.artist)
            if (a.year != null) { if (isNotEmpty()) append("  ·  "); append(a.year) }
        }

        if (a.photoPath.isNotEmpty()) {
            Glide.with(binding.photo).load(File(a.photoPath)).centerCrop().into(binding.photo)
            binding.photo.visibility = View.VISIBLE
        } else {
            binding.photo.visibility = View.GONE
        }

        fun row(label: View, value: android.widget.TextView, text: String) {
            val visible = text.isNotEmpty()
            label.visibility = if (visible) View.VISIBLE else View.GONE
            value.visibility = if (visible) View.VISIBLE else View.GONE
            value.text = text
        }

        row(binding.labelMedium,      binding.valueMedium,      a.medium)
        row(binding.labelLocation,    binding.valueLocation,    a.location)
        row(binding.labelDescription, binding.valueDescription, a.description)

        val dims = buildString {
            a.heightCm?.let { append("$it") }
            a.widthCm?.let  { append(" × $it") }
            a.depthCm?.let  { append(" × $it") }
            if (isNotEmpty()) append(" cm")
        }
        row(binding.labelDimensions, binding.valueDimensions, dims)

        val acq = buildString {
            if (a.acquisitionDate != null) {
                append(SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date(a.acquisitionDate)))
            }
            if (a.purchasePrice != null) {
                if (isNotEmpty()) append("  ·  ")
                append("€%.2f".format(a.purchasePrice))
            }
        }
        row(binding.labelAcquired, binding.valueAcquired, acq)
    }

    private fun navigateToEdit() {
        findNavController().navigate(
            ArtworkDetailFragmentDirections.actionDetailToAddEdit(args.artworkId)
        )
    }

    private fun showDeleteDialog() {
        val artwork = viewModel.artwork.value ?: return
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(R.string.delete_artwork)
            .setMessage(getString(R.string.delete_confirm, artwork.title))
            .setNegativeButton(R.string.cancel, null)
            .setPositiveButton(R.string.delete) { _, _ ->
                viewModel.delete(artwork) {
                    Snackbar.make(requireView(), R.string.artwork_deleted, Snackbar.LENGTH_SHORT).show()
                    findNavController().popBackStack()
                }
            }
            .show()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
