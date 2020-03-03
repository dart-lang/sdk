// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nullability_state.dart';
import 'package:nnbd_migration/src/postmortem_file.dart';

import 'edge_origin.dart';

/// Abstract interface for assigning ids numbers to nodes.  This allows us to
/// annotate nodes with their ids when analyzing postmortem output.
abstract class NodeToIdMapper {
  /// Gets the id corresponding to the given [node].
  int idForNode(NullabilityNode node);
}

/// Data structure to keep track of the relationship from one [NullabilityNode]
/// object to another [NullabilityNode] that is "downstream" from it (meaning
/// that if the former node is nullable, then the latter node will either have
/// to be nullable, or null checks will have to be added).
class NullabilityEdge implements EdgeInfo {
  @override
  final NullabilityNode destinationNode;

  /// A set of upstream nodes.  By convention, the first node is the source node
  /// and the other nodes are "guards".  The destination node will only need to
  /// be made nullable if all the upstream nodes are nullable.
  final List<NullabilityNode> upstreamNodes;

  final _NullabilityEdgeKind _kind;

  NullabilityEdge.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : destinationNode = deserializer.nodeForId(json['dest'] as int),
        upstreamNodes = [],
        _kind = _deserializeKind(json['kind']) {
    deserializer.defer(() {
      for (var id in json['us'] as List<dynamic>) {
        upstreamNodes.add(deserializer.nodeForId(id as int));
      }
    });
  }

  NullabilityEdge._(this.destinationNode, this.upstreamNodes, this._kind);

  @override
  Iterable<NullabilityNode> get guards => upstreamNodes.skip(1);

  /// Indicates whether it's possible for migration to cope with this edge being
  /// unsatisfied by inserting a null check.  Graph propagation favors
  /// satisfying uncheckable edges over satisfying hard edges.
  bool get isCheckable =>
      _kind == _NullabilityEdgeKind.soft || _kind == _NullabilityEdgeKind.hard;

  @override
  bool get isHard =>
      _kind == _NullabilityEdgeKind.hard || _kind == _NullabilityEdgeKind.union;

  @override
  bool get isSatisfied {
    if (!isTriggered) return true;
    return destinationNode.isNullable;
  }

  @override
  bool get isTriggered {
    for (var upstreamNode in upstreamNodes) {
      if (!upstreamNode.isNullable) return false;
    }
    return true;
  }

  @override
  bool get isUnion => _kind == _NullabilityEdgeKind.union;

  @override
  bool get isUpstreamTriggered {
    if (!isHard) return false;
    return destinationNode.nonNullIntent.isPresent;
  }

  @override
  NullabilityNode get sourceNode => upstreamNodes.first;

  Map<String, Object> toJson(NullabilityGraphSerializer serializer) {
    var json = <String, Object>{};
    switch (_kind) {
      case _NullabilityEdgeKind.soft:
        break;
      case _NullabilityEdgeKind.uncheckable:
        json['kind'] = 'uncheckable';
        break;
      case _NullabilityEdgeKind.hard:
        json['kind'] = 'hard';
        break;
      case _NullabilityEdgeKind.union:
        json['kind'] = 'union';
        break;
    }
    serializer.defer(() {
      json['dest'] = serializer.idForNode(destinationNode);
      json['us'] = [for (var n in upstreamNodes) serializer.idForNode(n)];
    });
    return json;
  }

  @override
  String toString({NodeToIdMapper idMapper}) {
    var edgeDecorations = <Object>[];
    switch (_kind) {
      case _NullabilityEdgeKind.soft:
        break;
      case _NullabilityEdgeKind.uncheckable:
        edgeDecorations.add('uncheckable');
        break;
      case _NullabilityEdgeKind.hard:
        edgeDecorations.add('hard');
        break;
      case _NullabilityEdgeKind.union:
        edgeDecorations.add('union');
        break;
    }
    edgeDecorations.addAll(guards);
    var edgeDecoration =
        edgeDecorations.isEmpty ? '' : '-(${edgeDecorations.join(', ')})';
    return '${sourceNode.toString(idMapper: idMapper)} $edgeDecoration-> '
        '${destinationNode.toString(idMapper: idMapper)}';
  }

  static _NullabilityEdgeKind _deserializeKind(dynamic json) {
    if (json == null) return _NullabilityEdgeKind.soft;
    var kind = json as String;
    switch (kind) {
      case 'uncheckable':
        return _NullabilityEdgeKind.uncheckable;
      case 'hard':
        return _NullabilityEdgeKind.hard;
      case 'union':
        return _NullabilityEdgeKind.union;
      default:
        throw StateError('Unrecognized edge kind $kind');
    }
  }
}

/// Data structure to keep track of the relationship between [NullabilityNode]
/// objects.
class NullabilityGraph {
  /// Set this const to `true` to dump the nullability graph just before
  /// propagation.
  static const _debugBeforePropagation = false;

  /// Set this const to `true` to dump the nullability graph just before
  /// propagation.
  static const _debugAfterPropagation = false;

  final NullabilityMigrationInstrumentation /*?*/ instrumentation;

