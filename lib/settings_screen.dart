import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _soundEnabled = prefs.getBool('sound') ?? true;
      _vibrationEnabled = prefs.getBool('vibration') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2ECF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2535)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF2D2535),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Appearance Section
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: const Color(0xFF2D2535),
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(
              _isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
              style: const TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            trailing: Switch(
              value: _isDarkMode,
              activeColor: const Color(0xFF2D2535),
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                _saveSetting('darkMode', value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Dark mode will be available in next update'
                          : 'Light mode activated',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Notifications Section
          const _SectionHeader(title: 'Notifications'),
          ListTile(
            leading: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF2D2535),
            ),
            title: const Text('Push Notifications'),
            subtitle: const Text(
              'Receive notifications for new messages',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            trailing: Switch(
              value: _notificationsEnabled,
              activeColor: const Color(0xFF2D2535),
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSetting('notifications', value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.volume_up_outlined,
              color: Color(0xFF2D2535),
            ),
            title: const Text('Sound'),
            subtitle: const Text(
              'Play sound for incoming messages',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            trailing: Switch(
              value: _soundEnabled,
              activeColor: const Color(0xFF2D2535),
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
                _saveSetting('sound', value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.vibration_outlined,
              color: Color(0xFF2D2535),
            ),
            title: const Text('Vibration'),
            subtitle: const Text(
              'Vibrate on new messages',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            trailing: Switch(
              value: _vibrationEnabled,
              activeColor: const Color(0xFF2D2535),
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
                _saveSetting('vibration', value);
              },
            ),
          ),
          const Divider(height: 1),

          // Privacy & Security Section
          const _SectionHeader(title: 'Privacy & Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Color(0xFF2D2535)),
            title: const Text('Privacy Settings'),
            subtitle: const Text(
              'Manage who can see your information',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF7F7F88)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined, color: Color(0xFF2D2535)),
            title: const Text('Blocked Users'),
            subtitle: const Text(
              'Manage blocked contacts',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF7F7F88)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          const Divider(height: 1),

          // Storage Section
          const _SectionHeader(title: 'Storage'),
          ListTile(
            leading: const Icon(
              Icons.storage_outlined,
              color: Color(0xFF2D2535),
            ),
            title: const Text('Storage Management'),
            subtitle: const Text(
              'Manage app data and cache',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF7F7F88)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Clear Cache',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text(
              'Free up space by clearing cached data',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Cache'),
                  content: const Text(
                    'Are you sure you want to clear all cached data? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              }
            },
          ),
          const Divider(height: 1),

          // About Section
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF2D2535)),
            title: const Text('Version'),
            subtitle: const Text(
              '1.0.0',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: Color(0xFF2D2535),
            ),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF7F7F88)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: Color(0xFF2D2535),
            ),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF7F7F88)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF7F7F88),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
