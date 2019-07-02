// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';

import 'edge_origin.dart';

/// Data structure to keep track of the relationship from one [NullabilityNode]
/// object to another [NullabilityNode] that is "downstream" from it (meaning
/// that if the former node is nullable, then the latter node will either have
/// to be nullable, or null checks will have to be added).
class NullabilityEdge {
  /// The node that is downstream.
  final NullabilityNode destinationNode;

  /// A set of source nodes.  By convention, the first node is the primary
  /// source and the other nodes are "guards".  The destination node will only
  /// need to be made nullable if all the source nodes are nullable.
  final List<NullabilityNode> sources;

  final _NullabilityEdgeKind _kind;

  /// An [EdgeOrigin] object indicating what was found in the source code that
  /// caused the edge to be generated.
  final EdgeOrigin origin;

  NullabilityEdge._(
      this.destinationNode, this.sources, this._kind, this.origin);

  Iterable<NullabilityNode> get guards => sources.skip(1);

  bool get hard => _kind != _NullabilityEdgeKind.soft;

  /// Indicates whether nullability was successfully propagated through this
  /// edge.
  bool get isSatisfied {
    if (!_isTriggered) return true;
    return destinationNode.isNullable;
  }

  bool get isUnion => _kind == _NullabilityEdgeKind.union;

  NullabilityNode get primarySource => sources.first;

  /// Indicates whether all the sources of this edge are nullable (and thus
  /// downstream nullability propagation should try to make the destination node
  /// nullable, if possible).
  bool get _isTriggered {
    for (var source in sources) {
      if (!source.isNullable) return false;
    }
    return true;
  }

  @override
  String toString() {
    var edgeDecorations = <Object>[];
    switch (_kind) {
      case _NullabilityEdgeKind.soft:
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
    return '$primarySource $edgeDecoration-> $destinationNode';
  }
}

/// Data structure to keep track of the relationship between [NullabilityNode]
/// objects.
class NullabilityGraph {
  /// Set this const to `true` to dump the nullability graph just before
  /// propagation.
  static const _debugBeforePropagation = false;

  /// Set containing all [NullabilityNode]s that have been passed as the
  /// `sourceNode` argument to [connect].
  final _allSourceNodes = Set<NullabilityNode>.identity();

  /// Returns a [NullabilityNode] that is a priori nullable.
  ///
  /// Propagation of nullability always proceeds downstream starting at this
  /// node.
  final NullabilityNode always = _NullabilityNodeImmutable('always', true);

  /// Returns a [NullabilityNode] that is a priori non-nullable.
  ///
  /// Propagation of nullability always proceeds upstream starting at this
  /// node.
  final NullabilityNode never = _NullabilityNodeImmutable('never', false);

  /// Set containing all sources being migrated.
  final _sourcesBeingMigrated = <Source>{};

  /// Records that [sourceNode] is immediately upstream from [destinationNode].
  ///
  /// Returns the edge created by the connection.
  NullabilityEdge connect(NullabilityNode sourceNode,
      NullabilityNode destinationNode, EdgeOrigin origin,
      {bool hard: false, List<NullabilityNode> guards: const []}) {
    var sources = [sourceNode]..addAll(guards);
    var kind = hard ? _NullabilityEdgeKind.hard : _NullabilityEdgeKind.soft;
    return _connect(sources, destinationNode, kind, origin);
  }

  /// Determine if [source] is in the code being migrated.
  bool isBeingMigrated(Source source) {
    return _sourcesBeingMigrated.contains(source);
  }

  /// Record source as code that is being migrated.
  void migrating(Source source) {
    _sourcesBeingMigrated.add(source);
  }

  /// Determines the nullability of each node in the graph by propagating
  /// nullability information from one node to another.
  ///
  /// Returns a list of edges that couldn't be satisfied.
  List<NullabilityEdge> propagate() {
    if (_debugBeforePropagation) _debugDump();
    var nullableNodes = _propagateAlways();
    _propagateUpstream();
    return _propagateDownstream(nullableNodes);
  }