  /// Returns a [NullabilityNode] that is a priori nullable.
  ///
  /// Propagation of nullability always proceeds downstream starting at this
  /// node.
  final NullabilityNode always;

  /// Returns a [NullabilityNode] that is a priori non-nullable.
  ///
  /// Propagation of nullability always proceeds upstream starting at this
  /// node.
  final NullabilityNode never;

  /// Set containing all sources being migrated.
  final _sourcesBeingMigrated = <Source>{};

  /// A set containing all of the nodes in the graph.
  final Set<NullabilityNode> nodes = {};

  NullabilityGraph({this.instrumentation})
      : always = _NullabilityNodeImmutable('always', true),
        never = _NullabilityNodeImmutable('never', false);

  NullabilityGraph.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : instrumentation = null,
        always = deserializer.nodeForId(json['always'] as int),
        never = deserializer.nodeForId(json['never'] as int) {
    var serializedNodes = json['nodes'] as List<dynamic>;
    for (int id = 0; id < serializedNodes.length; id++) {
      nodes.add(deserializer.nodeForId(id));
    }
    deserializer.finish();
  }

  /// Records that [sourceNode] is immediately upstream from [destinationNode].
  ///
  /// Returns the edge created by the connection.
  NullabilityEdge connect(NullabilityNode sourceNode,
      NullabilityNode destinationNode, EdgeOrigin origin,
      {bool hard: false,
      bool checkable = true,
      List<NullabilityNode> guards: const []}) {
    var upstreamNodes = [sourceNode]..addAll(guards);
    var kind = hard
        ? _NullabilityEdgeKind.hard
        : checkable
            ? _NullabilityEdgeKind.soft
            : _NullabilityEdgeKind.uncheckable;
    return _connect(upstreamNodes, destinationNode, kind, origin);
  }

  /// Prints out a representation of the graph nodes.  Useful in debugging
  /// broken tests.
  void debugDump() {
    Set<NullabilityNode> visitedNodes = {};
    Map<NullabilityNode, String> shortNames = {};
    int counter = 0;
    String nameNode(NullabilityNode node) {
      if (node.isImmutable) {
        var name = 'n${counter++}';
        print('  $name [label="$node" shape=none]');
        return name;
      }
      var name = shortNames[node];
      if (name == null) {
        shortNames[node] = name = 'n${counter++}';
        String styleSuffix = node.isNullable ? ' style=filled' : '';
        String intentSuffix =
            node.nonNullIntent.isPresent ? ', non-null intent' : '';
        String label = '$node (${node._nullability}$intentSuffix)';
        print('  $name [label="$label"$styleSuffix]');
        if (node is _NullabilityNodeCompound) {
          for (var component in node._components) {
            print('  ${nameNode(component)} -> $name [style=dashed]');
          }
        }
      }
      return name;
    }

    void visitNode(NullabilityNode node) {
      if (!visitedNodes.add(node)) return;
      for (var edge in node._upstreamEdges) {
        String suffix;
        if (edge.isUnion) {
          suffix = ' [label="union"]';
        } else if (edge.isHard) {
          suffix = ' [label="hard"]';
        } else if (edge.isCheckable) {
          suffix = '';
        } else {
          suffix = ' [label="uncheckable"]';
        }
        var upstreamNodes = edge.upstreamNodes;
        if (upstreamNodes.length == 1) {
          print(
              '  ${nameNode(upstreamNodes.single)} -> ${nameNode(node)}$suffix');
        } else {
          var tmpName = 'n${counter++}';
          print('  $tmpName [label=""]');
          print('  $tmpName -> ${nameNode(node)}$suffix}');
          for (var upstreamNode in upstreamNodes) {
            print('  ${nameNode(upstreamNode)} -> $tmpName');
          }
        }
      }
    }

    print('digraph G {');
    print('  rankdir="LR"');
    visitNode(always);
    visitNode(never);
    for (var node in nodes) {
      visitNode(node);
    }
    print('}');
  }

  /// Determine if [source] is in the code being migrated.
  bool isBeingMigrated(Source source) {
    return _sourcesBeingMigrated.contains(source);
  }

  /// Creates a graph edge that will try to force the given [node] to be
  /// non-nullable.
  NullabilityEdge makeNonNullable(NullabilityNode node, EdgeOrigin origin,
      {bool hard: true, List<NullabilityNode> guards: const []}) {
    return connect(node, never, origin, hard: hard, guards: guards);
  }

  /// Creates union edges that will guarantee that the given [node] is
  /// non-nullable.
  void makeNonNullableUnion(NullabilityNode node, EdgeOrigin origin) {
    union(node, never, origin);
  }

  /// Creates a graph edge that will try to force the given [node] to be
  /// nullable.
  void makeNullable(NullabilityNode node, EdgeOrigin origin,
      {List<NullabilityNode> guards: const []}) {
    connect(always, node, origin, guards: guards);
  }

  /// Creates a `union` graph edge that will try to force the given [node] to be
  /// nullable.  This is a stronger signal than [makeNullable] (it overrides
  /// [makeNonNullable]).
  void makeNullableUnion(NullabilityNode node, EdgeOrigin origin) {
    union(always, node, origin);
  }

