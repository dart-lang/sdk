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

  /// After execution of [_propagateAlways], a list of all nodes reachable from
  /// [always] via zero or more edges of kind [_NullabilityEdgeKind.union].
  final List<NullabilityNode> _unionedWithAlways = [];

  /// During any given stage of nullability propagation, a list of all the edges
  /// that need to be examined before the stage is complete.
  final List<NullabilityEdge> _pendingEdges = [];

  /// During and after nullability propagation, a list of all edges that
  /// couldn't be satisfied.
  final List<NullabilityEdge> _unsatisfiedEdges = [];

  /// During and after nullability propagation, a list of all substitution nodes
  /// that couldn't be satisfied.
  final List<NullabilityNodeForSubstitution> _unsatisfiedSubstitutions = [];

  /// During execution of [_propagateDownstream], a list of all the substitution
  /// nodes that have not yet been resolved.
  List<NullabilityNodeForSubstitution> _pendingSubstitutions = [];

  /// After calling [propagate], this getter may be queried to access the set of
  /// edges that could not be satisfied.
  Iterable<NullabilityEdge> get unsatisfiedEdges => _unsatisfiedEdges;

  /// After calling [propagate], this getter may be queried to access the set of
  /// substitution nodes that could not be satisfied.
  Iterable<NullabilityNodeForSubstitution> get unsatisfiedSubstitutions =>
      _unsatisfiedSubstitutions;

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
  void propagate() {
    if (_debugBeforePropagation) _debugDump();
    _propagateAlways();
    _propagateUpstream();
    _propagateDownstream();
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
  void _propagateAlways() {
    _unionedWithAlways.add(always);
    _pendingEdges.addAll(always._downstreamEdges);
    while (_pendingEdges.isNotEmpty) {
      var edge = _pendingEdges.removeLast();
      if (!edge.isUnion) continue;
      // Union edges always have exactly one source, so we don't need to check
      // whether all sources are nullable.
      assert(edge.sources.length == 1);
      var node = edge.destinationNode;
      if (node is NullabilityNodeMutable && !node.isNullable) {
        _unionedWithAlways.add(node);
        node._state = _NullabilityState.ordinaryNullable;
        // Was not previously nullable, so we need to propagate.
        _pendingEdges.addAll(node._downstreamEdges);
      }
    }
  }

  /// Propagates nullability downstream.
  void _propagateDownstream() {
    assert(_pendingEdges.isEmpty);
    for (var node in _unionedWithAlways) {
      _pendingEdges.addAll(node._downstreamEdges);
    }
    while (true) {
      while (_pendingEdges.isNotEmpty) {
        var edge = _pendingEdges.removeLast();
        if (!edge._isTriggered) continue;
        var node = edge.destinationNode;
        if (node._state == _NullabilityState.nonNullable) {
          // The node has already been marked as non-nullable, so the edge can't
          // be satisfied.
          _unsatisfiedEdges.add(edge);
          continue;
        }
        if (node is NullabilityNodeMutable && !node.isNullable) {
          _setNullable(node);
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
    assert(_pendingEdges.isEmpty);
    _pendingEdges.addAll(never._upstreamEdges);
    while (_pendingEdges.isNotEmpty) {
      var edge = _pendingEdges.removeLast();
      if (!edge.hard) continue;
      var node = edge.primarySource;
      if (node is NullabilityNodeMutable &&
          node._state == _NullabilityState.undetermined) {
        node._state = _NullabilityState.nonNullable;
        // Was not previously in the set of non-null intent nodes, so we need to
        // propagate.
        _pendingEdges.addAll(node._upstreamEdges);
      }
    }
  }

  void _resolvePendingSubstitution(
      NullabilityNodeForSubstitution substitutionNode) {
    assert(substitutionNode._state.isNullable);
    // If both nodes pointed to by the substitution node are in the non-nullable
    // state, then no resolution is needed; the substitution node can’t be
    // satisfied.
    if (substitutionNode.innerNode._state == _NullabilityState.nonNullable &&
        substitutionNode.outerNode._state == _NullabilityState.nonNullable) {
      _unsatisfiedSubstitutions.add(substitutionNode);
      return;
    }

    // Otherwise, if the outer node is in a nullable state, then no resolution
    // is needed because the substitution node is already satisfied.
    if (substitutionNode.outerNode.isNullable) {
      return;
    }

    // Otherwise, if the inner node is in the non-nullable state, then we set
    // the outer node to the ordinary nullable state.
    if (substitutionNode.innerNode._state == _NullabilityState.nonNullable) {
      _setNullable(substitutionNode.outerNode as NullabilityNodeMutable);
      return;
    }

    // Otherwise, we set the inner node to the exact nullable state, and we
    // propagate this state upstream as far as possible using the following
    // rule: if there is an edge A → B, where A is in the undetermined or
    // ordinary nullable state, and B is in the exact nullable state, then A’s
    // state is changed to exact nullable.
    var pendingNodes = [substitutionNode.innerNode];
    while (pendingNodes.isNotEmpty) {
      var node = pendingNodes.removeLast();
      if (node is NullabilityNodeMutable) {
        var oldState =
            _setNullable(node, newState: _NullabilityState.exactNullable);
        if (oldState != _NullabilityState.exactNullable) {
          // Was not previously in the "exact nullable" state.  Need to
          // propagate.
          for (var edge in node._upstreamEdges) {
            pendingNodes.add(edge.primarySource);
          }
        }
      }
    }
  }

  _NullabilityState _setNullable(NullabilityNodeMutable node,
      {_NullabilityState newState = _NullabilityState.ordinaryNullable}) {
    assert(newState.isNullable);
    var oldState = node._state;
    node._state = newState;
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

  NullabilityNode._();

  /// Gets a string that can be appended to a type name during debugging to help
  /// annotate the nullability of that type.
  String get debugSuffix => '?($this)';

  /// After nullability propagation, this getter can be used to query whether
  /// the type associated with this node should be considered "exact nullable".
  @visibleForTesting
  bool get isExactNullable;

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
  bool get isExactNullable => _state == _NullabilityState.exactNullable;

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

  @override
  String get debugSuffix => isNullable ? '?' : '';

  @override
  bool get isExactNullable => isNullable;

  @override
  _NullabilityState get _state => isNullable
      ? _NullabilityState.exactNullable
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
