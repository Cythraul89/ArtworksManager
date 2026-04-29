package com.example.artworksmanager.util

import android.content.Context
import android.net.Uri
import com.example.artworksmanager.data.Artwork
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/**
 * Creates a zip backup containing a human-readable [artworks.json] and all artwork photos.
 * The zip is written directly to a caller-supplied SAF [Uri] so the user controls
 * where the file is saved.
 *
 * Zip structure:
 * ```
 * artworks.json       ← all artwork records as pretty-printed JSON
 * photos/<name>.jpg   ← every artwork photo
 * ```
 */
class BackupExporter(private val context: Context) {

    /**
     * Writes the backup zip to [uri]. Must be called from a background thread.
     * [artworks] is the full collection fetched from the database before calling this.
     */
    fun writeTo(uri: Uri, artworks: List<Artwork>) {
        context.contentResolver.openOutputStream(uri)?.use { out ->
            ZipOutputStream(out.buffered()).use { zos ->
                addJson(zos, artworks)
                addPhotoFiles(zos)
            }
        }
    }

    private fun addJson(zos: ZipOutputStream, artworks: List<Artwork>) {
        val dateFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val isoFmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)

        val array = JSONArray()
        for (artwork in artworks) {
            JSONObject().apply {
                put("id", artwork.id)
                put("title", artwork.title)
                put("artist", artwork.artist)
                artwork.year?.let { put("year", it) }
                if (artwork.type.isNotEmpty()) put("type", artwork.type)
                put("medium", artwork.medium)
                artwork.heightCm?.let { put("heightCm", it) }
                artwork.widthCm?.let { put("widthCm", it) }
                artwork.depthCm?.let { put("depthCm", it) }
                put("location", artwork.location)
                artwork.acquisitionDate?.let { put("acquisitionDate", dateFmt.format(Date(it))) }
                if (artwork.currency.isNotEmpty()) put("currency", artwork.currency)
                artwork.purchasePrice?.let { put("purchasePrice", it) }
                put("description", artwork.description)
                if (artwork.photoPath.isNotEmpty()) put("photo", File(artwork.photoPath).name)
                put("createdAt", isoFmt.format(Date(artwork.createdAt)))
            }.also { array.put(it) }
        }

        val root = JSONObject().apply {
            put("exportedAt", isoFmt.format(Date()))
            put("count", artworks.size)
            put("artworks", array)
        }

        zos.putNextEntry(ZipEntry("artworks.json"))
        zos.write(root.toString(2).toByteArray(Charsets.UTF_8))
        zos.closeEntry()
    }

    private fun addPhotoFiles(zos: ZipOutputStream) {
        File(context.filesDir, "artworks").listFiles()?.forEach { photo ->
            zos.putNextEntry(ZipEntry("photos/${photo.name}"))
            FileInputStream(photo).use { it.copyTo(zos) }
            zos.closeEntry()
        }
    }
}
