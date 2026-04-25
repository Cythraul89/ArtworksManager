package com.example.artworksmanager.ui.collection

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.databinding.ItemArtworkGridBinding
import com.example.artworksmanager.databinding.ItemArtworkListBinding
import java.io.File

class ArtworkAdapter(private val onClick: (Artwork) -> Unit) :
    ListAdapter<Artwork, RecyclerView.ViewHolder>(DIFF) {

    var isGridLayout = true
        set(value) { field = value; notifyDataSetChanged() }

    override fun getItemViewType(position: Int) = if (isGridLayout) GRID else LIST

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder =
        if (viewType == GRID)
            GridVH(ItemArtworkGridBinding.inflate(LayoutInflater.from(parent.context), parent, false))
        else
            ListVH(ItemArtworkListBinding.inflate(LayoutInflater.from(parent.context), parent, false))

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val artwork = getItem(position)
        when (holder) {
            is GridVH -> holder.bind(artwork)
            is ListVH -> holder.bind(artwork)
        }
    }

    inner class GridVH(private val b: ItemArtworkGridBinding) : RecyclerView.ViewHolder(b.root) {
        fun bind(artwork: Artwork) {
            b.title.text  = artwork.title
            b.artist.text = artwork.artist
            loadImage(artwork.photoPath, b.image)
            b.root.setOnClickListener { onClick(artwork) }
        }
    }

    inner class ListVH(private val b: ItemArtworkListBinding) : RecyclerView.ViewHolder(b.root) {
        fun bind(artwork: Artwork) {
            b.title.text = artwork.title
            b.subtitle.text = buildString {
                if (artwork.artist.isNotEmpty()) append(artwork.artist)
                if (artwork.year != null) { if (isNotEmpty()) append(" · "); append(artwork.year) }
            }
            loadImage(artwork.photoPath, b.image)
            b.root.setOnClickListener { onClick(artwork) }
        }
    }

    private fun loadImage(path: String, view: android.widget.ImageView) {
        if (path.isNotEmpty()) {
            Glide.with(view).load(File(path)).centerCrop().into(view)
        } else {
            view.setImageResource(android.R.drawable.ic_menu_gallery)
        }
    }

    companion object {
        const val GRID = 0
        const val LIST = 1
        val DIFF = object : DiffUtil.ItemCallback<Artwork>() {
            override fun areItemsTheSame(a: Artwork, b: Artwork) = a.id == b.id
            override fun areContentsTheSame(a: Artwork, b: Artwork) = a == b
        }
    }
}