  /// Record source as code that is being migrated.
  void migrating(Source source) {
    _sourcesBeingMigrated.add(source);
  }

  /// Determines the nullability of each node in the graph by propagating
  /// nullability information from one node to another.
  PropagationResult propagate(PostmortemFileWriter postmortemFileWriter) {
    postmortemFileWriter?.downstreamPropagationSteps?.clear();
    if (_debugBeforePropagation) debugDump();
    var propagationState =
        _PropagationState(always, never, postmortemFileWriter).result;
    if (_debugAfterPropagation) debugDump();
    return propagationState;
  }

  Map<String, Object> toJson(NullabilityGraphSerializer serializer) {
    var json = <String, Object>{};
    json['always'] = serializer.idForNode(always);
    json['never'] = serializer.idForNode(never);
    serializer.finish();
    json['nodes'] = serializer.serializedNodes;
    json['edges'] = serializer.serializedEdges;
    return json;
  }

  /// Records that nodes [x] and [y] should have exactly the same nullability.
  void union(NullabilityNode x, NullabilityNode y, EdgeOrigin origin) {
    _connect([x], y, _NullabilityEdgeKind.union, origin);
    _connect([y], x, _NullabilityEdgeKind.union, origin);
  }

  /// Update the graph after an edge has been added or removed.
  void update(PostmortemFileWriter postmortemFileWriter) {
    //
    // Reset the state of the nodes.
    //
    // This is inefficient because we reset the state of some nodes more than
    // once, but not all nodes are reachable from both `never` and `always`, so
    // we need to traverse the graph from both directions.
    //
    for (var node in nodes) {
      node.resetState();
    }
    //
    // Reset the state of the listener.
    //
    instrumentation.prepareForUpdate();
    //
    // Re-run the propagation step.
    //
    propagate(postmortemFileWriter);
  }

  NullabilityEdge _connect(
      List<NullabilityNode> upstreamNodes,
      NullabilityNode destinationNode,
      _NullabilityEdgeKind kind,
      EdgeOrigin origin) {
    var edge = NullabilityEdge._(destinationNode, upstreamNodes, kind);
    instrumentation?.graphEdge(edge, origin);
    for (var upstreamNode in upstreamNodes) {
      _connectDownstream(upstreamNode, edge);
    }
    destinationNode._upstreamEdges.add(edge);
    nodes.addAll(upstreamNodes);
    nodes.add(destinationNode);
    return edge;
  }

  void _connectDownstream(NullabilityNode upstreamNode, NullabilityEdge edge) {
    upstreamNode._downstreamEdges.add(edge);
    if (upstreamNode is _NullabilityNodeCompound) {
      for (var component in upstreamNode._components) {
        _connectDownstream(component, edge);
      }
    }
  }
}

/// Helper object used to deserialize a nullability graph from a JSON
/// representation.
class NullabilityGraphDeserializer implements NodeToIdMapper {
  final List<dynamic> _serializedNodes;

  final List<dynamic> _serializedEdges;

  final Map<int, NullabilityNode> _idToNodeMap = {};

  final Map<int, NullabilityEdge> _idToEdgeMap = {};

  final List<void Function()> _deferred = [];

  final Map<NullabilityNode, int> _nodeToIdMap = {};

  NullabilityGraphDeserializer(this._serializedNodes, this._serializedEdges);

  /// Defers a deserialization action until later.  The nullability node
  /// `fromJson` constructors use this method to defer populating edge lists
  /// until all nodes have been deserialized.
  void defer(void Function() callback) {
    _deferred.add(callback);
  }

  /// Gets the edge having the given [id], deserializing it if it hasn't been
  /// deserialized already.
  NullabilityEdge edgeForId(int id) {
    var edge = _idToEdgeMap[id];
    if (edge == null) {
      _idToEdgeMap[id] =
          edge = NullabilityEdge.fromJson(_serializedEdges[id], this);
    }
    return edge;
  }

  /// Runs all deferred actions that have been passed to [defer].
  void finish() {
    while (_deferred.isNotEmpty) {
      var callback = _deferred.removeLast();
      callback();
    }
  }

  @override
  int idForNode(NullabilityNode node) => _nodeToIdMap[node];

  /// Gets the node having the given [id], deserializing it if it hasn't been
  /// deserialized already.
  NullabilityNode nodeForId(int id) {
    var node = _idToNodeMap[id];
    if (node == null) {
      _idToNodeMap[id] = node = _deserializeNode(id);
      _nodeToIdMap[node] = id;
    }
    return node;
  }

  NullabilityNode _deserializeNode(int id) {
    var json = _serializedNodes[id];
    var kind = json['kind'] as String;
    switch (kind) {
      case 'immutable':
        return _NullabilityNodeImmutable.fromJson(json, this);
      case 'simple':
        return _NullabilityNodeSimple.fromJson(json, this);
      case 'lub':
        return NullabilityNodeForLUB.fromJson(json, this);
      case 'substitution':
        return NullabilityNodeForSubstitution.fromJson(json, this);
      default:
        throw StateError('Unrecognized node kind $kind');
    }
  }
}

