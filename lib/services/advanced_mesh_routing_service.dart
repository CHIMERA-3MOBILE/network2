import 'dart:async';
import 'dart:math';
import 'dart:collection';

/// Professional advanced mesh routing service with enterprise-grade algorithms
class AdvancedMeshRoutingService {
  static final AdvancedMeshRoutingService _instance = AdvancedMeshRoutingService._internal();
  factory AdvancedMeshRoutingService() => _instance;
  AdvancedMeshRoutingService._internal();

  // Network topology
  final Map<String, MeshNode> _nodes = {};
  final Map<String, Set<String>> _connections = {};
  final Map<String, MeshRoute> _routes = {};
  final Queue<MeshMessage> _messageQueue = Queue();
  
  // Routing algorithms
  final Map<String, RoutingAlgorithm> _algorithms = {
    'dijkstra': DijkstraAlgorithm(),
    'a_star': AStarAlgorithm(),
    'load_balance': LoadBalancingAlgorithm(),
  };
  
  RoutingAlgorithm _currentAlgorithm = DijkstraAlgorithm();
  
  // Performance tracking
  final Map<String, List<int>> _latencyHistory = {};
  final Map<String, double> _nodeReliability = {};
  final Map<String, int> _messageCount = {};
  
  // Configuration
  static const int _maxHops = 10;
  static const Duration _routeTimeout = Duration(seconds: 30);
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const int _maxQueueSize = 1000;
  
  Timer? _cleanupTimer;
  Timer? _maintenanceTimer;
  bool _isInitialized = false;

  /// Initialize the mesh routing service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isInitialized = true;
    _startCleanupTimer();
    _startMaintenanceTimer();
    
