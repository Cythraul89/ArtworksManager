package com.example.artworksmanager.util

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * Fetches live exchange rates from the Frankfurter public API (api.frankfurter.app).
 * No API key required; rates are sourced from the European Central Bank and updated daily.
 */
object ExchangeRateService {

    private const val BASE_URL  = "https://api.frankfurter.app/latest?from="
    private const val TIMEOUT_MS = 8_000

    /**
     * Returns a map where each entry answers "how many units of currency X equal 1 [baseCurrency]".
     * The [baseCurrency] key is always present with value 1.0.
     * Returns null on any network error, timeout, or non-200 response.
     * Must be called from a background thread.
     */
    fun fetchRates(baseCurrency: String): Map<String, Double>? {
        return try {
            val conn = URL("$BASE_URL$baseCurrency").openConnection() as HttpURLConnection
            conn.connectTimeout = TIMEOUT_MS
            conn.readTimeout    = TIMEOUT_MS
            conn.requestMethod  = "GET"
            if (conn.responseCode != 200) { conn.disconnect(); return null }
            val body = conn.inputStream.bufferedReader().readText()
            conn.disconnect()
            val rates = JSONObject(body).getJSONObject("rates")
            buildMap {
                put(baseCurrency, 1.0)
                rates.keys().forEach { key -> put(key, rates.getDouble(key)) }
            }
        } catch (e: Exception) {
            null
        }
    }
}
