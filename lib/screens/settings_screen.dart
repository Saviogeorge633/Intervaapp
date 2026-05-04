import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    
    final isDark = themeProvider.isDarkMode;
    final colors = AppColors(isDark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.timer, size: 40, color: colors.accent),
                ),
                const SizedBox(height: 16),
                Text("Interva", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Version 1.0.0", style: TextStyle(color: colors.mutedText)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildSectionTitle('APPEARANCE', context, colors),
          _buildSettingsCard(
            colors: colors,
            children: [
              _buildListTile(
                title: 'Dark Mode',
                icon: Icons.dark_mode_outlined,
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(),
                  activeColor: colors.accent,
                ),
                colors: colors,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('NOTIFICATIONS & ALERTS', context, colors),
          _buildSettingsCard(
            colors: colors,
            children: [
              _buildListTile(
                title: 'Sound Effects',
                icon: Icons.volume_up_outlined,
                trailing: Switch(
                  value: settingsProvider.isSoundOn,
                  onChanged: (val) => settingsProvider.toggleSound(),
                  activeColor: colors.accent,
                ),
                colors: colors,
                showDivider: true,
              ),
              _buildListTile(
                title: 'Vibration',
                icon: Icons.vibration_outlined,
                trailing: Switch(
                  value: settingsProvider.isVibrationOn,
                  onChanged: (val) => settingsProvider.toggleVibration(),
                  activeColor: colors.accent,
                ),
                colors: colors,
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required AppColors colors, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.mutedText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    required Widget trailing,
    required AppColors colors,
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors.primaryText, size: 20),
          ),
          title: Text(title, style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.w500)),
          trailing: trailing,
        ),
        if (showDivider)
          Divider(height: 1, indent: 64, color: colors.background),
      ],
    );
  }
}