/// Same as [NullabilityGraph], but extended with extra methods for easier
/// testing.
@visibleForTesting
class NullabilityGraphForTesting extends NullabilityGraph {
  final List<NullabilityEdge> _allEdges = [];

  final Map<NullabilityEdge, EdgeOrigin> _edgeOrigins = {};

  /// Iterates through all edges in the graph.
  @visibleForTesting
  Iterable<NullabilityEdge> getAllEdges() {
    return _allEdges;
  }

  /// Retrieves the [EdgeOrigin] object that was used to create [edge].
  @visibleForTesting
  EdgeOrigin getEdgeOrigin(NullabilityEdge edge) => _edgeOrigins[edge];

  @override
  NullabilityEdge _connect(
      List<NullabilityNode> upstreamNodes,
      NullabilityNode destinationNode,
      _NullabilityEdgeKind kind,
      EdgeOrigin origin) {
    var edge = super._connect(upstreamNodes, destinationNode, kind, origin);
    _allEdges.add(edge);
    _edgeOrigins[edge] = origin;
    return edge;
  }
}

/// Helper object used to serialize a nullability graph into a JSON
/// representation.
class NullabilityGraphSerializer {
  /// The list of serialized node objects to be stored in the output JSON.
  final List<Map<String, Object>> serializedNodes = [];

  final Map<NullabilityNode, int> _nodeToIdMap = {};

  /// The list of serialized edge objects to be stored in the output JSON.
  final List<Map<String, Object>> serializedEdges = [];

  final Map<NullabilityEdge, int> _edgeToIdMap = {};

  final List<void Function()> _deferred = [];

  bool _serializingNodeOrEdge = false;

  /// Defers a serialization action until later.  The nullability node
  /// `toJson` methods use this method to defer serializing edge lists
  /// until all nodes have been serialized.
  void defer(void Function() callback) {
    _deferred.add(callback);
  }

  /// Runs all deferred actions that have been passed to [defer].
  void finish() {
    while (_deferred.isNotEmpty) {
      var callback = _deferred.removeLast();
      callback();
    }
  }

  /// Gets the id for the given [edge], serializing it if it hasn't been
  /// serialized already.
  int idForEdge(NullabilityEdge edge) {
    var result = _edgeToIdMap[edge];
    if (result == null) {
      if (_serializingNodeOrEdge) {
        throw StateError('Illegal nesting of idForEdge');
      }
      _serializingNodeOrEdge = true;
      assert(_edgeToIdMap.length == serializedEdges.length);
      result = _edgeToIdMap[edge] = _edgeToIdMap.length;
      serializedEdges.add(edge.toJson(this));
      _serializingNodeOrEdge = false;
    }
    return result;
  }

  /// Gets the id for the given [node], serializing it if it hasn't been
  /// serialized already.
  int idForNode(NullabilityNode node) {
    var result = _nodeToIdMap[node];
    if (result == null) {
      if (_serializingNodeOrEdge) {
        throw StateError('Illegal nesting of idForEdge');
      }
      _serializingNodeOrEdge = true;
      assert(_nodeToIdMap.length == serializedNodes.length);
      result = _nodeToIdMap[node] = _nodeToIdMap.length;
      serializedNodes.add(node.toJson(this));
      _serializingNodeOrEdge = false;
    }
    return result;
  }
}

/// Representation of a single node in the nullability inference graph.
///
/// Initially, this is just a wrapper over constraint variables, and the
/// nullability inference graph is encoded into the wrapped constraint
/// variables.  Over time this will be replaced by a first class representation
/// of the nullability inference graph.
abstract class NullabilityNode implements NullabilityNodeInfo {
  static final _debugNamesInUse = Set<String>();

  bool _isPossiblyOptional = false;

  String _debugName;

  /// List of [NullabilityEdge] objects describing this node's relationship to
  /// other nodes that are "downstream" from it (meaning that if a key node is
  /// nullable, then all the nodes in the corresponding value will either have
  /// to be nullable, or null checks will have to be added).
  final _downstreamEdges = <NullabilityEdge>[];

  /// List of edges that have this node as their destination.
  final _upstreamEdges = <NullabilityEdge>[];

  /// List of compound nodes wrapping this node.
  final List<_NullabilityNodeCompound> outerCompoundNodes =
      <_NullabilityNodeCompound>[];

  /// Creates a [NullabilityNode] representing the nullability of a variable
  /// whose type comes from an already-migrated library.
  factory NullabilityNode.forAlreadyMigrated() =>
      _NullabilityNodeSimple('migrated');

  /// Creates a [NullabilityNode] representing the nullability of an expression
  /// which is nullable iff two other nullability nodes are both nullable.
  ///
  /// The caller is required to create the appropriate graph edges to ensure
  /// that the appropriate relationship between the nodes' nullabilities holds.
  factory NullabilityNode.forGLB() => _NullabilityNodeSimple('GLB');

  /// Creates a [NullabilityNode] representing the nullability of a variable
  /// whose type is determined by the `??` operator.
  factory NullabilityNode.forIfNotNull() =>
      _NullabilityNodeSimple('?? operator');

