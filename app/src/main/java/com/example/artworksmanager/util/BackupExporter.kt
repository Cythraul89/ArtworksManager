package com.example.artworksmanager.util

import android.content.Context
import android.net.Uri
import java.io.File
import java.io.FileInputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/**
 * Creates a zip backup containing the Room database files and all artwork photos.
 * The zip is written directly to a caller-supplied SAF [Uri] so the user controls
 * where the file is saved.
 */
class BackupExporter(private val context: Context) {

    /**
     * Writes the backup zip to [uri]. Must be called from a background thread.
     *
     * Zip structure:
     * ```
     * db/artworks_db          ← main Room database
     * db/artworks_db-shm      ← WAL shared memory (if present)
     * db/artworks_db-wal      ← WAL journal (if present)
     * photos/<filename>.jpg   ← every artwork photo
     * ```
     */
    fun writeTo(uri: Uri) {
        context.contentResolver.openOutputStream(uri)?.use { out ->
            ZipOutputStream(out.buffered()).use { zos ->
                addDatabaseFiles(zos)
                addPhotoFiles(zos)
            }
        }
    }

    private fun addDatabaseFiles(zos: ZipOutputStream) {
        val dbFile = context.getDatabasePath("artworks_db")
        listOf(dbFile, File("${dbFile.path}-shm"), File("${dbFile.path}-wal"))
            .filter { it.exists() }
            .forEach { file -> addEntry(zos, file, "db/${file.name}") }
    }

    private fun addPhotoFiles(zos: ZipOutputStream) {
        File(context.filesDir, "artworks").listFiles()?.forEach { photo ->
            addEntry(zos, photo, "photos/${photo.name}")
        }
    }

    private fun addEntry(zos: ZipOutputStream, file: File, entryName: String) {
        zos.putNextEntry(ZipEntry(entryName))
        FileInputStream(file).use { it.copyTo(zos) }
        zos.closeEntry()
    }
}
