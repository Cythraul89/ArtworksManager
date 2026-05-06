package com.example.artworksmanager.util

import android.util.Base64
import java.io.File
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

    /**
     * Uploads [file] to `/ArtworksManager/artworks_backup.zip` on the server via WebDAV PUT.
     * Creates the remote directory first if it does not exist.
     * Must be called from a background thread.
     */
    fun uploadBackup(serverUrl: String, username: String, appPassword: String, file: File): Result {
        return try {
            val base = serverUrl.trimEnd('/')
            val auth = basicAuth(username, appPassword)

            // MKCOL creates the directory; 405 = already exists, both outcomes are acceptable
            runCatching {
                val mkcol = URL("$base/remote.php/dav/files/$username/ArtworksManager")
                    .openConnection() as HttpURLConnection
                mkcol.requestMethod = "MKCOL"
                mkcol.setRequestProperty("Authorization", auth)
                mkcol.connectTimeout = TIMEOUT_MS
                mkcol.readTimeout = TIMEOUT_MS
                mkcol.responseCode
                mkcol.disconnect()
            }

            val putUrl = URL("$base/remote.php/dav/files/$username/ArtworksManager/artworks_backup.zip")
            val conn = putUrl.openConnection() as HttpURLConnection
            conn.requestMethod = "PUT"
            conn.setRequestProperty("Authorization", auth)
            conn.setRequestProperty("Content-Type", "application/zip")
            conn.doOutput = true
            conn.connectTimeout = TIMEOUT_MS
            conn.readTimeout = 120_000  // uploads can take longer

            file.inputStream().use { input ->
                conn.outputStream.use { output -> input.copyTo(output) }
            }

            when (val code = conn.responseCode) {
                200, 201, 204 -> Result.Success
                401           -> Result.Failure("Invalid credentials")
                403           -> Result.Failure("Permission denied on server")
                507           -> Result.Failure("Insufficient storage on server")
                else          -> Result.Failure("Upload failed: HTTP $code")
            }
        } catch (e: java.net.UnknownHostException) {
            Result.Failure("Cannot reach server — check the URL and your internet connection")
        } catch (e: java.net.SocketTimeoutException) {
            Result.Failure("Connection timed out")
        } catch (e: Exception) {
            Result.Failure(e.message ?: "Upload failed")
        }
    }

    private fun basicAuth(username: String, password: String): String {
        val encoded = Base64.encodeToString("$username:$password".toByteArray(), Base64.NO_WRAP)
        return "Basic $encoded"
    }
}
