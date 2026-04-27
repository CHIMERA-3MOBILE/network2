import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/logger_service.dart';
import '../services/network_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final LoggerService _logger = LoggerService();
  final NetworkService _networkService = NetworkService();
  
  String _deviceName = '';
  bool _autoStartNetwork = true;
  bool _encryptionEnabled = true;
  int _maxHops = 5;
  int _discoveryInterval = 30;
  String _logLevel = 'INFO';
  bool _backgroundService = true;
  bool _batteryOptimization = false;
  bool _isLoading = true;

  final List<String> _logLevels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'FATAL'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      _deviceName = await _settingsService.getDeviceName();
      _autoStartNetwork = await _settingsService.getAutoStartNetwork();
      _encryptionEnabled = await _settingsService.getEncryptionEnabled();
      _maxHops = await _settingsService.getMaxHops();
      _discoveryInterval = await _settingsService.getDiscoveryInterval();
      _logLevel = await _settingsService.getLogLevel();
      _backgroundService = await _settingsService.getBackgroundService();
      _batteryOptimization = await _settingsService.getBatteryOptimization();
      
      setState(() => _isLoading = false);
    } catch (e) {
      _logger.error('Failed to load settings', error: e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDeviceName(String value) async {
    try {
      await _settingsService.setDeviceName(value);
      setState(() => _deviceName = value);
      _logger.info('Device name updated: $value');
    } catch (e) {
      _logger.error('Failed to save device name', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _settingsService.resetToDefaults();
      await _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefaults,
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader('Device Settings'),
                _buildTextTile(
                  'Device Name',
                  _deviceName,
                  Icons.devices,
                  () => _showEditDialog('Device Name', _deviceName, _saveDeviceName),
                ),
                
                _buildSectionHeader('Network Settings'),
                _buildSwitchTile(
                  'Auto-start Network',
                  'Automatically start network on app launch',
                  _autoStartNetwork,
                  (value) async {
                    await _settingsService.setAutoStartNetwork(value);
                    setState(() => _autoStartNetwork = value);
                  },
                ),
                _buildSwitchTile(
                  'Encryption Enabled',
                  'Use AES-256-GCM encryption for messages',
                  _encryptionEnabled,
                  (value) async {
                    await _settingsService.setEncryptionEnabled(value);
                    setState(() => _encryptionEnabled = value);
                  },
                ),
                _buildSliderTile(
                  'Max Hops',
                  'Maximum message relay hops: $_maxHops',
                  _maxHops.toDouble(),
                  1,
                  10,
                  (value) async {
                    await _settingsService.setMaxHops(value.toInt());
                    setState(() => _maxHops = value.toInt());
                  },
                ),
                _buildSliderTile(
                  'Discovery Interval',
                  'Device discovery interval: ${_discoveryInterval}s',
                  _discoveryInterval.toDouble(),
                  5,
                  300,
                  (value) async {
                    await _settingsService.setDiscoveryInterval(value.toInt());
                    setState(() => _discoveryInterval = value.toInt());
                  },
                ),
                
                _buildSectionHeader('Service Settings'),
                _buildSwitchTile(
                  'Background Service',
                  'Keep network active in background',
                  _backgroundService,
                  (value) async {
                    await _settingsService.setBackgroundService(value);
                    setState(() => _backgroundService = value);
                  },
                ),
                _buildSwitchTile(
                  'Battery Optimization',
                  'Optimize for battery life (may affect performance)',
                  _batteryOptimization,
                  (value) async {
                    await _settingsService.setBatteryOptimization(value);
                    setState(() => _batteryOptimization = value);
                  },
                ),
                
                _buildSectionHeader('Debug Settings'),
                _buildDropdownTile(
                  'Log Level',
                  'Current: $_logLevel',
                  Icons.bug_report,
                  _logLevel,
                  _logLevels,
                  (value) async {
                    if (value != null) {
                      await _settingsService.setLogLevel(value);
                      setState(() => _logLevel = value);
                    }
                  },
                ),
                
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Network Statistics'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Connected Devices: ${_networkService.deviceCount}'),
                              Text('Is Advertising: ${_networkService.isAdvertising}'),
                              Text('Is Discovering: ${_networkService.isDiscovering}'),
                              Text('Is Initialized: ${_networkService.isInitialized}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Network Statistics'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      secondary: const Icon(Icons.settings),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value, double min, double max, Function(double) onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, IconData icon, String value, List<String> items, Function(String?) onChanged) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _showEditDialog(String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSave(controller.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
