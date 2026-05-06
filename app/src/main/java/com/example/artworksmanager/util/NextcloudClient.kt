package com.example.artworksmanager.util

import android.util.Base64
import java.net.HttpURLConnection
import java.net.URL

/**
 * Thin HTTP client for Nextcloud connectivity checks.
 * All functions must be called on a background thread (Dispatchers.IO).
 */
object NextcloudClient {

    sealed class Result {
        object Success : Result()
        data class Failure(val message: String) : Result()
    }

    private const val TIMEOUT_MS = 10_000

    /**
     * Verifies credentials by calling the Nextcloud OCS user endpoint.
     * Returns [Result.Success] on HTTP 200, a descriptive [Result.Failure] otherwise.
     */
    fun testConnection(serverUrl: String, username: String, appPassword: String): Result {
        return try {
            val url = URL("${serverUrl.trimEnd('/')}/ocs/v2.php/cloud/user")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                setRequestProperty("Authorization", basicAuth(username, appPassword))
                setRequestProperty("OCS-APIRequest", "true")
                connectTimeout = TIMEOUT_MS
                readTimeout    = TIMEOUT_MS
            }
            when (val code = conn.responseCode) {
                200  -> Result.Success
                401  -> Result.Failure("Invalid username or app password")
                404  -> Result.Failure("Nextcloud not found at this URL")
                else -> Result.Failure("Unexpected response: HTTP $code")
            }
        } catch (e: java.net.UnknownHostException) {
            Result.Failure("Cannot reach server — check the URL and your internet connection")
        } catch (e: java.net.SocketTimeoutException) {
            Result.Failure("Connection timed out")
        } catch (e: Exception) {
            Result.Failure(e.message ?: "Connection failed")
        }
    }

    private fun basicAuth(username: String, password: String): String {
        val encoded = Base64.encodeToString("$username:$password".toByteArray(), Base64.NO_WRAP)
        return "Basic $encoded"
    }
}