  /// Creates a [NullabilityNode] representing the nullability of a variable
  /// whose type is determined by type inference.
  factory NullabilityNode.forInferredType({int offset}) =>
      _NullabilityNodeSimple('inferred${offset == null ? '' : '($offset)'}');

  /// Creates a [NullabilityNode] representing the nullability of an
  /// expression which is nullable iff either [a] or [b] is nullable.
  factory NullabilityNode.forLUB(NullabilityNode left, NullabilityNode right) =
      NullabilityNodeForLUB._;

  /// Creates a [NullabilityNode] representing the nullability of a type
  /// substitution where [outerNode] is the nullability node for the type
  /// variable being eliminated by the substitution, and [innerNode] is the
  /// nullability node for the type being substituted in its place.
  ///
  /// If either [innerNode] or [outerNode] is `null`, then the other node is
  /// returned.
  factory NullabilityNode.forSubstitution(
      NullabilityNode innerNode, NullabilityNode outerNode) {
    if (innerNode == null) return outerNode;
    if (outerNode == null) return innerNode;
    return NullabilityNodeForSubstitution._(innerNode, outerNode);
  }

  /// Creates a [NullabilityNode] representing the nullability of a type
  /// annotation appearing explicitly in the user's program.
  factory NullabilityNode.forTypeAnnotation(int endOffset) =>
      _NullabilityNodeSimple('type($endOffset)');

  NullabilityNode.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer) {
    deserializer.defer(() {
      if (json['isPossiblyOptional'] == true) {
        _isPossiblyOptional = true;
      }
      for (var id in json['ds'] ?? []) {
        _downstreamEdges.add(deserializer.edgeForId(id as int));
      }
      for (var id in json['us'] ?? []) {
        _upstreamEdges.add(deserializer.edgeForId(id as int));
      }
      for (var id in json['outerCompoundNodes'] ?? []) {
        outerCompoundNodes
            .add(deserializer.nodeForId(id as int) as _NullabilityNodeCompound);
      }
    });
  }

  NullabilityNode._();

  /// Gets a string that can be appended to a type name during debugging to help
  /// annotate the nullability of that type.
  String get debugSuffix => '?($this)';

  Iterable<EdgeInfo> get downstreamEdges => _downstreamEdges;

  /// After nullability propagation, this getter can be used to query whether
  /// the type associated with this node should be considered "exact nullable".
  @visibleForTesting
  bool get isExactNullable;

  /// After nullability propagation, this getter can be used to query whether
  /// the type associated with this node should be considered nullable.
  @override
  bool get isNullable;

  /// Indicates whether this node is associated with a named parameter for which
  /// nullability migration needs to decide whether it is optional or required.
  bool get isPossiblyOptional => _isPossiblyOptional;

  /// After nullability propagation, this getter can be used to query the node's
  /// non-null intent state.
  NonNullIntent get nonNullIntent;

  @override
  Iterable<EdgeInfo> get upstreamEdges => _upstreamEdges;

  String get _debugPrefix;

  String get _jsonKind;

  Nullability get _nullability;

  /// Records the fact that an invocation was made to a function with named
  /// parameters, and the named parameter associated with this node was not
  /// supplied.
  void recordNamedParameterNotSupplied(List<NullabilityNode> guards,
      NullabilityGraph graph, NamedParameterNotSuppliedOrigin origin) {
    if (isPossiblyOptional) {
      graph.connect(graph.always, this, origin, guards: guards);
    }
  }

  /// Reset the state of this node to what it was before the graph was solved.
  void resetState();

  Map<String, Object> toJson(NullabilityGraphSerializer serializer) {
    var json = <String, Object>{};
    json['kind'] = _jsonKind;
    if (_isPossiblyOptional) {
      json['isPossiblyOptional'] = true;
    }
    serializer.defer(() {
      if (_downstreamEdges.isNotEmpty) {
        json['ds'] = [for (var e in _downstreamEdges) serializer.idForEdge(e)];
      }
      if (_upstreamEdges.isNotEmpty) {
        json['us'] = [for (var e in _upstreamEdges) serializer.idForEdge(e)];
      }
      if (outerCompoundNodes.isNotEmpty) {
        json['outerCompoundNodes'] = [
          for (var e in outerCompoundNodes) serializer.idForNode(e)
        ];
      }
    });
    return json;
  }

  String toString({NodeToIdMapper idMapper}) {
    if (_debugName == null) {
      var prefix = _debugPrefix;
      if (_debugNamesInUse.add(prefix)) {
        _debugName = prefix;
      } else {
        for (int i = 0;; i++) {
          var name = '${prefix}_$i';
          if (_debugNamesInUse.add(name)) {
            _debugName = name;
            break;
          }
        }
      }
    }
    if (idMapper == null) {
      return _debugName;
    } else {
      return '${idMapper.idForNode(this)}: $_debugName';
    }
  }

  /// Tracks the possibility that this node is associated with a named parameter
  /// for which nullability migration needs to decide whether it is optional or
  /// required.
  void trackPossiblyOptional() {
    _isPossiblyOptional = true;
  }

  @visibleForTesting
  static void clearDebugNames() {
    _debugNamesInUse.clear();
  }
}

