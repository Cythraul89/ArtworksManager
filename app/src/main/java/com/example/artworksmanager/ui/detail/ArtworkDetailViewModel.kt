package com.example.artworksmanager.ui.detail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.data.ArtworkRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/**
 * ViewModel for [ArtworkDetailFragment] that keeps the displayed artwork in sync with
 * the database and provides a coroutine-safe delete operation.
 */
class ArtworkDetailViewModel(private val repository: ArtworkRepository) : ViewModel() {

    private val _artworkId = MutableStateFlow<Long?>(null)

    val artwork: StateFlow<Artwork?> = _artworkId
        .filterNotNull()
        .flatMapLatest { id -> repository.getAllArtworks().map { list -> list.firstOrNull { it.id == id } } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    /** Triggers loading the artwork with the given [id]; the result is emitted via [artwork]. */
    fun load(id: Long) { _artworkId.value = id }

    /** Deletes [artwork] from the repository and invokes [onDone] on the main thread when finished. */
    fun delete(artwork: Artwork, onDone: () -> Unit) {
        viewModelScope.launch {
            repository.delete(artwork)
            onDone()
        }
    }

    companion object {
        fun factory(repository: ArtworkRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>) =
                ArtworkDetailViewModel(repository) as T
        }
    }
}
