import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'logger_service.dart';

class MeshNode {
  final String id;
  final String name;
  final List<String> neighbors;
  final int hopCount;
  final DateTime lastSeen;
  final double signalStrength;
  final Map<String, dynamic> metadata;

  MeshNode({
    required this.id,
    required this.name,
    required this.neighbors,
    this.hopCount = 0,
    required this.lastSeen,
    this.signalStrength = 1.0,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'neighbors': neighbors,
      'hopCount': hopCount,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'signalStrength': signalStrength,
      'metadata': metadata,
    };
  }

  factory MeshNode.fromJson(Map<String, dynamic> json) {
    return MeshNode(
      id: json['id'],
      name: json['name'],
      neighbors: List<String>.from(json['neighbors'] ?? []),
      hopCount: json['hopCount'] ?? 0,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen']),
      signalStrength: json['signalStrength']?.toDouble() ?? 1.0,
      metadata: json['metadata'] ?? {},
    );
  }
}

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
      'calculatedAt': calculatedAt.millisecondsSinceEpoch,
    };
  }
}

class AdvancedMeshRoutingService {
  static final AdvancedMeshRoutingService _instance = AdvancedMeshRoutingService._internal();
  factory AdvancedMeshRoutingService() => _instance;
  AdvancedMeshRoutingService._internal();

  final LoggerService _logger = LoggerService();
  
  // Network topology
  final Map<String, MeshNode> _nodes = {};
  final Map<String, MeshRoute> _routes = {};
  final Map<String, List<String>> _adjacencyList = {};
  
  // Routing algorithms
  final Map<String, double> _nodeReliability = {};
  final Map<String, int> _nodeLatency = {};
  final Map<String, int> _messageCounts = {};
  
  // Performance metrics
  final Queue<Map<String, dynamic>> _recentMessages = Queue();
  final Map<String, DateTime> _lastMessageTime = {};
  
  Timer? _maintenanceTimer;
  Timer? _routeUpdateTimer;

