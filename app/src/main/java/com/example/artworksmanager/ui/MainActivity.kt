package com.example.artworksmanager.ui

import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.setupWithNavController
import com.example.artworksmanager.R
import com.example.artworksmanager.databinding.ActivityMainBinding

/**
 * Single-activity host that owns the Navigation component and bottom navigation bar.
 * The bottom nav is hidden automatically on non-top-level destinations.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // On Android 15+ (targetSdk 35) edge-to-edge is enforced: content draws
        // behind the status bar and navigation bar. Apply insets manually so the
        // toolbar clears the status bar and the bottom nav clears the nav bar.
        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            binding.navHostFragment.updatePadding(top = bars.top)
            binding.bottomNav.updatePadding(bottom = bars.bottom)
            // Return insets (not CONSUMED) so IME insets propagate to fragments
            // where individual scroll views can adjust their bottom padding.
            insets
        }

        val navHost = supportFragmentManager.findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        val navController = navHost.navController

        binding.bottomNav.setupWithNavController(navController)

        val topLevel = setOf(R.id.dashboardFragment, R.id.collectionFragment, R.id.settingsFragment)
        navController.addOnDestinationChangedListener { _, destination, _ ->
            binding.bottomNav.visibility =
                if (destination.id in topLevel) View.VISIBLE else View.GONE
        }
    }
}
