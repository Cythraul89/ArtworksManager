package com.example.artworksmanager.ui.collection

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.data.ArtworkRepository
import kotlinx.coroutines.flow.*

class CollectionViewModel(private val repository: ArtworkRepository) : ViewModel() {

    private val _searchQuery  = MutableStateFlow("")
    private val _filterMedium = MutableStateFlow("")
    private val _filterArtist = MutableStateFlow("")
    private val _sortBy       = MutableStateFlow("date") // "title" | "artist" | "date"

    val searchQuery:  StateFlow<String> = _searchQuery.asStateFlow()
    val filterMedium: StateFlow<String> = _filterMedium.asStateFlow()
    val sortBy:       StateFlow<String> = _sortBy.asStateFlow()

    val artworks: StateFlow<List<Artwork>> = combine(
        repository.getAllArtworks(),
        _searchQuery,
        _filterMedium,
        _filterArtist,
        _sortBy
    ) { list, query, medium, artist, sort ->
        list.filter { artwork ->
            (query.isBlank() || artwork.title.contains(query, true) || artwork.artist.contains(query, true))
                && (medium.isBlank() || artwork.medium == medium)
                && (artist.isBlank() || artwork.artist == artist)
        }.sortedWith(
            when (sort) {
                "title"  -> compareBy { it.title }
                "artist" -> compareBy { it.artist }
                else     -> compareByDescending { it.acquisitionDate ?: it.createdAt }
            }
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val distinctMediums: StateFlow<List<String>> = repository.getDistinctMediums()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun setSearch(query: String)  { _searchQuery.value = query }
    fun setFilterMedium(m: String) { _filterMedium.value = m }
    fun setFilterArtist(a: String) { _filterArtist.value = a }
    fun setSortBy(s: String)      { _sortBy.value = s }

    fun applyFilter(medium: String, sortBy: String) {
        _filterMedium.value = medium
        _sortBy.value = sortBy
    }

    fun resetFilters() {
        _searchQuery.value  = ""
        _filterMedium.value = ""
        _filterArtist.value = ""
        _sortBy.value       = "date"
    }

    companion object {
        fun factory(repository: ArtworkRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>) =
                CollectionViewModel(repository) as T
        }
    }
}
