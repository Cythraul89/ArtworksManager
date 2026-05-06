package com.example.artworksmanager.util

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
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
        if (!prefs.isConnected) return Result.failure()

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
                if (result is NextcloudClient.Result.Success) {
                    prefs.lastBackupTime = System.currentTimeMillis()
                    Result.success()
                } else {
                    Result.retry()
                }
            } finally {
                tmpFile.delete()
            }
        } catch (e: Exception) {
            Result.retry()
        }
    }
}
