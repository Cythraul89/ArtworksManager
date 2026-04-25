package com.example.artworksmanager.ui.collection

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.example.artworksmanager.databinding.BottomSheetFilterBinding
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.google.android.material.chip.Chip

class FilterSortBottomSheet : BottomSheetDialogFragment() {

    var currentMedium: String = ""
    var currentSort: String = "date"
    var availableMediums: List<String> = emptyList()
    var onApply: ((medium: String, sortBy: String) -> Unit)? = null

    private var _binding: BottomSheetFilterBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = BottomSheetFilterBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Sort radio
        when (currentSort) {
            "title"  -> binding.sortTitle.isChecked = true
            "artist" -> binding.sortArtist.isChecked = true
            else     -> binding.sortDate.isChecked = true
        }

        // Medium chips
        binding.mediumChipGroup.removeAllViews()
        availableMediums.forEach { medium ->
            val chip = Chip(requireContext()).apply {
                text = medium
                isCheckable = true
                isChecked = medium == currentMedium
            }
            binding.mediumChipGroup.addView(chip)
        }

        binding.resetButton.setOnClickListener {
            binding.sortDate.isChecked = true
            for (i in 0 until binding.mediumChipGroup.childCount) {
                (binding.mediumChipGroup.getChildAt(i) as? Chip)?.isChecked = false
            }
        }

        binding.applyButton.setOnClickListener {
            val sort = when {
                binding.sortTitle.isChecked  -> "title"
                binding.sortArtist.isChecked -> "artist"
                else                         -> "date"
            }
            val medium = (0 until binding.mediumChipGroup.childCount)
                .map { binding.mediumChipGroup.getChildAt(it) as Chip }
                .firstOrNull { it.isChecked }?.text?.toString() ?: ""
            onApply?.invoke(medium, sort)
            dismiss()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