  /// Records that nodes [x] and [y] should have exactly the same nullability.
  void union(NullabilityNode x, NullabilityNode y, EdgeOrigin origin) {
    _connect([x], y, _NullabilityEdgeKind.union, origin);
    _connect([y], x, _NullabilityEdgeKind.union, origin);
  }

  NullabilityEdge _connect(
      List<NullabilityNode> sources,
      NullabilityNode destinationNode,
      _NullabilityEdgeKind kind,
      EdgeOrigin origin) {
    var edge = NullabilityEdge._(destinationNode, sources, kind, origin);
    for (var source in sources) {
      _connectDownstream(source, edge);
    }
    destinationNode._upstreamEdges.add(edge);
    return edge;
  }

  void _connectDownstream(NullabilityNode source, NullabilityEdge edge) {
    _allSourceNodes.add(source);
    source._downstreamEdges.add(edge);
    if (source is _NullabilityNodeCompound) {
      for (var component in source._components) {
        _connectDownstream(component, edge);
      }
    }
  }

  void _debugDump() {
    for (var source in _allSourceNodes) {
      var edges = source._downstreamEdges;
      var destinations =
          edges.where((edge) => edge.primarySource == source).map((edge) {
        var suffixes = <Object>[];
        if (edge.isUnion) {
          suffixes.add('union');
        } else if (edge.hard) {
          suffixes.add('hard');
        }
        suffixes.addAll(edge.guards);
        var suffix = suffixes.isNotEmpty ? ' (${suffixes.join(', ')})' : '';
        return '${edge.destinationNode}$suffix';
      });
      var state = source._state;
      print('$source ($state) -> ${destinations.join(', ')}');
    }
  }

  /// Propagates nullability downstream along union edges from "always".
  ///
  /// Returns a list of nodes that are nullable after this operation (including
  /// "always")
  List<NullabilityNode> _propagateAlways() {
    var nullableNodes = <NullabilityNode>[always];
    var pendingEdges = always._downstreamEdges.toList();
    while (pendingEdges.isNotEmpty) {
      var edge = pendingEdges.removeLast();
      if (!edge.isUnion) continue;
      // Union edges always have exactly one source, so we don't need to check
      // whether all sources are nullable.
      assert(edge.sources.length == 1);
      var node = edge.destinationNode;
      if (node is NullabilityNodeMutable && !node.isNullable) {
        nullableNodes.add(node);
        node._state = _NullabilityState.ordinaryNullable;
        // Was not previously nullable, so we need to propagate.
        pendingEdges.addAll(node._downstreamEdges);
      }
    }
    return nullableNodes;
  }

  /// Propagates nullability downstream.
  List<NullabilityEdge> _propagateDownstream(
      List<NullabilityNode> nullableNodes) {
    var unsatisfiedEdges = <NullabilityEdge>[];
    var pendingEdges = <NullabilityEdge>[];
    for (var node in nullableNodes) {
      pendingEdges.addAll(node._downstreamEdges);
    }
    var pendingSubstitutions = <NullabilityNodeForSubstitution>[];
    while (true) {
      while (pendingEdges.isNotEmpty) {
        var edge = pendingEdges.removeLast();
        if (!edge._isTriggered) continue;
        var node = edge.destinationNode;
        if (node._state == _NullabilityState.nonNullable) {
          // The node has already been marked as non-nullable, so the edge can't
          // be satisfied.
          unsatisfiedEdges.add(edge);
          continue;
        }
        if (node is NullabilityNodeMutable && !node.isNullable) {
          node._state = _NullabilityState.ordinaryNullable;
          // Was not previously nullable, so we need to propagate.
          pendingEdges.addAll(node._downstreamEdges);
          if (node is NullabilityNodeForSubstitution) {
            pendingSubstitutions.add(node);
          }
        }
      }
      if (pendingSubstitutions.isEmpty) break;
      var node = pendingSubstitutions.removeLast();
      if (node.innerNode.isNullable || node.outerNode.isNullable) {
        // No further propagation is needed, since some other connection already
        // propagated nullability to either the inner or outer node.
        continue;
      }
      // Heuristically choose to propagate to the inner node since this seems
      // to lead to better quality migrations.
      pendingEdges.add(NullabilityEdge._(node.innerNode, const [],
          _NullabilityEdgeKind.soft, _SubstitutionHeuristicOrigin()));
    }
    return unsatisfiedEdges;
  }

