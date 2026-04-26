package com.example.artworksmanager.ui.collection

import android.os.Bundle
import android.view.*
import androidx.appcompat.widget.SearchView
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.fragment.findNavController
import androidx.navigation.fragment.navArgs
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.artworksmanager.ArtworksManagerApp
import com.example.artworksmanager.R
import com.example.artworksmanager.databinding.FragmentCollectionBinding
import kotlinx.coroutines.launch

/**
 * Fragment that displays the full artwork collection with search, filter, and sort capabilities.
 * Accepts optional pre-set filter arguments from the Dashboard via Safe Args.
 */
class CollectionFragment : Fragment() {

    private var _binding: FragmentCollectionBinding? = null
    private val binding get() = _binding!!

    private val args: CollectionFragmentArgs by navArgs()

    private val viewModel: CollectionViewModel by viewModels {
        CollectionViewModel.factory((requireActivity().application as ArtworksManagerApp).repository)
    }

    private val adapter = ArtworkAdapter { artwork ->
        findNavController().navigate(
            CollectionFragmentDirections.actionCollectionToDetail(artwork.id.toInt())
        )
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentCollectionBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Apply args passed from Dashboard
        if (args.filterMedium.isNotEmpty()) viewModel.setFilterMedium(args.filterMedium)
        if (args.filterArtist.isNotEmpty()) viewModel.setFilterArtist(args.filterArtist)

        setupRecyclerView()
        setupToolbar()

        binding.fab.setOnClickListener {
            findNavController().navigate(CollectionFragmentDirections.actionCollectionToAddEdit())
        }

        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                launch {
                    viewModel.artworks.collect { list ->
                        adapter.submitList(list)
                        binding.emptyText.visibility = if (list.isEmpty()) View.VISIBLE else View.GONE
                    }
                }
            }
        }
    }

    private fun setupRecyclerView() {
        binding.recyclerView.adapter = adapter
        setGridLayout(true)
    }

    private fun setupToolbar() {
        binding.toolbar.inflateMenu(R.menu.collection_menu)

        val searchItem = binding.toolbar.menu.findItem(R.id.action_search)
        val searchView = searchItem?.actionView as? SearchView
        searchView?.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(q: String?) = false
            override fun onQueryTextChange(q: String?): Boolean {
                viewModel.setSearch(q ?: "")
                return true
            }
        })

        binding.toolbar.menu.findItem(R.id.action_filter)?.setOnMenuItemClickListener {
            showFilterSheet()
            true
        }

        binding.toolbar.menu.findItem(R.id.action_toggle_layout)?.setOnMenuItemClickListener {
            val nowGrid = !adapter.isGridLayout
            setGridLayout(nowGrid)
            true
        }
    }

    /** Switches the RecyclerView between a two-column grid and a linear list. */
    private fun setGridLayout(grid: Boolean) {
        adapter.isGridLayout = grid
        binding.recyclerView.layoutManager = if (grid)
            GridLayoutManager(requireContext(), 2)
        else
            LinearLayoutManager(requireContext())
    }

    private fun showFilterSheet() {
        FilterSortBottomSheet().apply {
            currentMedium = viewModel.filterMedium.value
            currentSort = viewModel.sortBy.value
            availableMediums = viewModel.distinctMediums.value
            onApply = { medium, sort -> viewModel.applyFilter(medium, sort) }
        }.show(childFragmentManager, "filter")
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