/// Derived class for nullability nodes that arise from the least-upper-bound
/// implied by a conditional expression.
class NullabilityNodeForLUB extends _NullabilityNodeCompound {
  final NullabilityNode left;

  final NullabilityNode right;

  NullabilityNodeForLUB.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : left = deserializer.nodeForId(json['left'] as int),
        right = deserializer.nodeForId(json['right'] as int),
        super.fromJson(json, deserializer);

  NullabilityNodeForLUB._(this.left, this.right) {
    left.outerCompoundNodes.add(this);
    right.outerCompoundNodes.add(this);
  }

  @override
  Iterable<NullabilityNode> get _components => [left, right];

  @override
  String get _debugPrefix => 'LUB($left, $right)';

  @override
  String get _jsonKind => 'lub';

  @override
  void resetState() {
    left.resetState();
    right.resetState();
  }

  @override
  Map<String, Object> toJson(NullabilityGraphSerializer serializer) {
    var json = super.toJson(serializer);
    serializer.defer(() {
      json['left'] = serializer.idForNode(left);
      json['right'] = serializer.idForNode(right);
    });
    return json;
  }
}

/// Derived class for nullability nodes that arise from type variable
/// substitution.
class NullabilityNodeForSubstitution extends _NullabilityNodeCompound
    implements SubstitutionNodeInfo {
  @override
  final NullabilityNode innerNode;

  @override
  final NullabilityNode outerNode;

  NullabilityNodeForSubstitution.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : innerNode = deserializer.nodeForId(json['inner'] as int),
        outerNode = deserializer.nodeForId(json['outer'] as int),
        super.fromJson(json, deserializer);

  NullabilityNodeForSubstitution._(this.innerNode, this.outerNode) {
    innerNode.outerCompoundNodes.add(this);
    outerNode.outerCompoundNodes.add(this);
  }

  @override
  Iterable<NullabilityNode> get _components => [innerNode, outerNode];

  @override
  String get _debugPrefix => 'Substituted($innerNode, $outerNode)';

  @override
  String get _jsonKind => 'substitution';

  @override
  void resetState() {
    innerNode.resetState();
    outerNode.resetState();
  }

  @override
  Map<String, Object> toJson(NullabilityGraphSerializer serializer) {
    var json = super.toJson(serializer);
    serializer.defer(() {
      json['inner'] = serializer.idForNode(innerNode);
      json['outer'] = serializer.idForNode(outerNode);
    });
    return json;
  }
}

/// Base class for nullability nodes whose state can be mutated safely.
///
/// Nearly all nullability nodes derive from this class; the only exceptions are
/// the fixed nodes "always "never".
abstract class NullabilityNodeMutable extends NullabilityNode {
  Nullability _nullability;

  NonNullIntent _nonNullIntent;

  NullabilityNodeMutable.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : _nullability = json['nullability'] == null
            ? Nullability.nonNullable
            : Nullability.fromJson(json['nullability']),
        _nonNullIntent = json['nonNullIntent'] == null
            ? NonNullIntent.none
            : NonNullIntent.fromJson(json['nonNullIntent']),
        super.fromJson(json, deserializer);

  NullabilityNodeMutable._(
      {Nullability initialNullability = Nullability.nonNullable})
      : _nullability = initialNullability,
        _nonNullIntent = NonNullIntent.none,
        super._();

  @override
  bool get isExactNullable => _nullability.isExactNullable;

  @override
  bool get isImmutable => false;

  @override
  bool get isNullable => _nullability.isNullable;

  @override
  NonNullIntent get nonNullIntent => _nonNullIntent;

  @override
  void resetState() {
    _nullability = Nullability.nonNullable;
    _nonNullIntent = NonNullIntent.none;
  }

  @override
  Map<String, Object> toJson(NullabilityGraphSerializer serializer) {
    var json = super.toJson(serializer);
    if (_nullability != Nullability.nonNullable) {
      json['nullability'] = _nullability.toJson();
    }
    if (_nonNullIntent != NonNullIntent.none) {
      json['intent'] = _nonNullIntent.toJson();
    }
    return json;
  }
}

/// Information produced by [NullabilityGraph.propagate] about the results of
/// graph propagation.
class PropagationResult {
  /// A list of all edges that couldn't be satisfied.
  final List<NullabilityEdge> unsatisfiedEdges = [];

  /// A list of all substitution nodes that couldn't be satisfied.
  final List<NullabilityNodeForSubstitution> unsatisfiedSubstitutions = [];

  PropagationResult._();
}

/// Kinds of nullability edges
enum _NullabilityEdgeKind {
  /// Soft edge.  Propagates nullability downstream only.  May be overridden by
  /// suggestions that the user intends non-nullability.
  soft,

  /// Uncheckable edge.  Propagates nullability downstream only.  May not be
  /// overridden by suggestions that the user intends non-nullability.
  uncheckable,

  /// Hard edge.  Propagates nullability downstream and non-nullability
  /// upstream.
  hard,

  /// Union edge.  Indicates that two nodes should have exactly the same
  /// nullability.
  union,
}

