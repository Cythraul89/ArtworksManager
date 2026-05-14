package com.example.artworksmanager.util

import android.content.Context
import android.net.Uri
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.data.ArtworkPhoto
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/**
 * Creates a zip backup containing a human-readable [artworks.json] and all referenced artwork files.
 *
 * Zip structure:
 * ```
 * artworks.json       ← all artwork records as pretty-printed JSON
 * photos/<name>.jpg   ← every referenced photo or certificate PDF
 * ```
 */
class BackupExporter(private val context: Context) {

    fun writeTo(uri: Uri, artworks: List<Artwork>, photosByArtwork: Map<Long, List<ArtworkPhoto>> = emptyMap()) {
        context.contentResolver.openOutputStream(uri)?.use { writeZip(it, artworks, photosByArtwork) }
    }

    fun writeToFile(file: File, artworks: List<Artwork>, photosByArtwork: Map<Long, List<ArtworkPhoto>> = emptyMap()) {
        file.parentFile?.mkdirs()
        file.outputStream().use { writeZip(it, artworks, photosByArtwork) }
    }

    private fun writeZip(out: OutputStream, artworks: List<Artwork>, photosByArtwork: Map<Long, List<ArtworkPhoto>>) {
        ZipOutputStream(out.buffered()).use { zos ->
            val referencedPaths = collectReferencedPaths(artworks, photosByArtwork)
            addJson(zos, artworks, photosByArtwork)
            addReferencedFiles(zos, referencedPaths)
        }
    }

    /** Collects every file path referenced by any artwork record or additional photo. */
    private fun collectReferencedPaths(
        artworks: List<Artwork>,
        photosByArtwork: Map<Long, List<ArtworkPhoto>>
    ): Set<String> {
        val paths = mutableSetOf<String>()
        for (artwork in artworks) {
            if (artwork.photoPath.isNotEmpty()) paths.add(artwork.photoPath)
            if (artwork.certificatePath.isNotEmpty()) paths.add(artwork.certificatePath)
            photosByArtwork[artwork.id]?.forEach { p -> if (p.photoPath.isNotEmpty()) paths.add(p.photoPath) }
        }
        return paths
    }

    private fun addJson(zos: ZipOutputStream, artworks: List<Artwork>, photosByArtwork: Map<Long, List<ArtworkPhoto>>) {
        val dateFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val isoFmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).also {
            it.timeZone = TimeZone.getTimeZone("UTC")
        }

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
                if (artwork.certificatePath.isNotEmpty()) put("certificate", File(artwork.certificatePath).name)
                put("createdAt", isoFmt.format(Date(artwork.createdAt)))
                val extraPhotos = photosByArtwork[artwork.id]
                if (!extraPhotos.isNullOrEmpty()) {
                    val photosArray = JSONArray()
                    extraPhotos.sortedBy { it.sortOrder }.forEach { p ->
                        photosArray.put(JSONObject().apply {
                            put("photo", File(p.photoPath).name)
                            put("sortOrder", p.sortOrder)
                        })
                    }
                    put("additionalPhotos", photosArray)
                }
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

    private fun addReferencedFiles(zos: ZipOutputStream, paths: Set<String>) {
        for (path in paths) {
            val file = File(path)
            if (!file.exists()) continue
            zos.putNextEntry(ZipEntry("photos/${file.name}"))
            FileInputStream(file).use { it.copyTo(zos) }
            zos.closeEntry()
        }
    }
}
