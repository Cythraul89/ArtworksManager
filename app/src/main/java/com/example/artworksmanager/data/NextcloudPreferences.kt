package com.example.artworksmanager.data

import android.content.Context

/**
 * Stores Nextcloud connection credentials in SharedPreferences.
 * Obtain the singleton via [com.example.artworksmanager.ArtworksManagerApp.nextcloudPreferences].
 *
 * NOTE: app passwords are stored in plain SharedPreferences. A production release should
 * migrate to EncryptedSharedPreferences (androidx.security:security-crypto).
 */
class NextcloudPreferences(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

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

    fun clear() {
        prefs.edit().remove(KEY_SERVER).remove(KEY_USER).remove(KEY_PASS).apply()
    }

    companion object {
        private const val PREFS_NAME    = "nextcloud_prefs"
        private const val KEY_SERVER    = "server_url"
        private const val KEY_USER      = "username"
        private const val KEY_PASS      = "app_password"
        private const val KEY_LAST_BACKUP = "last_backup_time"
    }
}
