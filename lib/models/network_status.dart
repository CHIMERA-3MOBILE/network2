/// Professional network status enumeration for state management
enum NetworkStatus {
  /// Network is completely disconnected
  disconnected,
  
  /// Network is connected but no active transfers
  connected,
  
  /// Network is active with ongoing operations
  active,
  
  /// Network is in error state
  error,
  
  /// Network is initializing
  initializing,
  
  /// Network is shutting down
  shuttingDown,
}

/// Network status extension methods for professional handling
extension NetworkStatusExtension on NetworkStatus {
  /// Get human-readable status description
  String get description {
    switch (this) {
      case NetworkStatus.disconnected:
        return 'Disconnected';
      case NetworkStatus.connected:
        return 'Connected';
      case NetworkStatus.active:
        return 'Active';
      case NetworkStatus.error:
        return 'Error';
      case NetworkStatus.initializing:
        return 'Initializing';
      case NetworkStatus.shuttingDown:
        return 'Shutting Down';
    }
  }

  /// Get status color for UI representation
  String get colorHex {
    switch (this) {
      case NetworkStatus.disconnected:
        return '#FF5252'; // Red
      case NetworkStatus.connected:
        return '#4CAF50'; // Green
      case NetworkStatus.active:
        return '#2196F3'; // Blue
      case NetworkStatus.error:
        return '#FF9800'; // Orange
      case NetworkStatus.initializing:
        return '#9C27B0'; // Purple
      case NetworkStatus.shuttingDown:
        return '#607D8B'; // Blue Grey
    }
  }

  /// Check if status indicates connectivity
  bool get isConnected {
    return this == NetworkStatus.connected || this == NetworkStatus.active;
  }

  /// Check if status indicates activity
  bool get isActive {
    return this == NetworkStatus.active;
  }

  /// Check if status indicates error state
  bool get hasError {
    return this == NetworkStatus.error;
  }
}
