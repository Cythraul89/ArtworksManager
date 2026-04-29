package com.example.artworksmanager.ui.addedit

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.example.artworksmanager.R
import java.io.File

/**
 * RecyclerView adapter for a strip of photo thumbnails.
 * Pass a non-null [onRemove] to show the × badge on each item (Add/Edit mode);
 * pass null to show thumbnails without a remove control (Detail mode).
 */
class AdditionalPhotoAdapter(
    private val onRemove: ((position: Int) -> Unit)? = null
) : RecyclerView.Adapter<AdditionalPhotoAdapter.ViewHolder>() {

    private val paths = mutableListOf<String>()

    fun submitList(newPaths: List<String>) {
        paths.clear()
        paths.addAll(newPaths)
        notifyDataSetChanged()
    }

    fun addPhoto(path: String) {
        paths.add(path)
        notifyItemInserted(paths.lastIndex)
    }

    fun removeAt(index: Int) {
        if (index in paths.indices) {
            paths.removeAt(index)
            notifyItemRemoved(index)
        }
    }

    fun getPaths(): List<String> = paths.toList()

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val thumb: ImageView = itemView.findViewById(R.id.photoThumb)
        val removeBtn: TextView = itemView.findViewById(R.id.removeButton)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder =
        ViewHolder(LayoutInflater.from(parent.context).inflate(R.layout.item_additional_photo, parent, false))

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        Glide.with(holder.thumb).load(File(paths[position])).centerCrop().into(holder.thumb)
        if (onRemove != null) {
            holder.removeBtn.visibility = View.VISIBLE
            holder.removeBtn.setOnClickListener { onRemove.invoke(holder.adapterPosition) }
        } else {
            holder.removeBtn.visibility = View.GONE
        }
    }

    override fun getItemCount(): Int = paths.size
}
