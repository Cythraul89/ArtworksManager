package com.example.artworksmanager.ui.addedit

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.data.ArtworkPhoto
import com.example.artworksmanager.data.ArtworkRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch

/**
 * ViewModel for [AddEditFragment] that handles loading an existing artwork for editing
 * and persisting the form data as a new or updated record.
 */
class AddEditViewModel(private val repository: ArtworkRepository) : ViewModel() {

    private val _artwork = MutableStateFlow<Artwork?>(null)
    val artwork: StateFlow<Artwork?> = _artwork

    private val _savedId = MutableStateFlow<Long?>(null)
    val savedId: StateFlow<Long?> = _savedId

    private val _additionalPhotos = MutableStateFlow<List<ArtworkPhoto>>(emptyList())
    val additionalPhotos: StateFlow<List<ArtworkPhoto>> = _additionalPhotos

    /** Fetches the artwork and its additional photos. No-op when [id] is 0. */
    fun load(id: Long) {
        if (id == 0L) return
        viewModelScope.launch {
            _artwork.value = repository.getById(id)
            _additionalPhotos.value =
                repository.getAdditionalPhotos(id).firstOrNull() ?: emptyList()
        }
    }

    /**
     * Inserts or updates the artwork, then applies the photo diff:
     * - [photosToDelete] are removed from the database
     * - [newPhotoPaths] are inserted as new [ArtworkPhoto] rows
     */
    fun save(
        id: Long,
        title: String,
        artist: String,
        year: Int?,
        type: String,
        medium: String,
        heightCm: Float?,
        widthCm: Float?,
        depthCm: Float?,
        location: String,
        acquisitionDate: Long?,
        currency: String,
        purchasePrice: Double?,
        description: String,
        photoPath: String,
        photosToDelete: List<ArtworkPhoto>,
        newPhotoPaths: List<String>
    ) {
        viewModelScope.launch {
            val artwork = Artwork(
                id = id, title = title, artist = artist, year = year,
                type = type, medium = medium,
                heightCm = heightCm, widthCm = widthCm, depthCm = depthCm,
                location = location, acquisitionDate = acquisitionDate,
                currency = currency, purchasePrice = purchasePrice,
                description = description, photoPath = photoPath
            )
            val savedId = if (id == 0L) repository.insert(artwork)
                          else { repository.update(artwork); id }

            photosToDelete.forEach { repository.deletePhoto(it) }
            newPhotoPaths.forEachIndexed { idx, path ->
                repository.addPhoto(ArtworkPhoto(artworkId = savedId, photoPath = path, sortOrder = idx))
            }

            _savedId.value = savedId
        }
    }

    companion object {
        fun factory(repository: ArtworkRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>) =
                AddEditViewModel(repository) as T
        }
    }
}
