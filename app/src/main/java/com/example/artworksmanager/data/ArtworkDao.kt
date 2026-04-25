package com.example.artworksmanager.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

data class MediumCount(val medium: String, val count: Int)
data class ArtistCount(val artist: String, val count: Int)

@Dao
interface ArtworkDao {

    @Query("SELECT * FROM artworks ORDER BY createdAt DESC")
    fun getAllArtworks(): Flow<List<Artwork>>

    @Query("SELECT * FROM artworks WHERE id = :id")
    suspend fun getById(id: Long): Artwork?

    @Query("SELECT COUNT(*) FROM artworks")
    fun getCount(): Flow<Int>

    @Query("SELECT medium, COUNT(*) as count FROM artworks WHERE medium != '' GROUP BY medium ORDER BY count DESC")
    fun getMediumCounts(): Flow<List<MediumCount>>

    @Query("SELECT artist, COUNT(*) as count FROM artworks WHERE artist != '' GROUP BY artist ORDER BY count DESC LIMIT 5")
    fun getTopArtists(): Flow<List<ArtistCount>>

    @Query("SELECT * FROM artworks ORDER BY createdAt DESC LIMIT 8")
    fun getRecentArtworks(): Flow<List<Artwork>>

    @Query("SELECT DISTINCT medium FROM artworks WHERE medium != '' ORDER BY medium")
    fun getDistinctMediums(): Flow<List<String>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(artwork: Artwork): Long

    @Update
    suspend fun update(artwork: Artwork)

    @Delete
    suspend fun delete(artwork: Artwork)
}
