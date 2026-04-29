package com.example.artworksmanager.data

/**
 * Supported display currencies for purchase prices.
 * Add new entries here to extend the selectable list — no other code changes required.
 */
enum class Currency(val code: String, val symbol: String, val displayName: String) {
    EUR("EUR", "€",  "Euro"),
    USD("USD", "$",  "US Dollar"),
    NOK("NOK", "kr", "Norwegian Krone"),
    ZAR("ZAR", "R",  "South African Rand");

    /** Human-readable label shown in the selection dialog: e.g. "Euro (€)". */
    val label: String get() = "$displayName ($symbol)"

    companion object {
        /** Returns the [Currency] matching [code], or [EUR] if not found. */
        fun fromCode(code: String): Currency =
            entries.firstOrNull { it.code == code } ?: EUR
    }
}
