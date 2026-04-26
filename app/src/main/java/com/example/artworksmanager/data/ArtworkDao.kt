package com.example.artworksmanager.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

/** Projection used by [ArtworkDao.getMediumCounts] to group artworks by medium. */
data class MediumCount(val medium: String, val count: Int)

/** Projection used by [ArtworkDao.getTopArtists] to group artworks by artist. */
data class ArtistCount(val artist: String, val count: Int)

/** Room DAO providing all database operations for the [Artwork] entity. */
@Dao
interface ArtworkDao {

    @Query("SELECT * FROM artworks ORDER BY createdAt DESC")
    fun getAllArtworks(): Flow<List<Artwork>>

    @Query("SELECT * FROM artworks WHERE id = :id")
    suspend fun getById(id: Long): Artwork?

    @Query("SELECT COUNT(*) FROM artworks")
    fun getCount(): Flow<Int>

    /** Returns the number of artworks per medium, ordered by frequency descending. */
    @Query("SELECT medium, COUNT(*) as count FROM artworks WHERE medium != '' GROUP BY medium ORDER BY count DESC")
    fun getMediumCounts(): Flow<List<MediumCount>>

    /** Returns up to five artists ranked by the size of their represented collection. */
    @Query("SELECT artist, COUNT(*) as count FROM artworks WHERE artist != '' GROUP BY artist ORDER BY count DESC LIMIT 5")
    fun getTopArtists(): Flow<List<ArtistCount>>

    /** Returns the eight most recently added artworks for the dashboard carousel. */
    @Query("SELECT * FROM artworks ORDER BY createdAt DESC LIMIT 8")
    fun getRecentArtworks(): Flow<List<Artwork>>

    @Query("SELECT DISTINCT medium FROM artworks WHERE medium != '' ORDER BY medium")
    fun getDistinctMediums(): Flow<List<String>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(artwork: Artwork): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(artworks: List<Artwork>)

    @Query("DELETE FROM artworks")
    suspend fun deleteAll()

    /** Atomically replaces the entire collection with [artworks]. */
    @Transaction
    suspend fun replaceAll(artworks: List<Artwork>) {
        deleteAll()
        insertAll(artworks)
    }

    @Update
    suspend fun update(artwork: Artwork)

    @Delete
    suspend fun delete(artwork: Artwork)
}
