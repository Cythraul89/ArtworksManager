package com.example.artworksmanager.data

import android.content.Context

/**
 * Thin wrapper around SharedPreferences that stores app-level user preferences.
 * Obtain the singleton via [ArtworksManagerApp.preferences].
 */
class AppPreferences(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /** The currency used to display and format purchase prices throughout the app. */
    var currency: Currency
        get() = Currency.fromCode(prefs.getString(KEY_CURRENCY, Currency.EUR.code) ?: Currency.EUR.code)
        set(value) = prefs.edit().putString(KEY_CURRENCY, value.code).apply()

    companion object {
        private const val PREFS_NAME   = "app_prefs"
        private const val KEY_CURRENCY = "currency"
    }
}
