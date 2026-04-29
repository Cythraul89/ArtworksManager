package com.example.artworksmanager.ui.dashboard

import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.artworksmanager.ArtworksManagerApp
import com.example.artworksmanager.R
import com.example.artworksmanager.data.ArtistCount
import com.example.artworksmanager.data.Currency
import com.example.artworksmanager.data.CurrencyTotal
import com.example.artworksmanager.data.MediumCount
import com.example.artworksmanager.databinding.FragmentDashboardBinding
import com.google.android.material.chip.Chip
import kotlinx.coroutines.launch

/**
 * Fragment for the home dashboard, showing collection statistics, medium chips,
 * top-artist rows, a horizontally scrolling carousel of recent artworks, and
 * a Collection Value card with per-currency totals and a live-rate grand total.
 */
class DashboardFragment : Fragment() {

    private var _binding: FragmentDashboardBinding? = null
    private val binding get() = _binding!!

    private val viewModel: DashboardViewModel by viewModels {
        val app = requireActivity().application as ArtworksManagerApp
        DashboardViewModel.factory(app.repository, app.preferences)
    }

    private val recentAdapter = RecentArtworkAdapter { artwork ->
        findNavController().navigate(
            DashboardFragmentDirections.actionDashboardToDetail(artwork.id.toInt())
        )
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentDashboardBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.recentRecycler.layoutManager =
            LinearLayoutManager(requireContext(), LinearLayoutManager.HORIZONTAL, false)
        binding.recentRecycler.adapter = recentAdapter

        binding.fab.setOnClickListener {
            findNavController().navigate(DashboardFragmentDirections.actionDashboardToAddEdit())
        }

        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                launch { viewModel.totalCount.collect { updateCount(it) } }
                launch { viewModel.mediumCounts.collect { updateMediumChips(it) } }
                launch { viewModel.topArtists.collect { updateArtists(it) } }
                launch { viewModel.recentArtworks.collect { updateRecent(it) } }
                launch { viewModel.priceTotals.collect { updateValueTotals(it) } }
                launch { viewModel.valueState.collect { updateValueState(it) } }
            }
        }
    }

    private fun updateCount(count: Int) {
        binding.totalCount.text = count.toString()
        binding.emptyState.visibility = if (count == 0) View.VISIBLE else View.GONE
        binding.contentGroup.visibility = if (count == 0) View.GONE else View.VISIBLE
    }

    /** Rebuilds the medium chip group; tapping a chip navigates to the collection pre-filtered by that medium. */
    private fun updateMediumChips(mediums: List<MediumCount>) {
        binding.mediumChipGroup.removeAllViews()
        mediums.forEach { mc ->
            val chip = Chip(requireContext()).apply {
                text = "${mc.medium} (${mc.count})"
                isClickable = true
                setOnClickListener {
                    findNavController().navigate(
                        DashboardFragmentDirections.actionDashboardToCollection(
                            filterMedium = mc.medium, filterArtist = ""
                        )
                    )
                }
            }
            binding.mediumChipGroup.addView(chip)
        }
    }

    /** Rebuilds the top-artists list; tapping a row navigates to the collection pre-filtered by that artist. */
    private fun updateArtists(artists: List<ArtistCount>) {
        binding.artistsContainer.removeAllViews()
        artists.forEach { ac ->
            val row = layoutInflater.inflate(
                android.R.layout.simple_list_item_2,
                binding.artistsContainer,
                false
            )
            row.findViewById<android.widget.TextView>(android.R.id.text1).text = ac.artist
            row.findViewById<android.widget.TextView>(android.R.id.text2).text = "${ac.count} artworks"
            row.setOnClickListener {
                findNavController().navigate(
                    DashboardFragmentDirections.actionDashboardToCollection(
                        filterMedium = "", filterArtist = ac.artist
                    )
                )
            }
            binding.artistsContainer.addView(row)
        }
    }

    private fun updateRecent(artworks: List<com.example.artworksmanager.data.Artwork>) {
        recentAdapter.submitList(artworks)
        binding.recentSection.visibility = if (artworks.isEmpty()) View.GONE else View.VISIBLE
    }

    /** Rebuilds the per-currency rows; hides the card entirely when no prices are recorded. */
    private fun updateValueTotals(totals: List<CurrencyTotal>) {
        binding.collectionValueSection.visibility = if (totals.isEmpty()) View.GONE else View.VISIBLE
        binding.valueTotalsContainer.removeAllViews()
        val dp4 = (4 * resources.displayMetrics.density).toInt()
        totals.forEach { ct ->
            val row = LinearLayout(requireContext()).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).also { it.bottomMargin = dp4 }
            }
            row.addView(TextView(requireContext()).apply {
                text = ct.currency
                textSize = 14f
                setTextColor(ContextCompat.getColor(requireContext(), R.color.text_secondary))
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            })
            row.addView(TextView(requireContext()).apply {
                val symbol = Currency.fromCode(ct.currency).symbol
                text = "$symbol${"%.2f".format(ct.total)}"
                textSize = 14f
                gravity = Gravity.END
                setTextColor(ContextCompat.getColor(requireContext(), R.color.text_primary))
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 2f)
            })
            binding.valueTotalsContainer.addView(row)
        }
        binding.valueDivider.visibility = if (totals.isEmpty()) View.GONE else View.VISIBLE
    }

    private fun updateValueState(state: ValueState) {
        when (state) {
            ValueState.Loading -> {
                binding.valueProgress.visibility = View.VISIBLE
                binding.valueConvertedRow.visibility = View.GONE
                binding.valueUnavailable.visibility = View.GONE
            }
            is ValueState.Ready -> {
                binding.valueProgress.visibility = View.GONE
                binding.valueConvertedRow.visibility = View.VISIBLE
                binding.valueUnavailable.visibility = View.GONE
                val symbol = Currency.fromCode(state.currency).symbol
                val prefix = if (state.isLive) "≈ " else ""
                binding.valueConvertedAmount.text = "$prefix$symbol${"%.2f".format(state.amount)}"
                binding.valueRatesLabel.text = if (state.isLive) getString(R.string.live_rates) else ""
            }
            ValueState.Unavailable -> {
                binding.valueProgress.visibility = View.GONE
                binding.valueConvertedRow.visibility = View.GONE
                binding.valueUnavailable.visibility = View.VISIBLE
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
