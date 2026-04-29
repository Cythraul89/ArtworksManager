package com.example.artworksmanager.ui.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.artworksmanager.data.AppPreferences
import com.example.artworksmanager.data.ArtistCount
import com.example.artworksmanager.data.Artwork
import com.example.artworksmanager.data.ArtworkRepository
import com.example.artworksmanager.data.CurrencyTotal
import com.example.artworksmanager.data.MediumCount
import com.example.artworksmanager.util.ExchangeRateService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** State of the converted grand-total row in the Collection Value card. */
sealed class ValueState {
    /** Rates fetch in progress. */
    object Loading : ValueState()
    /** Total is ready. [isLive] is false when no conversion was needed (single currency = target). */
    data class Ready(val amount: Double, val currency: String, val isLive: Boolean) : ValueState()
    /** Offline with mixed currencies — conversion not possible. */
    object Unavailable : ValueState()
}

/**
 * ViewModel for [DashboardFragment] that exposes aggregated collection statistics,
 * the recent-artworks carousel, per-currency price totals, and a live-rate grand total.
 */
class DashboardViewModel(
    private val repository: ArtworkRepository,
    private val preferences: AppPreferences
) : ViewModel() {

    val totalCount: StateFlow<Int> = repository.getCount()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    val mediumCounts: StateFlow<List<MediumCount>> = repository.getMediumCounts()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val topArtists: StateFlow<List<ArtistCount>> = repository.getTopArtists()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val recentArtworks: StateFlow<List<Artwork>> = repository.getRecentArtworks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    /**
     * Per-currency price totals. Artworks with an empty currency field are bucketed
     * under the global preference currency rather than shown as a blank group.
     */
    val priceTotals: StateFlow<List<CurrencyTotal>> = repository.getPriceTotals()
        .map { rawList ->
            val defaultCode = preferences.currency.code
            val merged = mutableMapOf<String, Double>()
            rawList.forEach { ct ->
                val code = ct.currency.ifEmpty { defaultCode }
                merged[code] = (merged[code] ?: 0.0) + ct.total
            }
            merged.entries.sortedByDescending { it.value }
                          .map { CurrencyTotal(it.key, it.value) }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _valueState = MutableStateFlow<ValueState>(ValueState.Loading)
    val valueState: StateFlow<ValueState> = _valueState

    init {
        // Fetch exchange rates once per ViewModel lifetime, then recompute on every
        // priceTotals emission (collection changes) using the already-fetched rates.
        viewModelScope.launch {
            val targetCurrency = preferences.currency.code
            val rates = withContext(Dispatchers.IO) {
                ExchangeRateService.fetchRates(targetCurrency)
            }
            priceTotals.collect { totals ->
                _valueState.value = computeValueState(totals, targetCurrency, rates)
            }
        }
    }

    private fun computeValueState(
        totals: List<CurrencyTotal>,
        targetCurrency: String,
        rates: Map<String, Double>?
    ): ValueState {
        if (totals.isEmpty()) return ValueState.Loading

        if (rates != null) {
            // Convert each currency bucket to the target using: amount / rate
            // where rate = "how many foreign-currency units per 1 target-currency unit".
            val sum = totals.sumOf { ct ->
                val rate = rates[ct.currency] ?: return ValueState.Unavailable
                ct.total / rate
            }
            return ValueState.Ready(sum, targetCurrency, isLive = true)
        }

        // Offline — only exact when the entire collection uses the target currency.
        if (totals.size == 1 && totals[0].currency == targetCurrency) {
            return ValueState.Ready(totals[0].total, targetCurrency, isLive = false)
        }

        return ValueState.Unavailable
    }

    companion object {
        fun factory(repository: ArtworkRepository, preferences: AppPreferences) =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>) =
                    DashboardViewModel(repository, preferences) as T
            }
    }
}