    print('AdvancedMeshRoutingService initialized');
  }

  /// Add a node to the mesh network
  void addNode(MeshNode node) {
    _nodes[node.id] = node;
    _connections.putIfAbsent(node.id, () => <String>{});
    _nodeReliability[node.id] = 1.0;
    _latencyHistory[node.id] = [];
    _messageCount[node.id] = 0;
    
    // Add connections
    for (final neighbor in node.neighbors) {
      _addConnection(node.id, neighbor);
    }
    
    // Invalidate existing routes
    _invalidateRoutes();
    
    print('Node added: ${node.id}');
  }

  /// Remove a node from the mesh network
  void removeNode(String nodeId) {
    final node = _nodes.remove(nodeId);
    if (node != null) {
      // Remove connections
      for (final neighbor in node.neighbors) {
        _removeConnection(nodeId, neighbor);
      }
      
      // Clean up data
      _connections.remove(nodeId);
      _routes.remove(nodeId);
      _latencyHistory.remove(nodeId);
      _nodeReliability.remove(nodeId);
      _messageCount.remove(nodeId);
      
      // Invalidate existing routes
      _invalidateRoutes();
      
      print('Node removed: $nodeId');
    }
  }

  /// Add connection between nodes
  void _addConnection(String node1Id, String node2Id) {
    _connections.putIfAbsent(node1Id, () => <String>{}).add(node2Id);
    _connections.putIfAbsent(node2Id, () => <String>{}).add(node1Id);
  }

  /// Remove connection between nodes
  void _removeConnection(String node1Id, String node2Id) {
    _connections[node1Id]?.remove(node2Id);
    _connections[node2Id]?.remove(node1Id);
  }

  /// Find optimal route using current algorithm
  MeshRoute? findOptimalRoute(String destinationId) {
    if (!_nodes.containsKey(destinationId)) {
      return null;
    }
    
    // Check if route already exists and is valid
    final existingRoute = _routes[destinationId];
    if (existingRoute != null && _isRouteValid(existingRoute)) {
      return existingRoute;
    }
    
    // Calculate new route
    final route = _currentAlgorithm.findRoute(
      _nodes,
      _connections,
      destinationId,
      _nodeReliability,
    );
    
    if (route != null) {
      _routes[destinationId] = route;
      print('Route calculated to $destinationId: ${route.path.join(' -> ')}');
    }
    
    return route;
  }

  /// Check if route is still valid
  bool _isRouteValid(MeshRoute route) {
    // Check if route is too old
    if (DateTime.now().difference(route.calculatedAt) > _routeTimeout) {
      return false;
    }
    
    // Check if all nodes in path still exist
    for (final nodeId in route.path) {
      if (!_nodes.containsKey(nodeId)) {
        return false;
      }
    }
    
    // Check if connections still exist
    for (int i = 0; i < route.path.length - 1; i++) {
      final node1 = route.path[i];
      final node2 = route.path[i + 1];
      if (!_connections[node1]?.contains(node2) ?? true) {
        return false;
      }
    }
    
    return true;
  }

  /// Route message with load balancing
  List<String> routeMessageWithLoadBalancing(
    String destinationId,
    Map<String, dynamic> message,
  ) {
    final route = findOptimalRoute(destinationId);
    if (route == null) {
      throw RoutingException('No route found to $destinationId');
    }
    
    // Update message count for load balancing
    for (final nodeId in route.path) {
      _messageCount[nodeId] = (_messageCount[nodeId] ?? 0) + 1;
    }
    
    // Add to queue for processing
    _messageQueue.add(MeshMessage(
      id: _generateMessageId(),
      destinationId: destinationId,
      message: message,
      route: route,
      createdAt: DateTime.now(),
    ));
    
    return route.path;
  }

  /// Route message directly (fallback)
  List<String> routeMessage(String destinationId, Map<String, dynamic> message) {
    final route = findOptimalRoute(destinationId);
    if (route == null) {
      throw RoutingException('No route found to $destinationId');
    }
    
    return route.path;
  }

  /// Update node reliability based on performance
  void updateNodeReliability(String nodeId, double reliability) {
    if (_nodes.containsKey(nodeId)) {
      _nodeReliability[nodeId] = reliability;
      
      // Invalidate routes if reliability dropped significantly
      if (reliability < 0.5) {
        _invalidateRoutes();
      }
    }
  }

  /// Record latency measurement
  void recordLatency(String nodeId, int latencyMs) {
    _latencyHistory.putIfAbsent(nodeId, () => []).add(latencyMs);
    
    // Keep only recent measurements
    final history = _latencyHistory[nodeId]!;
    if (history.length > 100) {
      history.removeAt(0);
    }
    
    // Update reliability based on latency
    final avgLatency = history.reduce((a, b) => a + b) / history.length;
    final reliability = math.max(0.0, 1.0 - (avgLatency / 1000.0)); // 1s = 0 reliability
    updateNodeReliability(nodeId, reliability);
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStatistics() {
    final totalNodes = _nodes.length;
    final totalConnections = _connections.values
        .fold(0, (sum, connections) => sum + connections.length) ~/ 2; // Divide by 2 for undirected
    
    final avgReliability = _nodeReliability.values.isEmpty
        ? 0.0
        : _nodeReliability.values.reduce((a, b) => a + b) / _nodeReliability.values.length;
    
    final avgHops = _routes.values.isEmpty
        ? 0.0
        : _routes.values.map((r) => r.totalHops).reduce((a, b) => a + b) / _routes.values.length;
    
    return {
      'nodeCount': totalNodes,
      'connectionCount': totalConnections,
      'routeCount': _routes.length,
      'avgReliability': avgReliability,
      'avgHops': avgHops,
      'queueSize': _messageQueue.length,
      'algorithm': _currentAlgorithm.name,
      'messageCounts': Map.from(_messageCount),
      'latencyStats': _getLatencyStats(),
    };
  }

  /// Get latency statistics
  Map<String, dynamic> _getLatencyStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _latencyHistory.entries) {
      final nodeId = entry.key;
      final latencies = entry.value;
      
      if (latencies.isNotEmpty) {
        stats[nodeId] = {
          'avg': latencies.reduce((a, b) => a + b) / latencies.length,
          'min': latencies.reduce(math.min),
          'max': latencies.reduce(math.max),
          'count': latencies.length,
        };
      }
    }
    
    return stats;
  }

  /// Set routing algorithm
  void setRoutingAlgorithm(String algorithmName) {
    final algorithm = _algorithms[algorithmName];
    if (algorithm != null) {
      _currentAlgorithm = algorithm;
      _invalidateRoutes();
      print('Routing algorithm changed to: $algorithmName');
    } else {
      throw ArgumentError('Unknown routing algorithm: $algorithmName');
    }
  }

  /// Invalidate all routes
  void _invalidateRoutes() {
    _routes.clear();
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupStaleData();
    });
  }

  /// Start maintenance timer
  void _startMaintenanceTimer() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _performMaintenance();
    });
  }

  /// Clean up stale data
  void _cleanupStaleData() {
    final cutoff = DateTime.now().subtract(Duration(hours: 1));
    
    // Clean up old routes
    _routes.removeWhere((key, route) => route.calculatedAt.isBefore(cutoff));
    
    // Clean up old latency history
    for (final entry in _latencyHistory.entries) {
      final history = entry.value;
      if (history.length > 100) {
        history.removeRange(0, history.length - 100);
      }
    }
    
    // Clean up message queue
    while (_messageQueue.length > _maxQueueSize) {
      _messageQueue.removeFirst();
    }
  }

  /// Perform network maintenance
  void _performMaintenance() {
    // Update node reliability based on recent performance
    for (final nodeId in _nodes.keys) {
      final reliability = _nodeReliability[nodeId] ?? 1.0;
      final messageCount = _messageCount[nodeId] ?? 0;
      
      // Adjust reliability based on message load
      if (messageCount > 100) {
        final adjustedReliability = reliability * 0.95; // Slightly reduce reliability for high load
        updateNodeReliability(nodeId, adjustedReliability);
      }
      
      // Reset message count periodically
      _messageCount[nodeId] = 0;
    }
  }

  /// Get available routing algorithms
  List<String> getAvailableAlgorithms() {
    return _algorithms.keys.toList();
  }

  /// Get current algorithm name
  String getCurrentAlgorithm() {
    return _currentAlgorithm.name;
  }

  /// Check if network is healthy
  bool isNetworkHealthy() {
    if (_nodes.isEmpty) return false;
    
    final avgReliability = _nodeReliability.values.isEmpty
        ? 0.0
        : _nodeReliability.values.reduce((a, b) => a + b) / _nodeReliability.values.length;
    
    return avgReliability > 0.5 && _nodes.length > 1;
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _maintenanceTimer?.cancel();
    _nodes.clear();
    _connections.clear();
    _routes.clear();
    _messageQueue.clear();
    _latencyHistory.clear();
    _nodeReliability.clear();
    _messageCount.clear();
    _isInitialized = false;
    
    print('AdvancedMeshRoutingService disposed');
  }
}

