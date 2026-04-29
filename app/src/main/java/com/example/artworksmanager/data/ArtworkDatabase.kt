package com.example.artworksmanager.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

/**
 * Room database for the app, exposing [ArtworkDao] as the single access point.
 * Obtain the singleton instance via [getDatabase].
 */
@Database(entities = [Artwork::class], version = 2, exportSchema = false)
abstract class ArtworkDatabase : RoomDatabase() {

    abstract fun artworkDao(): ArtworkDao

    companion object {
        @Volatile private var INSTANCE: ArtworkDatabase? = null

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("ALTER TABLE artworks ADD COLUMN type TEXT NOT NULL DEFAULT ''")
                database.execSQL("ALTER TABLE artworks ADD COLUMN currency TEXT NOT NULL DEFAULT ''")
            }
        }

        /** Returns the singleton database instance, creating it on first call. */
        fun getDatabase(context: Context): ArtworkDatabase =
            INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(context, ArtworkDatabase::class.java, "artworks_db")
                    .addMigrations(MIGRATION_1_2)
                    .build()
                    .also { INSTANCE = it }
            }
    }
}
