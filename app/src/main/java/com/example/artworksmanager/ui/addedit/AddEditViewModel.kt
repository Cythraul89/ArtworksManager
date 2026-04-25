package com.example.artworksmanager.ui.addedit

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.data.ArtworkRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class AddEditViewModel(private val repository: ArtworkRepository) : ViewModel() {

    private val _artwork = MutableStateFlow<Artwork?>(null)
    val artwork: StateFlow<Artwork?> = _artwork

    private val _savedId = MutableStateFlow<Long?>(null)
    val savedId: StateFlow<Long?> = _savedId

    fun load(id: Long) {
        if (id == 0L) return
        viewModelScope.launch {
            _artwork.value = repository.getById(id)
        }
    }

    fun save(
        id: Long,
        title: String,
        artist: String,
        year: Int?,
        medium: String,
        heightCm: Float?,
        widthCm: Float?,
        depthCm: Float?,
        location: String,
        acquisitionDate: Long?,
        purchasePrice: Double?,
        description: String,
        photoPath: String
    ) {
        viewModelScope.launch {
            val artwork = Artwork(
                id = id,
                title = title,
                artist = artist,
                year = year,
                medium = medium,
                heightCm = heightCm,
                widthCm = widthCm,
                depthCm = depthCm,
                location = location,
                acquisitionDate = acquisitionDate,
                purchasePrice = purchasePrice,
                description = description,
                photoPath = photoPath
            )
            val savedId = if (id == 0L) repository.insert(artwork)
                         else { repository.update(artwork); id }
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
