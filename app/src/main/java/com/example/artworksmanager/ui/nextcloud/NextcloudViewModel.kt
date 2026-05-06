package com.example.artworksmanager.ui.nextcloud

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.artworksmanager.data.NextcloudPreferences
import com.example.artworksmanager.util.NextcloudClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class NextcloudViewModel(private val prefs: NextcloudPreferences) : ViewModel() {

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

    val savedServerUrl  get() = prefs.serverUrl
    val savedUsername   get() = prefs.username
    val savedAppPassword get() = prefs.appPassword

    fun connect(serverUrl: String, username: String, appPassword: String) {
        if (serverUrl.isBlank() || username.isBlank() || appPassword.isBlank()) {
            _state.value = State.Error("Please fill in all fields")
            return
        }
        _state.value = State.Testing
        viewModelScope.launch {
            val result = withContext(Dispatchers.IO) {
                NextcloudClient.testConnection(serverUrl.trim(), username.trim(), appPassword)
            }
            if (result is NextcloudClient.Result.Success) {
                prefs.serverUrl   = serverUrl
                prefs.username    = username
                prefs.appPassword = appPassword
                _state.value = State.Connected
            } else {
                _state.value = State.Error((result as NextcloudClient.Result.Failure).message)
            }
        }
    }

    fun disconnect() {
        prefs.clear()
        _state.value = State.Idle
    }

    companion object {
        fun factory(prefs: NextcloudPreferences) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>) =
                NextcloudViewModel(prefs) as T
        }
    }
}
