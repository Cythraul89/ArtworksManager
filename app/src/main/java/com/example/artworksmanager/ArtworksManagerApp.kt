package com.example.artworksmanager

import android.app.Application
import androidx.appcompat.app.AppCompatDelegate
import com.example.artworksmanager.data.AppPreferences
import com.example.artworksmanager.data.ArtworkDatabase
import com.example.artworksmanager.data.ArtworkRepository

/**
 * Application subclass that initialises the database, repository, and preferences singletons.
 * The UI follows the system dark/light mode setting.
 */
class ArtworksManagerApp : Application() {
    val database by lazy { ArtworkDatabase.getDatabase(this) }
    val repository by lazy { ArtworkRepository(database.artworkDao()) }
    val preferences by lazy { AppPreferences(this) }

    override fun onCreate() {
        super.onCreate()
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM)
    }
}
