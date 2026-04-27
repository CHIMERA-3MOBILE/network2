import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../services/logger_service.dart';
import '../services/settings_service.dart';

class DeviceManagerScreen extends StatefulWidget {
  const DeviceManagerScreen({super.key});

  @override
  State<DeviceManagerScreen> createState() => _DeviceManagerScreenState();
}

class _DeviceManagerScreenState extends State<DeviceManagerScreen> {
  final NetworkService _networkService = NetworkService();
  final LoggerService _logger = LoggerService();
  final SettingsService _settingsService = SettingsService();
  
  List<String> _connectedDevices = [];
  Map<String, Map<String, dynamic>> _deviceInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _setupListeners();
  }

  void _setupListeners() {
    _networkService.deviceListStream.listen((devices) {
      setState(() {
        _connectedDevices = devices;
      });
    });
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final devices = _networkService.connectedDevices;
      setState(() {
        _connectedDevices = devices;
        _isLoading = false;
      });
      _logger.info('Loaded ${devices.length} devices');
    } catch (e) {
      _logger.error('Failed to load devices', error: e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnectDevice(String deviceId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disconnect Device'),
          content: Text('Are you sure you want to disconnect $deviceId?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        // Disconnect logic here
        _logger.info('Disconnecting device: $deviceId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disconnected $deviceId')),
        );
      }
    } catch (e) {
      _logger.error('Failed to disconnect device', error: e);
    }
  }

  void _showDeviceInfo(String deviceId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Device ID', deviceId),
            _buildInfoRow('Status', 'Connected'),
            _buildInfoRow('Protocol', 'P2P Mesh'),
            _buildInfoRow('Encryption', 'AES-256-GCM'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _disconnectDevice(deviceId);
                },
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add manual connection dialog
              _showManualConnectDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _connectedDevices.isEmpty
              ? _buildEmptyState()
              : _buildDeviceList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No devices connected',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start network advertising to discover devices',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _networkService.startAdvertising();
              _networkService.startDiscovery();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Started network discovery...')),
              );
            },
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('Start Discovery'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _connectedDevices.length,
        itemBuilder: (context, index) {
          final device = _connectedDevices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(Icons.smartphone, color: Colors.green[700]),
              ),
              title: Text(
                device,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Connected • P2P Mesh',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showDeviceInfo(device),
                  ),
                  IconButton(
                    icon: const Icon(Icons.link_off, color: Colors.red),
                    onPressed: () => _disconnectDevice(device),
                  ),
                ],
              ),
              onTap: () => _showDeviceInfo(device),
            ),
          );
        },
      ),
    );
  }

  void _showManualConnectDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Connection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Device ID or Endpoint',
            hintText: 'Enter device identifier',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final deviceId = controller.text.trim();
              if (deviceId.isNotEmpty) {
                Navigator.pop(context);
                // Initiate connection
                _logger.info('Manual connection to: $deviceId');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connecting to $deviceId...')),
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