  /// Propagates non-null intent upstream along unconditional control flow
  /// lines.
  void _propagateUpstream() {
    var pendingEdges = never._upstreamEdges.toList();
    while (pendingEdges.isNotEmpty) {
      var edge = pendingEdges.removeLast();
      if (!edge.hard) continue;
      var node = edge.primarySource;
      if (node is NullabilityNodeMutable &&
          node._state == _NullabilityState.undetermined) {
        node._state = _NullabilityState.nonNullable;
        // Was not previously in the set of non-null intent nodes, so we need to
        // propagate.
        pendingEdges.addAll(node._upstreamEdges);
      }
    }
  }
}

/// Same as [NullabilityGraph], but extended with extra methods for easier
/// testing.
@visibleForTesting
class NullabilityGraphForTesting extends NullabilityGraph {
  /// Iterates through all edges that have this node as one of their sources.
  ///
  /// There is no guarantee of uniqueness of the iterated edges.
  @visibleForTesting
  Iterable<NullabilityEdge> getDownstreamEdges(NullabilityNode node) {
    return node._downstreamEdges;
  }

  /// Iterates through all edges that have this node as their destination.
  ///
  /// There is no guarantee of uniqueness of the iterated nodes.
  @visibleForTesting
  Iterable<NullabilityEdge> getUpstreamEdges(NullabilityNode node) {
    return node._upstreamEdges;
  }
}

/// Representation of a single node in the nullability inference graph.
///
/// Initially, this is just a wrapper over constraint variables, and the
/// nullability inference graph is encoded into the wrapped constraint
/// variables.  Over time this will be replaced by a first class representation
/// of the nullability inference graph.
abstract class NullabilityNode {
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

  /// Creates a [NullabilityNode] representing the nullability of a variable
  /// whose type is determined by the `??` operator.
  factory NullabilityNode.forIfNotNull() =>
      _NullabilityNodeSimple('?? operator');

  /// Creates a [NullabilityNode] representing the nullability of a variable
  /// whose type is determined by type inference.
  factory NullabilityNode.forInferredType() =>
      _NullabilityNodeSimple('inferred');

  /// Creates a [NullabilityNode] representing the nullability of an
  /// expression which is nullable iff either [a] or [b] is nullable.
  factory NullabilityNode.forLUB(NullabilityNode left, NullabilityNode right) =
      NullabilityNodeForLUB._;

  /// Creates a [NullabilityNode] representing the nullability of a type
  /// substitution where [outerNode] is the nullability node for the type
  /// variable being eliminated by the substitution, and [innerNode] is the
  /// nullability node for the type being substituted in its place.
  ///
  /// [innerNode] may be `null`.  TODO(paulberry): when?
  ///
  /// Additional constraints are recorded in [constraints] as necessary to make
  /// the new nullability node behave consistently with the old nodes.
  /// TODO(paulberry): this should become unnecessary once constraint solving is
  /// performed directly using [NullabilityNode] objects.
  factory NullabilityNode.forSubstitution(
          NullabilityNode innerNode, NullabilityNode outerNode) =
      NullabilityNodeForSubstitution._;

  /// Creates a [NullabilityNode] representing the nullability of a type
  /// annotation appearing explicitly in the user's program.
  factory NullabilityNode.forTypeAnnotation(int endOffset) =>
      _NullabilityNodeSimple('type($endOffset)');

  NullabilityNode._();

  /// Gets a string that can be appended to a type name during debugging to help
  /// annotate the nullability of that type.
  String get debugSuffix => '?($this)';

  /// After nullability propagation, this getter can be used to query whether
  /// the type associated with this node should be considered nullable.
  bool get isNullable;

  /// Indicates whether this node is associated with a named parameter for which
  /// nullability migration needs to decide whether it is optional or required.
  bool get isPossiblyOptional => _isPossiblyOptional;

  String get _debugPrefix;

  _NullabilityState get _state;

