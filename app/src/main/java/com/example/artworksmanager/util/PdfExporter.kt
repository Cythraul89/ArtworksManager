package com.example.artworksmanager.util

import android.content.Context
import android.content.Intent
import android.graphics.*
import android.graphics.pdf.PdfDocument
import androidx.core.content.FileProvider
import com.example.artworksmanager.data.Artwork
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

class PdfExporter(private val context: Context) {

    private val dateFormat = SimpleDateFormat("dd MMM yyyy", Locale.getDefault())
    private val pageWidth  = 595  // A4 at 72dpi
    private val pageHeight = 842
    private val margin     = 40f

    fun buildAndShare(artworks: List<Artwork>) {
        val file = generate(artworks)
        val uri  = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(Intent.createChooser(intent, "Export collection").also {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
    }

    private fun generate(artworks: List<Artwork>): File {
        val doc = PdfDocument()
        artworks.forEachIndexed { idx, artwork -> renderPage(doc, artwork, idx + 1) }

        val file = File(context.cacheDir, "artworks_${System.currentTimeMillis()}.pdf")
        FileOutputStream(file).use { doc.writeTo(it) }
        doc.close()
        return file
    }

    private fun renderPage(doc: PdfDocument, a: Artwork, pageNum: Int) {
        val info = PdfDocument.PageInfo.Builder(pageWidth, pageHeight, pageNum).create()
        val page = doc.startPage(info)
        val canvas = page.canvas
        val paint  = Paint(Paint.ANTI_ALIAS_FLAG)
        var y = margin

        // Photo
        if (a.photoPath.isNotEmpty()) {
            val bmp = BitmapFactory.decodeFile(a.photoPath)
            if (bmp != null) {
                val maxH = 220f
                val scale = minOf(maxH / bmp.height, (pageWidth - margin * 2) / bmp.width)
                val w = (bmp.width * scale).toInt()
                val h = (bmp.height * scale).toInt()
                canvas.drawBitmap(Bitmap.createScaledBitmap(bmp, w, h, true), margin, y, null)
                y += h + 16f
            }
        }

        // Title
        paint.textSize = 20f; paint.isFakeBoldText = true
        paint.color = Color.parseColor("#3D3B8E")
        canvas.drawText(a.title, margin, y, paint); y += 28f

        // Artist · Year
        paint.textSize = 13f; paint.isFakeBoldText = false
        paint.color = Color.parseColor("#6E6E73")
        val sub = buildString {
            if (a.artist.isNotEmpty()) append(a.artist)
            if (a.year != null) { if (isNotEmpty()) append("  ·  "); append(a.year) }
        }
        if (sub.isNotEmpty()) { canvas.drawText(sub, margin, y, paint); y += 20f }

        // Divider
        paint.color = Color.parseColor("#E0DED9"); paint.strokeWidth = 1f
        canvas.drawLine(margin, y + 4, pageWidth - margin, y + 4, paint); y += 16f

        paint.color = Color.BLACK; paint.textSize = 12f

        fun field(label: String, value: String) {
            if (value.isBlank()) return
            paint.isFakeBoldText = true
            canvas.drawText(label, margin, y, paint)
            paint.isFakeBoldText = false
            // Wrap value text
            val x = margin + 130f
            val maxW = pageWidth - x - margin
            val words = value.split(" ")
            var line = ""
            var firstLine = true
            for (word in words) {
                val candidate = if (line.isEmpty()) word else "$line $word"
                if (paint.measureText(candidate) > maxW && line.isNotEmpty()) {
                    canvas.drawText(line, if (firstLine) x else x, y, paint)
                    y += 16f; line = word; firstLine = false
                } else { line = candidate }
            }
            if (line.isNotEmpty()) {
                canvas.drawText(line, x, y, paint); y += 18f
            }
        }

        field("Medium:", a.medium)
        val dims = buildString {
            a.heightCm?.let { append(it) }
            a.widthCm?.let  { append(" × $it") }
            a.depthCm?.let  { append(" × $it") }
            if (isNotEmpty()) append(" cm")
        }
        field("Dimensions:", dims)
        field("Location:", a.location)
        if (a.acquisitionDate != null) field("Acquired:", dateFormat.format(Date(a.acquisitionDate)))
        if (a.purchasePrice != null)   field("Price:", "€%.2f".format(a.purchasePrice))
        field("Description:", a.description)

        doc.finishPage(page)
    }
}
