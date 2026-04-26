package com.example.artworksmanager.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

/**
 * Room database for the app, exposing [ArtworkDao] as the single access point.
 * Obtain the singleton instance via [getDatabase].
 */
@Database(entities = [Artwork::class], version = 1, exportSchema = false)
abstract class ArtworkDatabase : RoomDatabase() {

    abstract fun artworkDao(): ArtworkDao

    companion object {
        @Volatile private var INSTANCE: ArtworkDatabase? = null

        /** Returns the singleton database instance, creating it on first call. */
        fun getDatabase(context: Context): ArtworkDatabase =
            INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(context, ArtworkDatabase::class.java, "artworks_db")
                    .build()
                    .also { INSTANCE = it }
            }
    }
}
