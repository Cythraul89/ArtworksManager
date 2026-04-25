package com.example.artworksmanager.ui.dashboard

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.databinding.ItemRecentArtworkBinding
import java.io.File

class RecentArtworkAdapter(private val onClick: (Artwork) -> Unit) :
    ListAdapter<Artwork, RecentArtworkAdapter.ViewHolder>(DIFF) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) = ViewHolder(
        ItemRecentArtworkBinding.inflate(LayoutInflater.from(parent.context), parent, false)
    )

    override fun onBindViewHolder(holder: ViewHolder, position: Int) =
        holder.bind(getItem(position))

    inner class ViewHolder(private val b: ItemRecentArtworkBinding) :
        RecyclerView.ViewHolder(b.root) {
        fun bind(artwork: Artwork) {
            b.title.text = artwork.title
            if (artwork.photoPath.isNotEmpty()) {
                Glide.with(b.image).load(File(artwork.photoPath)).centerCrop().into(b.image)
            } else {
                b.image.setImageResource(android.R.drawable.ic_menu_gallery)
            }
            b.root.setOnClickListener { onClick(artwork) }
        }
    }

    companion object {
        val DIFF = object : DiffUtil.ItemCallback<Artwork>() {
            override fun areItemsTheSame(a: Artwork, b: Artwork) = a.id == b.id
            override fun areContentsTheSame(a: Artwork, b: Artwork) = a == b
        }
    }
}
