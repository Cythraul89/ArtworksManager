package com.example.artworksmanager.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [Artwork::class], version = 1, exportSchema = false)
abstract class ArtworkDatabase : RoomDatabase() {

    abstract fun artworkDao(): ArtworkDao

    companion object {
        @Volatile private var INSTANCE: ArtworkDatabase? = null

        fun getDatabase(context: Context): ArtworkDatabase =
            INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(context, ArtworkDatabase::class.java, "artworks_db")
                    .build()
                    .also { INSTANCE = it }
            }
    }
}
