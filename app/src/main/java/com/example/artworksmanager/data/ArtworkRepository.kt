package com.example.artworksmanager.data

import kotlinx.coroutines.flow.Flow

class ArtworkRepository(private val dao: ArtworkDao) {

    fun getAllArtworks(): Flow<List<Artwork>> = dao.getAllArtworks()
    fun getCount(): Flow<Int> = dao.getCount()
    fun getMediumCounts(): Flow<List<MediumCount>> = dao.getMediumCounts()
    fun getTopArtists(): Flow<List<ArtistCount>> = dao.getTopArtists()
    fun getRecentArtworks(): Flow<List<Artwork>> = dao.getRecentArtworks()
    fun getDistinctMediums(): Flow<List<String>> = dao.getDistinctMediums()

    suspend fun getById(id: Long): Artwork? = dao.getById(id)
    suspend fun insert(artwork: Artwork): Long = dao.insert(artwork)
    suspend fun update(artwork: Artwork) = dao.update(artwork)
    suspend fun delete(artwork: Artwork) = dao.delete(artwork)
}
