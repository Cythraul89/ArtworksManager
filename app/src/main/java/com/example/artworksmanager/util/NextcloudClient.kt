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
        /** Network/timeout errors that are worth retrying (e.g. WorkManager retry). */
        object Transient : Result()
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
            val code = conn.responseCode
            conn.disconnect()
            when (code) {
                200  -> Result.Success
                401  -> Result.Failure("Invalid username or app password")
                404  -> Result.Failure("Nextcloud not found at this URL")
                else -> Result.Failure("Unexpected response: HTTP $code")
            }
        } catch (e: SSLHandshakeException) {
            Result.Failure("SSL certificate error — enable \"Trust self-signed certificates\" if your server uses a self-signed cert")
        } catch (e: java.net.UnknownHostException) {
            Result.Transient
        } catch (e: java.net.SocketTimeoutException) {
            Result.Transient
        } catch (e: Exception) {
            Result.Failure(e.message ?: "Connection failed")
        }
    }

    /**
     * Uploads [file] to the user's Nextcloud via WebDAV PUT.
     * Tries several path variants in order, continuing on 403/404, so self-hosted
     * servers with non-standard configurations or restricted MKCOL still work.
     * Must be called from a background thread.
     */
    fun uploadBackup(serverUrl: String, username: String, appPassword: String, file: File, trustAllCerts: Boolean = false): Result {
        val base = serverUrl.trimEnd('/')
        val auth = basicAuth(username, appPassword)

        // Each entry: Pair(putUrl, mkcolUrl-or-null)
        val candidates = listOf(
            // 1. Flat PUT in user root — no MKCOL needed, most permissive
            "$base/remote.php/dav/files/$username/artworks_backup.zip" to null,
            // 2. PUT in subdirectory — MKCOL first
            "$base/remote.php/dav/files/$username/ArtworksManager/artworks_backup.zip"
                    to "$base/remote.php/dav/files/$username/ArtworksManager",
            // 3. Legacy WebDAV endpoint (pre-NC10)
            "$base/remote.php/webdav/artworks_backup.zip" to null
        )

        var lastCode = 0
        for ((putUrl, mkcolUrl) in candidates) {
            try {
                mkcolUrl?.let { dir ->
                    runCatching {
                        val mkcol = URL(dir).openConnection() as HttpURLConnection
                        if (trustAllCerts && mkcol is HttpsURLConnection) applySelfSignedTrust(mkcol)
                        mkcol.requestMethod = "MKCOL"
                        mkcol.setRequestProperty("Authorization", auth)
                        mkcol.connectTimeout = TIMEOUT_MS
                        mkcol.readTimeout = TIMEOUT_MS
                        mkcol.responseCode
                        mkcol.disconnect()
                    }
                }

                val conn = URL(putUrl).openConnection() as HttpURLConnection
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

                lastCode = conn.responseCode
                conn.disconnect()
                when (lastCode) {
                    200, 201, 204 -> return Result.Success
                    401 -> return Result.Failure("Invalid credentials")
                    403, 404 -> { /* try next candidate */ }
                    507 -> return Result.Failure("Insufficient storage on server")
                    else -> return Result.Failure("Upload failed: HTTP $lastCode")
                }
            } catch (e: SSLHandshakeException) {
                return Result.Failure("SSL certificate error during upload")
            } catch (e: java.net.UnknownHostException) {
                return Result.Transient
            } catch (e: java.net.SocketTimeoutException) {
                return Result.Transient
            } catch (e: Exception) {
                return Result.Failure(e.message ?: "Upload failed")
            }
        }

        return if (lastCode == 403)
            Result.Failure(
                "WebDAV upload denied (HTTP 403) — in Nextcloud go to " +
                "Settings → Security → App passwords and create a new unrestricted app password"
            )
        else
            Result.Failure("WebDAV endpoint not found (HTTP 404) — check that WebDAV is enabled on your server")
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