abstract class _NullabilityNodeCompound extends NullabilityNodeMutable {
  _NullabilityNodeCompound() : super._();

  _NullabilityNodeCompound.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : super.fromJson(json, deserializer);

  @override
  bool get isExactNullable => _components.any((c) => c.isExactNullable);

  @override
  bool get isNullable => _components.any((c) => c.isNullable);

  Iterable<NullabilityNode> get _components;
}

class _NullabilityNodeImmutable extends NullabilityNode {
  @override
  final String _debugPrefix;

  @override
  final bool isNullable;

  _NullabilityNodeImmutable(this._debugPrefix, this.isNullable) : super._();

  _NullabilityNodeImmutable.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : _debugPrefix = json['debugPrefix'] as String,
        isNullable = json['isNullable'] as bool,
        super.fromJson(json, deserializer);

  @override
  String get debugSuffix => isNullable ? '?' : '';

  @override
  // Note: the node "always" is not exact nullable, because exact nullability is
  // a concept for contravariant generics which propagates upstream instead of
  // downstream. "always" is not a contravariant generic, and does not have any
  // upstream nodes, so it should not be considered *exact* nullable.
  bool get isExactNullable => false;

  @override
  bool get isImmutable => true;

  @override
  NonNullIntent get nonNullIntent =>
      isNullable ? NonNullIntent.none : NonNullIntent.direct;

  @override
  String get _jsonKind => 'immutable';

  @override
  Nullability get _nullability =>
      isNullable ? Nullability.ordinaryNullable : Nullability.nonNullable;

  @override
  void resetState() {
    // There is no state to reset.
  }

  @override
  Map<String, Object> toJson(NullabilityGraphSerializer serializer) {
    var json = super.toJson(serializer);
    json['debugPrefix'] = _debugPrefix;
    json['isNullable'] = isNullable;
    return json;
  }
}

class _NullabilityNodeSimple extends NullabilityNodeMutable {
  @override
  final String _debugPrefix;

  _NullabilityNodeSimple(this._debugPrefix) : super._();

  _NullabilityNodeSimple.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : _debugPrefix = json['debugPrefix'] as String,
        super.fromJson(json, deserializer);

  @override
  String get _jsonKind => 'simple';

  @override
  Map<String, Object> toJson(NullabilityGraphSerializer serializer) {
    var json = super.toJson(serializer);
    json['debugPrefix'] = _debugPrefix;
    return json;
  }
}

/// Workspace for performing graph propagation.
///
/// Graph propagation is performed immediately upon construction, so as soon as
/// the caller has constructed this object, the graph has been propagated and
/// the results of propagation can be retrieved from [result].
class _PropagationState {
  /// The result of propagation, for sharing with the client.
  final PropagationResult result = PropagationResult._();

  /// The graph's one and only "always" node.
  final NullabilityNode _always;

  /// The graph's one and only "never" node.
  final NullabilityNode _never;

  /// During any given stage of nullability propagation, a list of all the edges
  /// that need to be examined before the stage is complete.
  final List<NullabilityEdge> _pendingEdges = [];

  final PostmortemFileWriter _postmortemFileWriter;

  /// During execution of [_propagateDownstream], a list of all the substitution
  /// nodes that have not yet been resolved.
  List<NullabilityNodeForSubstitution> _pendingSubstitutions = [];

  _PropagationState(this._always, this._never, this._postmortemFileWriter) {
    _propagateUpstream();
    _propagateDownstream();
  }

  /// Propagates nullability downstream.
  void _propagateDownstream() {
    assert(_pendingEdges.isEmpty);
    _pendingEdges.addAll(_always._downstreamEdges);
    while (true) {
      while (_pendingEdges.isNotEmpty) {
        var edge = _pendingEdges.removeLast();
        if (!edge.isTriggered) continue;
        var node = edge.destinationNode;
        var nonNullIntent = node.nonNullIntent;
        if (nonNullIntent.isPresent) {
          if (edge.isCheckable) {
            // The node has already been marked as having non-null intent, and
            // the edge can be addressed by adding a null check, so we prefer to
            // leave the edge unsatisfied and let the null check happen.
            result.unsatisfiedEdges.add(edge);
            continue;
          }
          if (nonNullIntent.isDirect) {
            // The node has direct non-null intent so we aren't in a position to
            // mark it as nullable.
            result.unsatisfiedEdges.add(edge);
            continue;
          }
        }
        if (node is NullabilityNodeMutable && !node.isNullable) {
          _setNullable(node, Nullability.ordinaryNullable, causeEdge: edge);
        }
      }
      if (_pendingSubstitutions.isEmpty) break;
      var oldPendingSubstitutions = _pendingSubstitutions;
      _pendingSubstitutions = [];
      for (var node in oldPendingSubstitutions) {
        _resolvePendingSubstitution(node);
      }
    }
  }

