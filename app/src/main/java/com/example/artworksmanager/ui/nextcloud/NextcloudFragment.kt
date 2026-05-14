package com.example.artworksmanager.ui.nextcloud

import android.os.Bundle
import android.view.*
import android.widget.Toast
import androidx.core.view.isVisible
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.fragment.findNavController
import androidx.work.WorkInfo
import androidx.work.WorkManager
import com.example.artworksmanager.ArtworksManagerApp
import com.example.artworksmanager.R
import com.example.artworksmanager.databinding.FragmentNextcloudBinding
import com.example.artworksmanager.util.NextcloudBackupWorker
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NextcloudFragment : Fragment() {

    private var _binding: FragmentNextcloudBinding? = null
    private val binding get() = _binding!!

    private val viewModel: NextcloudViewModel by viewModels {
        val app = requireActivity().application as ArtworksManagerApp
        NextcloudViewModel.factory(app, app.nextcloudPreferences)
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        _binding = FragmentNextcloudBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.toolbar.setNavigationOnClickListener { findNavController().popBackStack() }

        if (viewModel.savedServerUrl.isNotEmpty()) {
            binding.serverUrlInput.setText(viewModel.savedServerUrl)
            binding.usernameInput.setText(viewModel.savedUsername)
            binding.appPasswordInput.setText(viewModel.savedAppPassword)
        }
        binding.trustCertsCheckbox.isChecked = viewModel.savedTrustAll

        binding.connectButton.setOnClickListener {
            if (binding.trustCertsCheckbox.isChecked) {
                MaterialAlertDialogBuilder(requireContext())
                    .setTitle(R.string.ssl_warning_title)
                    .setMessage(R.string.ssl_warning_message)
                    .setNegativeButton(R.string.cancel, null)
                    .setPositiveButton(R.string.ssl_warning_proceed) { _, _ -> doConnect() }
                    .show()
            } else {
                doConnect()
            }
        }

        binding.disconnectButton.setOnClickListener { viewModel.disconnect() }

        binding.backupNowButton.setOnClickListener {
            val workId = viewModel.backupNow()
            Snackbar.make(requireView(), R.string.nextcloud_backup_queued, Snackbar.LENGTH_SHORT).show()
            WorkManager.getInstance(requireContext())
                .getWorkInfoByIdLiveData(workId)
                .observe(viewLifecycleOwner) { info ->
                    when (info?.state) {
                        WorkInfo.State.SUCCEEDED -> {
                            Toast.makeText(requireContext(), R.string.backup_success, Toast.LENGTH_SHORT).show()
                            refreshLastBackupText()
                        }
                        WorkInfo.State.FAILED -> {
                            val msg = info.outputData.getString(NextcloudBackupWorker.KEY_ERROR)
                                ?: getString(R.string.nextcloud_backup_failed)
                            Toast.makeText(requireContext(), msg, Toast.LENGTH_LONG).show()
                        }
                        else -> Unit
                    }
                }
        }

        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.state.collect { state -> applyState(state) }
            }
        }
    }

    private fun doConnect() {
        viewModel.connect(
            serverUrl     = binding.serverUrlInput.text?.toString() ?: "",
            username      = binding.usernameInput.text?.toString() ?: "",
            appPassword   = binding.appPasswordInput.text?.toString() ?: "",
            trustAllCerts = binding.trustCertsCheckbox.isChecked
        )
    }

    private fun applyState(state: NextcloudViewModel.State) {
        val testing   = state is NextcloudViewModel.State.Testing
        val connected = state is NextcloudViewModel.State.Connected

        binding.progressBar.isVisible      = testing
        binding.connectButton.isEnabled    = !testing
        binding.disconnectButton.isVisible = connected
        binding.connectButton.isVisible    = !connected
        binding.backupDivider.isVisible    = connected
        binding.backupNowButton.isVisible  = connected
        binding.lastBackupText.isVisible   = connected

        binding.statusCard.isVisible = connected || state is NextcloudViewModel.State.Error
        if (connected) {
            val prefs = (requireActivity().application as ArtworksManagerApp).nextcloudPreferences
            binding.statusText.text = getString(R.string.nextcloud_connected_as, prefs.username, prefs.serverUrl)
            binding.statusText.setTextColor(requireContext().getColor(R.color.text_primary))
            binding.statusIcon.setImageResource(android.R.drawable.ic_menu_upload)
            refreshLastBackupText()
        } else if (state is NextcloudViewModel.State.Error) {
            binding.statusText.text = state.message
            binding.statusText.setTextColor(requireContext().getColor(android.R.color.holo_red_dark))
            binding.statusIcon.setImageResource(android.R.drawable.ic_dialog_alert)
        }
    }

    private fun refreshLastBackupText() {
        val lastBackup = viewModel.lastBackupTime
        binding.lastBackupText.text = if (lastBackup > 0L) {
            val fmt = SimpleDateFormat("dd MMM yyyy, HH:mm", Locale.getDefault())
            getString(R.string.nextcloud_last_backup, fmt.format(Date(lastBackup)))
        } else {
            getString(R.string.nextcloud_never_backed_up)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