  void initialize() {
    _maintenanceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performMaintenance();
    });
    
    _routeUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateRoutes();
    });
    
    _logger.info('Advanced mesh routing service initialized', tag: 'MeshRouting');
  }

  void dispose() {
    _maintenanceTimer?.cancel();
    _routeUpdateTimer?.cancel();
    _logger.info('Advanced mesh routing service disposed', tag: 'MeshRouting');
  }

  // Node management
  void addNode(MeshNode node) {
    _nodes[node.id] = node;
    _updateAdjacencyList();
    _updateRoutes();
    _logger.info('Added node: ${node.name} (${node.id})', tag: 'MeshRouting');
  }

  void removeNode(String nodeId) {
    _nodes.remove(nodeId);
    _adjacencyList.remove(nodeId);
    _routes.removeWhere((key, route) => route.path.contains(nodeId));
    _updateAdjacencyList();
    _updateRoutes();
    _logger.info('Removed node: $nodeId', tag: 'MeshRouting');
  }

  void updateNode(String nodeId, Map<String, dynamic> updates) {
    final node = _nodes[nodeId];
    if (node != null) {
      final updatedNode = MeshNode(
        id: node.id,
        name: updates['name'] ?? node.name,
        neighbors: List<String>.from(updates['neighbors'] ?? node.neighbors),
        hopCount: updates['hopCount'] ?? node.hopCount,
        lastSeen: updates['lastSeen'] ?? node.lastSeen,
        signalStrength: updates['signalStrength']?.toDouble() ?? node.signalStrength,
        metadata: {...node.metadata, ...updates['metadata'] ?? {}},
      );
      
      _nodes[nodeId] = updatedNode;
      _updateAdjacencyList();
      _updateRoutes();
    }
  }

  // Routing algorithms
  MeshRoute? findOptimalRoute(String destination, {String? excludeNode}) {
    final routes = _findAllRoutes(destination, excludeNode: excludeNode);
    if (routes.isEmpty) return null;

    // Sort by reliability, then by hop count
    routes.sort((a, b) {
      if (a.reliability != b.reliability) {
        return b.reliability.compareTo(a.reliability);
      }
      return a.totalHops.compareTo(b.totalHops);
    });

    return routes.first;
  }

  List<MeshRoute> _findAllRoutes(String destination, {String? excludeNode}) {
    final routes = <MeshRoute>[];
    final visited = <String>{};
    
    if (_adjacencyList.isEmpty) return routes;

    // BFS to find all paths
    _bfsFindRoutes(
      start: 'current', // Current node
      destination: destination,
      path: [],
      visited: visited,
      routes: routes,
      excludeNode: excludeNode,
    );

    return routes;
  }

  void _bfsFindRoutes({
    required String start,
    required String destination,
    required List<String> path,
    required Set<String> visited,
    required List<MeshRoute> routes,
    String? excludeNode,
  }) {
    if (excludeNode != null && path.contains(excludeNode)) return;

    final currentPath = List<String>.from(path)..add(start);
    visited.add(start);

    if (start == destination) {
      routes.add(_createRoute(destination, currentPath));
      return;
    }

    final neighbors = _adjacencyList[start] ?? [];
    for (final neighbor in neighbors) {
      if (!visited.contains(neighbor)) {
        _bfsFindRoutes(
          start: neighbor,
          destination: destination,
          path: currentPath,
          visited: Set<String>.from(visited),
          routes: routes,
          excludeNode: excludeNode,
        );
      }
    }
  }

  MeshRoute _createRoute(String destination, List<String> path) {
    final reliability = _calculateRouteReliability(path);
    return MeshRoute(
      destination: destination,
      path: path,
      totalHops: path.length - 1,
      reliability: reliability,
      calculatedAt: DateTime.now(),
    );
  }

  double _calculateRouteReliability(List<String> path) {
    if (path.isEmpty) return 0.0;

    double totalReliability = 1.0;
    for (final nodeId in path) {
      totalReliability *= _nodeReliability[nodeId] ?? 0.5;
    }

    // Apply hop penalty
    final hopPenalty = pow(0.9, path.length - 1).toDouble();
    return totalReliability * hopPenalty;
  }

  // Message routing
  List<String> routeMessage(String destination, Map<String, dynamic> message) {
    final route = findOptimalRoute(destination);
    if (route == null) {
      _logger.warning('No route found to destination: $destination', tag: 'MeshRouting');
      return [];
    }

    _recordMessage(message, route);
    _updateNodeReliability(route.path.first, true);
    
    return route.path;
  }

  void _recordMessage(Map<String, dynamic> message, MeshRoute route) {
    _recentMessages.add({
      'message': message,
      'route': route.toJson(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Keep only last 1000 messages
    while (_recentMessages.length > 1000) {
      _recentMessages.removeFirst();
    }

    // Update message counts
    for (final nodeId in route.path) {
      _messageCounts[nodeId] = (_messageCounts[nodeId] ?? 0) + 1;
    }
  }

  void _updateNodeReliability(String nodeId, bool success) {
    final currentReliability = _nodeReliability[nodeId] ?? 0.5;
    final newReliability = success 
        ? (currentReliability * 0.9) + (1.0 * 0.1)  // Increase reliability
        : (currentReliability * 0.9) + (0.0 * 0.1); // Decrease reliability

    _nodeReliability[nodeId] = newReliability.clamp(0.0, 1.0);
  }

  // Network maintenance
  void _performMaintenance() {
    final now = DateTime.now();
    final staleNodes = <String>[];

    for (final entry in _nodes.entries) {
      if (now.difference(entry.value.lastSeen).inMinutes > 10) {
        staleNodes.add(entry.key);
      }
    }

    for (final nodeId in staleNodes) {
      removeNode(nodeId);
    }

    _cleanupOldMessages();
    _logger.info('Maintenance completed. Removed ${staleNodes.length} stale nodes', tag: 'MeshRouting');
  }

  void _cleanupOldMessages() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _recentMessages.removeWhere((message) => 
        DateTime.fromMillisecondsSinceEpoch(message['timestamp']).isBefore(cutoff));
  }

  void _updateAdjacencyList() {
    _adjacencyList.clear();
    
    for (final node in _nodes.values) {
      _adjacencyList[node.id] = List<String>.from(node.neighbors);
    }
  }

  void _updateRoutes() {
    _routes.clear();
    
    for (final nodeId in _nodes.keys) {
      if (nodeId != 'current') { // Don't create route to self
        final route = findOptimalRoute(nodeId);
        if (route != null) {
          _routes[nodeId] = route;
        }
      }
    }
  }

  // Analytics and monitoring
  Map<String, dynamic> getNetworkStatistics() {
    final nodeCount = _nodes.length;
    final routeCount = _routes.length;
    final avgReliability = _nodeReliability.values.isEmpty 
        ? 0.0 
        : _nodeReliability.values.reduce((a, b) => a + b) / _nodeReliability.length;
    
    final avgHops = _routes.values.isEmpty 
        ? 0.0 
        : _routes.values.map((r) => r.totalHops).reduce((a, b) => a + b) / _routes.length;

    return {
      'nodeCount': nodeCount,
      'routeCount': routeCount,
      'avgReliability': avgReliability,
      'avgHops': avgHops,
      'totalMessages': _recentMessages.length,
      'activeNodes': _nodes.values.where((n) => 
          DateTime.now().difference(n.lastSeen).inMinutes < 5).length,
    };
  }

  List<Map<String, dynamic>> getNetworkTopology() {
    return _nodes.values.map((node) => node.toJson()).toList();
  }

  Map<String, dynamic> getRoutingTable() {
    return _routes.map((key, route) => MapEntry(key, route.toJson()));
  }

  // Advanced routing algorithms
  MeshRoute? findRouteWithConstraints(
    String destination, {
    int maxHops = 10,
    double minReliability = 0.5,
    List<String>? avoidNodes,
  }) {
    final routes = _findAllRoutes(destination);
    
    final filteredRoutes = routes.where((route) {
      if (route.totalHops > maxHops) return false;
      if (route.reliability < minReliability) return false;
      if (avoidNodes != null && route.path.any((node) => avoidNodes.contains(node))) return false;
      return true;
    }).toList();

    if (filteredRoutes.isEmpty) return null;

    // Sort by a weighted score
    filteredRoutes.sort((a, b) {
      final scoreA = (a.reliability * 0.7) - (a.totalHops * 0.3);
      final scoreB = (b.reliability * 0.7) - (b.totalHops * 0.3);
      return scoreB.compareTo(scoreA);
    });

    return filteredRoutes.first;
  }

  // Load balancing
  List<String> routeMessageWithLoadBalancing(String destination, Map<String, dynamic> message) {
    final routes = _findAllRoutes(destination);
    if (routes.isEmpty) return [];

    // Calculate load for each route
    final routesWithLoad = routes.map((route) {
      final load = route.path.fold(0.0, (sum, nodeId) {
        return sum + (_messageCounts[nodeId] ?? 0);
      });
      return MapEntry(route, load);
    }).toList();

    // Sort by load (prefer less loaded routes)
    routesWithLoad.sort((a, b) => a.value.compareTo(b.value));

    final selectedRoute = routesWithLoad.first.key;
    _recordMessage(message, selectedRoute);
    
    return selectedRoute.path;
  }

  // Network healing
  void healNetwork() {
    final disconnectedNodes = <String>[];
    
    for (final entry in _adjacencyList.entries) {
      if (entry.value.isEmpty) {
        disconnectedNodes.add(entry.key);
      }
    }

    for (final nodeId in disconnectedNodes) {
      _attemptReconnection(nodeId);
    }

    _logger.info('Network healing completed. Attempted to reconnect ${disconnectedNodes.length} nodes', tag: 'MeshRouting');
  }

  void _attemptReconnection(String nodeId) {
    // In a real implementation, this would attempt to re-establish connections
    _logger.info('Attempting to reconnect node: $nodeId', tag: 'MeshRouting');
  }
}
