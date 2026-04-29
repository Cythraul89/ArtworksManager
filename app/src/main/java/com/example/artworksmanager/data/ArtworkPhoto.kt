package com.example.artworksmanager.data

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Additional photo attached to an [Artwork]. Deleting the parent artwork cascades to all its photos.
 */
@Entity(
    tableName = "artwork_photos",
    foreignKeys = [ForeignKey(
        entity     = Artwork::class,
        parentColumns = ["id"],
        childColumns  = ["artworkId"],
        onDelete   = ForeignKey.CASCADE
    )],
    indices = [Index("artworkId")]
)
data class ArtworkPhoto(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    @ColumnInfo(index = true) val artworkId: Long,
    val photoPath: String,
    val sortOrder: Int = 0
)