  /// Propagates non-null intent upstream along unconditional control flow
  /// lines.
  void _propagateUpstream() {
    var pendingNodes = <NullabilityNode>[_never];
    while (pendingNodes.isNotEmpty) {
      var pendingNode = pendingNodes.removeLast();
      for (var edge in pendingNode._upstreamEdges) {
        // We only propagate for nodes that are "upstream triggered".  At this
        // point of propagation, a node is upstream triggered if it is hard.
        assert(edge.isUpstreamTriggered == edge.isHard);
        if (!edge.isHard) continue;
        var node = edge.sourceNode;
        if (node is NullabilityNodeMutable) {
          var oldNonNullIntent = node._nonNullIntent;
          if (edge.isUnion && edge.destinationNode == _never) {
            // If a node is unioned with "never" then it's considered to have
            // direct non-null intent.
            _setNonNullIntent(node, NonNullIntent.direct, causeEdge: edge);
          } else {
            _setNonNullIntent(node, oldNonNullIntent.addIndirect(),
                causeEdge: edge);
          }
          if (!oldNonNullIntent.isPresent) {
            // We did not previously have non-null intent, so we need to
            // propagate.
            pendingNodes.add(node);
          }
        }
      }
      // If any compound node is forced to be non-nullable by this change,
      // propagate to it.
      for (var node in pendingNode.outerCompoundNodes) {
        if (node._components
            .any((component) => !component.nonNullIntent.isPresent)) {
          continue;
        }
        var oldNonNullIntent = node._nonNullIntent;
        _setNonNullIntent(node, oldNonNullIntent.addIndirect(),
            causeNode: pendingNode);
        if (!oldNonNullIntent.isPresent) {
          // We did not previously have non-null intent, so we need to
          // propagate.
          pendingNodes.add(node);
        }
      }
    }
  }

  void _resolvePendingSubstitution(
      NullabilityNodeForSubstitution substitutionNode) {
    assert(substitutionNode._nullability.isNullable);
    // If both nodes pointed to by the substitution node have non-null intent,
    // then no resolution is needed; the substitution node can’t be satisfied.
    if (substitutionNode.innerNode.nonNullIntent.isPresent &&
        substitutionNode.outerNode.nonNullIntent.isPresent) {
      result.unsatisfiedSubstitutions.add(substitutionNode);
      return;
    }

    // Otherwise, if the outer node is in a nullable state, then no resolution
    // is needed because the substitution node is already satisfied.
    if (substitutionNode.outerNode.isNullable) {
      return;
    }

    // Otherwise, if the inner node has non-null intent, then we set the outer
    // node to the ordinary nullable state.
    if (substitutionNode.innerNode.nonNullIntent.isPresent) {
      _setNullable(substitutionNode.outerNode as NullabilityNodeMutable,
          Nullability.ordinaryNullable,
          causeNode: substitutionNode);
      return;
    }

    // Otherwise, we set the inner node to the exact nullable state, and we
    // propagate this state upstream as far as possible using the following
    // rule: if there is an edge A → B, where A is in the undetermined or
    // ordinary nullable state, and B is in the exact nullable state, then A’s
    // state is changed to exact nullable.
    var pendingEdges = <NullabilityEdge>[];
    var node = substitutionNode.innerNode;
    if (node is NullabilityNodeMutable) {
      var oldNullability = _setNullable(node, Nullability.exactNullable,
          causeNode: substitutionNode);
      if (!oldNullability.isExactNullable) {
        // Was not previously in the "exact nullable" state.  Need to
        // propagate.
        for (var edge in node._upstreamEdges) {
          pendingEdges.add(edge);
        }

        // TODO(mfairhurst): should this propagate back up outerContainerNodes?
      }
    }

    while (pendingEdges.isNotEmpty) {
      var edge = pendingEdges.removeLast();
      var node = edge.sourceNode;
      if (node is NullabilityNodeMutable && !edge.isCheckable) {
        var oldNullability =
            _setNullable(node, Nullability.exactNullable, causeEdge: edge);
        if (!oldNullability.isExactNullable) {
          // Was not previously in the "exact nullable" state.  Need to
          // propagate.
          for (var edge in node._upstreamEdges) {
            pendingEdges.add(edge);
          }
        }
      }
    }
  }

  void _setNonNullIntent(
      NullabilityNodeMutable node, NonNullIntent newNonNullIntent,
      {NullabilityNode causeNode, NullabilityEdge causeEdge}) {
    node._nonNullIntent = newNonNullIntent;
    _postmortemFileWriter?.upstreamPropagationSteps?.add(
        UpstreamPropagationStep(node, newNonNullIntent,
            causeNode: causeNode, causeEdge: causeEdge));
  }

  Nullability _setNullable(NullabilityNodeMutable node, Nullability newState,
      {NullabilityNode causeNode, NullabilityEdge causeEdge}) {
    var oldState = node._nullability;
    node._nullability = newState;
    _postmortemFileWriter?.downstreamPropagationSteps?.add(
        DownstreamPropagationStep(node, newState,
            causeNode: causeNode, causeEdge: causeEdge));
    if (!oldState.isNullable) {
      // Was not previously nullable, so we need to propagate.
      _pendingEdges.addAll(node._downstreamEdges);
      if (node is NullabilityNodeForSubstitution) {
        _pendingSubstitutions.add(node);
      }
    }
    return oldState;
  }
}
