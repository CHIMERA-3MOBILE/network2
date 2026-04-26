import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:animations/animations.dart';

/// Professional enhanced UI components with Material Design 3
class EnhancedUIComponents {
  // Color palette
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  final DateTime? lastModified;
  final bool isSelected;

  const EnhancedFileItem({
    super.key,
    required this.name,
    required this.type,
    required this.onTap,
    this.onLongPress,
    this.size = 0,
    this.lastModified,
    this.isSelected = false,
  });

  @override
  State<EnhancedFileItem> createState() => _EnhancedFileItemState();
}

class _EnhancedFileItemState extends State<EnhancedFileItem>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.ease,
    ));

    _slideController.forward();
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.isSelected 
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.white,
                widget.isSelected
                    ? Colors.blue.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.01),
              ],
            ),
            boxShadow: [
              if (_isHovered || widget.isSelected)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: widget.isSelected
                  ? Colors.blue.withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _scaleController.forward().then((_) {
                  _scaleController.reverse();
                });
                widget.onTap();
              },
              onLongPress: widget.onLongPress,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildIcon(),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFileInfo()),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getIconColor().withOpacity(0.8),
            _getIconColor().withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getIconColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _getIcon(),
              color: Colors.white,
              size: 24,
            ),
          ),
          if (_isHovered)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shimmerAnimation.value * 48, 0),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.isSelected ? Colors.blue : Colors.grey[800],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              _formatFileSize(widget.size),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (widget.lastModified != null) ...[
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(widget.lastModified!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return AnimatedOpacity(
      opacity: _isHovered ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.share,
            onPressed: () {
              // Share functionality
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.more_vert,
            onPressed: () {
              // More options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.type.toLowerCase()) {
      case 'folder':
        return Icons.folder;
      case 'document':
      case 'documents':
        return Icons.description;
      case 'download':
      case 'downloads':
        return Icons.download;
      case 'picture':
      case 'pictures':
        return Icons.image;
      case 'video':
      case 'videos':
        return Icons.videocam;
      case 'music':
        return Icons.music_note;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getIconColor() {
    switch (widget.type.toLowerCase()) {
      case 'folder':
        return Colors.blue;
      case 'document':
      case 'documents':
        return Colors.indigo;
      case 'download':
      case 'downloads':
        return Colors.green;
      case 'picture':
      case 'pictures':
        return Colors.purple;
      case 'video':
      case 'videos':
        return Colors.red;
      case 'music':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class EnhancedNetworkStatusCard extends StatefulWidget {
  final bool isActive;
  final int connectedDevices;
  final VoidCallback onToggle;
  final VoidCallback onSettings;
  final double signalStrength;

  const EnhancedNetworkStatusCard({
    super.key,
    required this.isActive,
    required this.connectedDevices,
    required this.onToggle,
    required this.onSettings,
    this.signalStrength = 0.8,
  });

  @override
  State<EnhancedNetworkStatusCard> createState() => _EnhancedNetworkStatusCardState();
}

class _EnhancedNetworkStatusCardState extends State<EnhancedNetworkStatusCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(EnhancedNetworkStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _waveController.stop();
        _waveController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isActive
              ? [
                  Colors.teal.withOpacity(0.1),
                  Colors.blue.withOpacity(0.05),
                ]
              : [
                  Colors.grey.withOpacity(0.05),
                  Colors.grey.withOpacity(0.02),
                ],
        ),
        border: Border.all(
          color: widget.isActive
              ? Colors.teal.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          if (widget.isActive)
            BoxShadow(
              color: Colors.teal.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (widget.isActive) _buildWaveEffect(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSignalIndicator(),
                const SizedBox(height: 16),
                _buildDeviceCount(),
                const SizedBox(height: 16),
                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveEffect() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: _waveAnimation.value * 2,
                  colors: [
                    Colors.teal.withOpacity(0.1 * (1 - _waveAnimation.value)),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isActive ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isActive
                        ? [Colors.teal, Colors.blue]
                        : [Colors.grey, Colors.grey.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (widget.isActive)
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Icon(
                  widget.isActive ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Network Status',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isActive ? Colors.teal : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: widget.isActive,
          onChanged: (_) => widget.onToggle(),
          activeColor: Colors.teal,
          activeTrackColor: Colors.teal.withOpacity(0.3),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildSignalIndicator() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.withOpacity(0.2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widget.signalStrength,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.teal,
                Colors.blue,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCount() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.blue.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.devices,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.connectedDevices}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'device${widget.connectedDevices != 1 ? 's' : ''} connected',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: widget.onSettings,
          icon: const Icon(Icons.settings, size: 18),
          label: const Text('Advanced Settings'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blue.withOpacity(0.3)),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.isActive ? 'SECURED' : 'OFFLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: widget.isActive ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