  /// Records the fact that an invocation was made to a function with named
  /// parameters, and the named parameter associated with this node was not
  /// supplied.
  void recordNamedParameterNotSupplied(List<NullabilityNode> guards,
      NullabilityGraph graph, NamedParameterNotSuppliedOrigin origin) {
    if (isPossiblyOptional) {
      graph.connect(graph.always, this, origin, guards: guards);
    }
  }

  String toString() {
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
    return _debugName;
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

  NullabilityNodeForLUB._(this.left, this.right);

  @override
  Iterable<NullabilityNode> get _components => [left, right];

  @override
  String get _debugPrefix => 'LUB($left, $right)';
}

/// Derived class for nullability nodes that arise from type variable
/// substitution.
class NullabilityNodeForSubstitution extends _NullabilityNodeCompound {
  /// Nullability node representing the inner type of the substitution.
  ///
  /// For example, if this NullabilityNode arose from substituting `int*` for
  /// `T` in the type `T*`, [innerNode] is the nullability corresponding to the
  /// `*` in `int*`.
  final NullabilityNode innerNode;

  /// Nullability node representing the outer type of the substitution.
  ///
  /// For example, if this NullabilityNode arose from substituting `int*` for
  /// `T` in the type `T*`, [innerNode] is the nullability corresponding to the
  /// `*` in `T*`.
  final NullabilityNode outerNode;

  NullabilityNodeForSubstitution._(this.innerNode, this.outerNode);

  @override
  Iterable<NullabilityNode> get _components => [innerNode, outerNode];

  @override
  String get _debugPrefix => 'Substituted($innerNode, $outerNode)';
}

/// Base class for nullability nodes whose state can be mutated safely.
///
/// Nearly all nullability nodes derive from this class; the only exceptions are
/// the fixed nodes "always "never".
abstract class NullabilityNodeMutable extends NullabilityNode {
  _NullabilityState _state;

  NullabilityNodeMutable._(
      {_NullabilityState initialState: _NullabilityState.undetermined})
      : _state = initialState,
        super._();

  @override
  bool get isNullable => _state.isNullable;
}

/// Kinds of nullability edges
enum _NullabilityEdgeKind {
  /// Soft edge.  Propagates nullability downstream only.
  soft,

  /// Hard edge.  Propagates nullability downstream and non-nullability
  /// upstream.
  hard,

  /// Union edge.  Indicates that two nodes should have exactly the same
  /// nullability.
  union,
}

abstract class _NullabilityNodeCompound extends NullabilityNodeMutable {
  _NullabilityNodeCompound() : super._();

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

  @override
  String get debugSuffix => isNullable ? '?' : '';

  @override
  _NullabilityState get _state => isNullable
      ? _NullabilityState.ordinaryNullable
      : _NullabilityState.nonNullable;
}

class _NullabilityNodeSimple extends NullabilityNodeMutable {
  @override
  final String _debugPrefix;

  _NullabilityNodeSimple(this._debugPrefix)
      : super._(initialState: _NullabilityState.undetermined);
}

/// State of a nullability node.
class _NullabilityState {
  /// State of a nullability node whose nullability hasn't been decided yet.
  static const undetermined = _NullabilityState._('undetermined', false);

  /// State of a nullability node that has been determined to be non-nullable
  /// by propagating upstream.
  static const nonNullable = _NullabilityState._('non-nullable', false);

  /// State of a nullability node that has been determined to be nullable by
  /// propagating downstream.
  static const ordinaryNullable =
      _NullabilityState._('ordinary nullable', true);

  /// State of a nullability node that has been determined to be nullable by
  /// propagating upstream from a contravariant use of a generic.
  static const exactNullable = _NullabilityState._('exact nullable', true);

  /// Name of the state (for use in debugging).
  final String name;

  /// Indicates whether the given state should be considered nullable.
  ///
  /// After propagation, any nodes that remain in the undetermined state are
  /// considered to be non-nullable, so this field is returns `false` for nodes
  /// in that state.
  final bool isNullable;

  const _NullabilityState._(this.name, this.isNullable);

  @override
  String toString() => name;
}

class _SubstitutionHeuristicOrigin extends EdgeOrigin {}
