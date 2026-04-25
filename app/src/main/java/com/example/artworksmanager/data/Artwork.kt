package com.example.artworksmanager.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "artworks")
data class Artwork(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String,
    val artist: String = "",
    val year: Int? = null,
    val medium: String = "",
    val heightCm: Float? = null,
    val widthCm: Float? = null,
    val depthCm: Float? = null,
    val location: String = "",
    val acquisitionDate: Long? = null,
    val purchasePrice: Double? = null,
    val description: String = "",
    val photoPath: String = "",
    val createdAt: Long = System.currentTimeMillis()
)
