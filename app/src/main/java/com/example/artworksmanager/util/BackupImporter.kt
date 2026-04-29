package com.example.artworksmanager.util

import android.content.Context
import android.net.Uri
import com.example.artworksmanager.data.Artwork
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.zip.ZipInputStream

/**
 * Reads a backup zip produced by [BackupExporter] and returns a list of [Artwork] objects
 * with photos extracted to [Context.getFilesDir]/artworks/.
 */
class BackupImporter(private val context: Context) {

    /**
     * Reads the backup zip at [uri], extracts photos, and returns the parsed artworks
     * with [Artwork.photoPath] pointing to the newly extracted local files.
     * Must be called from a background thread.
     */
    fun importFrom(uri: Uri): List<Artwork> {
        val photosDir = File(context.filesDir, "artworks").also { it.mkdirs() }

        var jsonBytes: ByteArray? = null
        val extractedPhotos = mutableMapOf<String, File>() // filename → local file

        context.contentResolver.openInputStream(uri)?.use { input ->
            ZipInputStream(input.buffered()).use { zis ->
                var entry = zis.nextEntry
                while (entry != null) {
                    when {
                        entry.name == "artworks.json" ->
                            jsonBytes = zis.readBytes()
                        entry.name.startsWith("photos/") && !entry.isDirectory -> {
                            val filename = File(entry.name).name
                            val dest = File(photosDir, filename)
                            FileOutputStream(dest).use { zis.copyTo(it) }
                            extractedPhotos[filename] = dest
                        }
                    }
                    zis.closeEntry()
                    entry = zis.nextEntry
                }
            }
        }

        val json = jsonBytes?.toString(Charsets.UTF_8)
            ?: error("artworks.json not found in backup")

        return parseArtworks(json, extractedPhotos)
    }

    private fun parseArtworks(json: String, photos: Map<String, File>): List<Artwork> {
        val dateFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val isoFmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        val array = JSONObject(json).getJSONArray("artworks")

        return (0 until array.length()).map { i ->
            val o = array.getJSONObject(i)
            Artwork(
                id          = o.getLong("id"),
                title       = o.getString("title"),
                artist      = o.optString("artist", ""),
                year        = if (o.has("year")) o.getInt("year") else null,
                type        = o.optString("type", ""),
                medium      = o.optString("medium", ""),
                heightCm    = if (o.has("heightCm")) o.getDouble("heightCm").toFloat() else null,
                widthCm     = if (o.has("widthCm")) o.getDouble("widthCm").toFloat() else null,
                depthCm     = if (o.has("depthCm")) o.getDouble("depthCm").toFloat() else null,
                location    = o.optString("location", ""),
                acquisitionDate = o.optString("acquisitionDate", "").takeIf { it.isNotEmpty() }
                                    ?.let { dateFmt.parse(it)?.time },
                currency        = o.optString("currency", ""),
                purchasePrice   = if (o.has("purchasePrice")) o.getDouble("purchasePrice") else null,
                description = o.optString("description", ""),
                photoPath   = o.optString("photo", "").let { photos[it]?.absolutePath ?: "" },
                createdAt   = o.optString("createdAt", "").takeIf { it.isNotEmpty() }
                                ?.let { runCatching { isoFmt.parse(it)?.time }.getOrNull() }
                                ?: System.currentTimeMillis()
            )
        }
    }
}
