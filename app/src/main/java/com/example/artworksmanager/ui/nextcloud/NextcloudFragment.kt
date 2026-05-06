package com.example.artworksmanager.ui.nextcloud

import android.os.Bundle
import android.view.*
import androidx.core.view.isVisible
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.fragment.findNavController
import com.example.artworksmanager.ArtworksManagerApp
import com.example.artworksmanager.databinding.FragmentNextcloudBinding
import kotlinx.coroutines.launch

class NextcloudFragment : Fragment() {

    private var _binding: FragmentNextcloudBinding? = null
    private val binding get() = _binding!!

    private val viewModel: NextcloudViewModel by viewModels {
        NextcloudViewModel.factory(
            (requireActivity().application as ArtworksManagerApp).nextcloudPreferences
        )
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

        // Pre-fill saved values
        if (viewModel.savedServerUrl.isNotEmpty()) {
            binding.serverUrlInput.setText(viewModel.savedServerUrl)
            binding.usernameInput.setText(viewModel.savedUsername)
            binding.appPasswordInput.setText(viewModel.savedAppPassword)
        }

        binding.connectButton.setOnClickListener {
            viewModel.connect(
                serverUrl   = binding.serverUrlInput.text?.toString() ?: "",
                username    = binding.usernameInput.text?.toString() ?: "",
                appPassword = binding.appPasswordInput.text?.toString() ?: ""
            )
        }

        binding.disconnectButton.setOnClickListener { viewModel.disconnect() }

        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.state.collect { state -> applyState(state) }
            }
        }
    }

    private fun applyState(state: NextcloudViewModel.State) {
        val testing = state is NextcloudViewModel.State.Testing
        val connected = state is NextcloudViewModel.State.Connected

        binding.progressBar.isVisible     = testing
        binding.connectButton.isEnabled   = !testing
        binding.disconnectButton.isVisible = connected
        binding.connectButton.isVisible    = !connected

        binding.statusCard.isVisible = connected || state is NextcloudViewModel.State.Error
        if (connected) {
            val prefs = (requireActivity().application as ArtworksManagerApp).nextcloudPreferences
            binding.statusText.text = "Connected as ${prefs.username}\n${prefs.serverUrl}"
            binding.statusText.setTextColor(
                requireContext().getColor(com.example.artworksmanager.R.color.text_primary)
            )
            binding.statusIcon.setImageResource(android.R.drawable.ic_menu_upload)
        } else if (state is NextcloudViewModel.State.Error) {
            binding.statusText.text = state.message
            binding.statusText.setTextColor(
                requireContext().getColor(android.R.color.holo_red_dark)
            )
            binding.statusIcon.setImageResource(android.R.drawable.ic_dialog_alert)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
