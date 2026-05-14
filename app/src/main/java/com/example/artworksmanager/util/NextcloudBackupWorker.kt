package com.example.artworksmanager.util

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.example.artworksmanager.ArtworksManagerApp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import java.io.File

/**
 * WorkManager worker that exports the full collection to a zip and uploads it
 * to the user's Nextcloud server via WebDAV.
 *
 * Scheduled as a daily [androidx.work.PeriodicWorkRequest] when the user connects
 * to Nextcloud, and cancelled when they disconnect.
 */
class NextcloudBackupWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {

    override suspend fun doWork(): Result {
        val app = applicationContext as ArtworksManagerApp
        val prefs = app.nextcloudPreferences
        if (!prefs.isConnected) return Result.failure(workDataOf(KEY_ERROR to "Not connected"))

        return try {
            val artworks = withContext(Dispatchers.IO) { app.repository.getAllArtworks().first() }
            val photos   = withContext(Dispatchers.IO) { app.repository.getAllPhotosNow() }

            val tmpFile = File(applicationContext.cacheDir, "nc_backup_tmp.zip")
            try {
                withContext(Dispatchers.IO) {
                    BackupExporter(applicationContext).writeToFile(tmpFile, artworks, photos)
                }
                val result = withContext(Dispatchers.IO) {
                    NextcloudClient.uploadBackup(
                        prefs.serverUrl, prefs.username, prefs.appPassword, tmpFile, prefs.trustAllCerts
                    )
                }
                when (result) {
                    is NextcloudClient.Result.Success -> {
                        prefs.lastBackupTime = System.currentTimeMillis()
                        Result.success()
                    }
                    is NextcloudClient.Result.Transient -> Result.retry()
                    is NextcloudClient.Result.Failure ->
                        Result.failure(workDataOf(KEY_ERROR to result.message))
                }
            } finally {
                tmpFile.delete()
            }
        } catch (e: java.net.UnknownHostException) {
            Result.retry()
        } catch (e: java.net.SocketTimeoutException) {
            Result.retry()
        } catch (e: Exception) {
            Result.failure(workDataOf(KEY_ERROR to (e.message ?: "Unexpected error")))
        }
    }

    companion object {
        const val KEY_ERROR = "error"
    }
}
