package com.example.artworksmanager.ui.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.artworksmanager.data.ArtistCount
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.data.ArtworkRepository
import com.example.artworksmanager.data.MediumCount
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

class DashboardViewModel(private val repository: ArtworkRepository) : ViewModel() {

    val totalCount: StateFlow<Int> = repository.getCount()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    val mediumCounts: StateFlow<List<MediumCount>> = repository.getMediumCounts()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val topArtists: StateFlow<List<ArtistCount>> = repository.getTopArtists()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val recentArtworks: StateFlow<List<Artwork>> = repository.getRecentArtworks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    companion object {
        fun factory(repository: ArtworkRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>) =
                DashboardViewModel(repository) as T
        }
    }
}
