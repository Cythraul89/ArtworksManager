package com.example.artworksmanager.util

import android.content.Context
import android.net.Uri
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.data.ArtworkPhoto
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.zip.ZipInputStream

data class BackupData(val artworks: List<Artwork>, val photos: List<ArtworkPhoto>)

/**
 * Reads a backup zip produced by [BackupExporter] and returns a [BackupData] with artworks
 * and their additional photos, with all photo paths pointing to extracted local files.
 */
class BackupImporter(private val context: Context) {

    /**
     * Reads the backup zip at [uri], extracts photos, and returns the parsed data.
     * Must be called from a background thread.
     */
    fun importFrom(uri: Uri): BackupData {
        val photosDir = File(context.filesDir, "artworks").also { it.mkdirs() }

        var jsonBytes: ByteArray? = null
        val extractedPhotos = mutableMapOf<String, File>()

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

        return parseData(json, extractedPhotos)
    }

    private fun parseData(json: String, photos: Map<String, File>): BackupData {
        val dateFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val isoFmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        val array = JSONObject(json).getJSONArray("artworks")

        val artworks = mutableListOf<Artwork>()
        val allPhotos = mutableListOf<ArtworkPhoto>()

        for (i in 0 until array.length()) {
            val o = array.getJSONObject(i)
            val artworkId = o.getLong("id")
            artworks.add(Artwork(
                id          = artworkId,
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
            ))
            if (o.has("additionalPhotos")) {
                val photosArr = o.getJSONArray("additionalPhotos")
                for (j in 0 until photosArr.length()) {
                    val p = photosArr.getJSONObject(j)
                    val path = p.optString("photo", "").let { photos[it]?.absolutePath ?: "" }
                    if (path.isNotEmpty()) {
                        allPhotos.add(ArtworkPhoto(
                            artworkId = artworkId,
                            photoPath = path,
                            sortOrder = p.optInt("sortOrder", j)
                        ))
                    }
                }
            }
        }

        return BackupData(artworks, allPhotos)
    }
}
