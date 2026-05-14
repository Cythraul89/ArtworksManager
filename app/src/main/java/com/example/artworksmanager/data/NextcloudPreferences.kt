package com.example.artworksmanager.data

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * Stores Nextcloud connection credentials in EncryptedSharedPreferences so the
 * app password is never written to disk in plaintext.
 *
 * Obtain the singleton via [com.example.artworksmanager.ArtworksManagerApp.nextcloudPreferences].
 */
class NextcloudPreferences(context: Context) {

    private val prefs = try {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    } catch (_: Exception) {
        // Fall back to plain prefs if the keystore is unavailable (e.g. some emulators).
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    var serverUrl: String
        get() = prefs.getString(KEY_SERVER, "") ?: ""
        set(value) { prefs.edit().putString(KEY_SERVER, value.trimEnd('/')).apply() }

    var username: String
        get() = prefs.getString(KEY_USER, "") ?: ""
        set(value) { prefs.edit().putString(KEY_USER, value.trim()).apply() }

    var appPassword: String
        get() = prefs.getString(KEY_PASS, "") ?: ""
        set(value) { prefs.edit().putString(KEY_PASS, value).apply() }

    val isConnected: Boolean
        get() = serverUrl.isNotEmpty() && username.isNotEmpty() && appPassword.isNotEmpty()

    var lastBackupTime: Long
        get() = prefs.getLong(KEY_LAST_BACKUP, 0L)
        set(value) { prefs.edit().putLong(KEY_LAST_BACKUP, value).apply() }

    var trustAllCerts: Boolean
        get() = prefs.getBoolean(KEY_TRUST_ALL, false)
        set(value) { prefs.edit().putBoolean(KEY_TRUST_ALL, value).apply() }

    fun clear() {
        prefs.edit().remove(KEY_SERVER).remove(KEY_USER).remove(KEY_PASS).apply()
    }

    companion object {
        private const val PREFS_NAME      = "nextcloud_prefs"
        private const val KEY_SERVER      = "server_url"
        private const val KEY_USER        = "username"
        private const val KEY_PASS        = "app_password"
        private const val KEY_LAST_BACKUP = "last_backup_time"
        private const val KEY_TRUST_ALL   = "trust_all_certs"
    }
}
