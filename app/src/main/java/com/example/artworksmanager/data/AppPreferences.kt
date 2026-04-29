package com.example.artworksmanager.data

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

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

    /**
     * Emits the current [Currency] immediately and again whenever it is changed,
     * so ViewModels can react to preference changes without polling.
     */
    val currencyFlow: Flow<Currency> = callbackFlow {
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key == KEY_CURRENCY) trySend(currency)
        }
        prefs.registerOnSharedPreferenceChangeListener(listener)
        trySend(currency)
        awaitClose { prefs.unregisterOnSharedPreferenceChangeListener(listener) }
    }

    companion object {
        private const val PREFS_NAME   = "app_prefs"
        private const val KEY_CURRENCY = "currency"
    }
}
