package com.example.artworksmanager

import android.app.Application
import androidx.appcompat.app.AppCompatDelegate
import com.example.artworksmanager.data.ArtworkDatabase
import com.example.artworksmanager.data.ArtworkRepository

class ArtworksManagerApp : Application() {
    val database by lazy { ArtworkDatabase.getDatabase(this) }
    val repository by lazy { ArtworkRepository(database.artworkDao()) }

    override fun onCreate() {
        super.onCreate()
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO)
    }
}
