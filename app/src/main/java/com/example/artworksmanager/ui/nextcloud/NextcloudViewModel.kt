package com.example.artworksmanager.ui.nextcloud

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.example.artworksmanager.data.NextcloudPreferences
import com.example.artworksmanager.util.NextcloudBackupWorker
import com.example.artworksmanager.util.NextcloudClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

class NextcloudViewModel(
    application: Application,
    private val prefs: NextcloudPreferences
) : AndroidViewModel(application) {

    sealed class State {
        object Idle      : State()
        object Testing   : State()
        object Connected : State()
        data class Error(val message: String) : State()
    }

    private val _state = MutableStateFlow<State>(
        if (prefs.isConnected) State.Connected else State.Idle
    )
    val state: StateFlow<State> = _state

    val savedServerUrl   get() = prefs.serverUrl
    val savedUsername    get() = prefs.username
    val savedAppPassword get() = prefs.appPassword
    val savedTrustAll    get() = prefs.trustAllCerts
    val lastBackupTime   get() = prefs.lastBackupTime

    fun connect(serverUrl: String, username: String, appPassword: String, trustAllCerts: Boolean) {
        if (serverUrl.isBlank() || username.isBlank() || appPassword.isBlank()) {
            _state.value = State.Error("Please fill in all fields")
            return
        }
        _state.value = State.Testing
        viewModelScope.launch {
            val result = withContext(Dispatchers.IO) {
                NextcloudClient.testConnection(serverUrl.trim(), username.trim(), appPassword, trustAllCerts)
            }
            if (result is NextcloudClient.Result.Success) {
                prefs.serverUrl     = serverUrl
                prefs.username      = username
                prefs.appPassword   = appPassword
                prefs.trustAllCerts = trustAllCerts
                scheduleAutoBackup()
                _state.value = State.Connected
            } else {
                _state.value = State.Error((result as NextcloudClient.Result.Failure).message)
            }
        }
    }

    fun disconnect() {
        cancelAutoBackup()
        prefs.clear()
        _state.value = State.Idle
    }

    fun backupNow(): java.util.UUID {
        val request = OneTimeWorkRequestBuilder<NextcloudBackupWorker>()
            .setConstraints(networkConstraint())
            .build()
        WorkManager.getInstance(getApplication()).enqueue(request)
        return request.id
    }

    private fun scheduleAutoBackup() {
        val request = PeriodicWorkRequestBuilder<NextcloudBackupWorker>(1, TimeUnit.DAYS)
            .setConstraints(networkConstraint())
            .build()
        WorkManager.getInstance(getApplication()).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )
    }

    private fun cancelAutoBackup() {
        WorkManager.getInstance(getApplication()).cancelUniqueWork(WORK_NAME)
    }

    private fun networkConstraint() =
        Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

    companion object {
        const val WORK_NAME = "nextcloud_auto_backup"

        fun factory(application: Application, prefs: NextcloudPreferences) =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : androidx.lifecycle.ViewModel> create(modelClass: Class<T>) =
                    NextcloudViewModel(application, prefs) as T
            }
    }
}
