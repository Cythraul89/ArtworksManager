package com.example.artworksmanager

import android.app.Application
import androidx.appcompat.app.AppCompatDelegate
import com.example.artworksmanager.data.ArtworkDatabase
import com.example.artworksmanager.data.ArtworkRepository

/**
 * Application subclass that initialises the database and repository singletons and
 * locks the UI to light mode on startup.
 */
class ArtworksManagerApp : Application() {
    val database by lazy { ArtworkDatabase.getDatabase(this) }
    val repository by lazy { ArtworkRepository(database.artworkDao()) }

    override fun onCreate() {
        super.onCreate()
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO)
    }
}
