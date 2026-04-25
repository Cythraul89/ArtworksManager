package com.example.artworksmanager

import android.app.Application
import com.example.artworksmanager.data.ArtworkDatabase
import com.example.artworksmanager.data.ArtworkRepository

class ArtworksManagerApp : Application() {
    val database by lazy { ArtworkDatabase.getDatabase(this) }
    val repository by lazy { ArtworkRepository(database.artworkDao()) }
}
