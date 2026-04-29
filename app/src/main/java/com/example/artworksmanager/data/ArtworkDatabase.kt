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
@Database(entities = [Artwork::class, ArtworkPhoto::class], version = 3, exportSchema = false)
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

        private val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS artwork_photos (
                        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        artworkId INTEGER NOT NULL,
                        photoPath TEXT NOT NULL,
                        sortOrder INTEGER NOT NULL DEFAULT 0,
                        FOREIGN KEY (artworkId) REFERENCES artworks(id) ON DELETE CASCADE
                    )
                """.trimIndent())
                database.execSQL(
                    "CREATE INDEX IF NOT EXISTS index_artwork_photos_artworkId ON artwork_photos(artworkId)"
                )
            }
        }

        /** Returns the singleton database instance, creating it on first call. */
        fun getDatabase(context: Context): ArtworkDatabase =
            INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(context, ArtworkDatabase::class.java, "artworks_db")
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
                    .build()
                    .also { INSTANCE = it }
            }
    }
}