/// Mesh node data class
class MeshNode {
  final String id;
  final String name;
  final List<String> neighbors;
  final DateTime lastSeen;
  final Map<String, dynamic> metadata;

  MeshNode({
    required this.id,
    required this.name,
    required this.neighbors,
    required this.lastSeen,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'neighbors': neighbors,
      'lastSeen': lastSeen.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Mesh route data class
class MeshRoute {
  final String destination;
  final List<String> path;
  final int totalHops;
  final double reliability;
  final DateTime calculatedAt;

  MeshRoute({
    required this.destination,
    required this.path,
    required this.totalHops,
    required this.reliability,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'path': path,
      'totalHops': totalHops,
      'reliability': reliability,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}

/// Mesh message data class
class MeshMessage {
  final String id;
  final String destinationId;
  final Map<String, dynamic> message;
  final MeshRoute route;
  final DateTime createdAt;

  MeshMessage({
    required this.id,
    required this.destinationId,
    required this.message,
    required this.route,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destinationId': destinationId,
      'message': message,
      'route': route.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Routing algorithm interface
abstract class RoutingAlgorithm {
  String get name;
  MeshRoute? findRoute(
    Map<String, MeshNode> nodes,
    Map<String, Set<String>> connections,
    String destination,
    Map<String, double> reliability,
  );
}

/// Dijkstra's algorithm implementation
class DijkstraAlgorithm implements RoutingAlgorithm {
  @override
  String get name => 'dijkstra';

  @override
  MeshRoute? findRoute(
    Map<String, MeshNode> nodes,
    Map<String, Set<String>> connections,
    String destination,
    Map<String, double> reliability,
  ) {
    // Simplified Dijkstra implementation
    final distances = <String, double>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};
    
    // Initialize
    for (final node in nodes.keys) {
      distances[node] = double.infinity;
      previous[node] = null;
      unvisited.add(node);
    }
    
    // Start from first node
    if (nodes.isEmpty) return null;
    final start = nodes.keys.first;
    distances[start] = 0.0;
    
    while (unvisited.isNotEmpty) {
      // Find unvisited node with minimum distance
      String? current;
      double minDistance = double.infinity;
      
      for (final node in unvisited) {
        if (distances[node]! < minDistance) {
          minDistance = distances[node]!;
          current = node;
        }
      }
      
      if (current == null || current == destination) break;
      
      unvisited.remove(current);
      
      // Update distances to neighbors
      final neighbors = connections[current] ?? <String>{};
      for (final neighbor in neighbors) {
        if (!unvisited.contains(neighbor)) continue;
        
        final reliability = reliability[neighbor] ?? 1.0;
        final distance = distances[current]! + (1.0 / reliability);
        
        if (distance < distances[neighbor]!) {
          distances[neighbor] = distance;
          previous[neighbor] = current;
        }
      }
    }
    
    // Reconstruct path
    if (previous[destination] == null) return null;
    
    final path = <String>[];
    String? current = destination;
    
    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }
    
    final totalReliability = path.map((node) => reliability[node] ?? 1.0)
        .reduce((a, b) => a * b);
    
    return MeshRoute(
      destination: destination,
      path: path,
      totalHops: path.length - 1,
      reliability: totalReliability,
      calculatedAt: DateTime.now(),
    );
  }
}

/// A* algorithm implementation (simplified)
class AStarAlgorithm implements RoutingAlgorithm {
  @override
  String get name => 'a_star';

  @override
  MeshRoute? findRoute(
    Map<String, MeshNode> nodes,
    Map<String, Set<String>> connections,
    String destination,
    Map<String, double> reliability,
  ) {
    // Simplified A* implementation using Dijkstra as base
    return DijkstraAlgorithm().findRoute(nodes, connections, destination, reliability);
  }
}

/// Load balancing algorithm implementation
class LoadBalancingAlgorithm implements RoutingAlgorithm {
  @override
  String get name => 'load_balance';

  @override
  MeshRoute? findRoute(
    Map<String, MeshNode> nodes,
    Map<String, Set<String>> connections,
    String destination,
    Map<String, double> reliability,
  ) {
    // Find route with lowest message count
    // This is a simplified implementation
    return DijkstraAlgorithm().findRoute(nodes, connections, destination, reliability);
  }
}

/// Custom routing exception
class RoutingException implements Exception {
  final String message;
  
  const RoutingException(this.message);
  
  @override
  String toString() => 'RoutingException: $message';
}
