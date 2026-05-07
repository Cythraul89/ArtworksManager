package com.example.artworksmanager.util

import android.util.Base64
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.SecureRandom
import java.security.cert.X509Certificate
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLHandshakeException
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

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
     * Pass [trustAllCerts] = true for servers with self-signed certificates.
     */
    fun testConnection(serverUrl: String, username: String, appPassword: String, trustAllCerts: Boolean = false): Result {
        return try {
            val url = URL("${serverUrl.trimEnd('/')}/ocs/v2.php/cloud/user")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                if (trustAllCerts && this is HttpsURLConnection) applySelfSignedTrust(this)
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
        } catch (e: SSLHandshakeException) {
            Result.Failure("SSL certificate error — enable \"Trust self-signed certificates\" if your server uses a self-signed cert")
        } catch (e: java.net.UnknownHostException) {
            Result.Failure("Cannot reach server — check the URL and your internet connection")
        } catch (e: java.net.SocketTimeoutException) {
            Result.Failure("Connection timed out")
        } catch (e: Exception) {
            Result.Failure(e.message ?: "Connection failed")
        }
    }

    /**
     * Uploads [file] to the user's Nextcloud via WebDAV PUT.
     * Tries the modern DAV path first, then the legacy /remote.php/webdav/ path.
     * Must be called from a background thread.
     */
    fun uploadBackup(serverUrl: String, username: String, appPassword: String, file: File, trustAllCerts: Boolean = false): Result {
        val base = serverUrl.trimEnd('/')
        val auth = basicAuth(username, appPassword)

        // Try modern path with subdirectory, legacy flat path as fallback
        val candidates = listOf(
            "$base/remote.php/dav/files/$username/ArtworksManager/artworks_backup.zip" to true,
            "$base/remote.php/webdav/artworks_backup.zip" to false
        )

        for ((putPath, needsMkcol) in candidates) {
            try {
                if (needsMkcol) {
                    // Ensure the ArtworksManager directory exists; 405 = already exists, both OK
                    runCatching {
                        val dirUrl = putPath.substringBeforeLast('/')
                        val mkcol = URL(dirUrl).openConnection() as HttpURLConnection
                        if (trustAllCerts && mkcol is HttpsURLConnection) applySelfSignedTrust(mkcol)
                        mkcol.requestMethod = "MKCOL"
                        mkcol.setRequestProperty("Authorization", auth)
                        mkcol.connectTimeout = TIMEOUT_MS
                        mkcol.readTimeout = TIMEOUT_MS
                        mkcol.responseCode
                        mkcol.disconnect()
                    }
                }

                val conn = URL(putPath).openConnection() as HttpURLConnection
                if (trustAllCerts && conn is HttpsURLConnection) applySelfSignedTrust(conn)
                conn.requestMethod = "PUT"
                conn.setRequestProperty("Authorization", auth)
                conn.setRequestProperty("Content-Type", "application/zip")
                conn.doOutput = true
                conn.connectTimeout = TIMEOUT_MS
                conn.readTimeout = 120_000

                file.inputStream().use { input ->
                    conn.outputStream.use { output -> input.copyTo(output) }
                }

                when (val code = conn.responseCode) {
                    200, 201, 204 -> return Result.Success
                    401 -> return Result.Failure("Invalid credentials")
                    403 -> { /* try next candidate */ }
                    507 -> return Result.Failure("Insufficient storage on server")
                    else -> return Result.Failure("Upload failed: HTTP $code")
                }
            } catch (e: SSLHandshakeException) {
                return Result.Failure("SSL certificate error during upload")
            } catch (e: java.net.UnknownHostException) {
                return Result.Failure("Cannot reach server — check the URL and your internet connection")
            } catch (e: java.net.SocketTimeoutException) {
                return Result.Failure("Connection timed out")
            } catch (e: Exception) {
                return Result.Failure(e.message ?: "Upload failed")
            }
        }

        return Result.Failure(
            "WebDAV upload denied (HTTP 403) — in Nextcloud go to " +
            "Settings → Security → App passwords and create a new unrestricted app password"
        )
    }

    private fun basicAuth(username: String, password: String): String {
        val encoded = Base64.encodeToString("$username:$password".toByteArray(), Base64.NO_WRAP)
        return "Basic $encoded"
    }

    private fun applySelfSignedTrust(conn: HttpsURLConnection) {
        val trustAll = arrayOf<TrustManager>(object : X509TrustManager {
            override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) = Unit
            override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) = Unit
            override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
        })
        val sslContext = SSLContext.getInstance("TLS").apply {
            init(null, trustAll, SecureRandom())
        }
        conn.sslSocketFactory = sslContext.socketFactory
        conn.hostnameVerifier = javax.net.ssl.HostnameVerifier { _, _ -> true }
    }
}
