// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/nullability_node.dart';
import 'package:meta/meta.dart';

/// Data structure to keep track of the relationship between [NullabilityNode]
/// objects.
class NullabilityGraph {
  /// Map from a nullability node to a list of [_NullabilityEdge] objects
  /// describing the node's relationship to other nodes that are "downstream"
  /// from it (meaning that if a key node is nullable, then all the nodes in the
  /// corresponding value will either have to be nullable, or null checks will
  /// have to be added).
  final _downstream = Map<NullabilityNode, List<_NullabilityEdge>>.identity();

  /// Map from a nullability node to those nodes that are "upstream" from it
  /// via unconditional control flow (meaning that if a node in the value is
  /// nullable, then there exists code that is unguarded by an "if" statement
  /// that indicates that the corresponding key node will have to be nullable,
  /// or null checks will have to be added).
  final _unconditionalUpstream =
      Map<NullabilityNode, List<NullabilityNode>>.identity();

  final _nonNullIntentNodes = Set<NullabilityNode>.identity();

  /// Records that [sourceNode] is immediately upstream from [destinationNode].
  void connect(NullabilityNode sourceNode, NullabilityNode destinationNode,
      {bool unconditional: false, List<NullabilityNode> guards: const []}) {
    var sources = [sourceNode]..addAll(guards);
    var edge = _NullabilityEdge(destinationNode, sources);
    for (var source in sources) {
      (_downstream[source] ??= []).add(edge);
    }
    if (unconditional) {
      (_unconditionalUpstream[destinationNode] ??= []).add(sourceNode);
    }
  }

  void debugDump() {
    for (var entry in _downstream.entries) {
      var destinations = entry.value
          .where((edge) => edge.primarySource == entry.key)
          .map((edge) {
        var suffixes = <Object>[];
        if (getUnconditionalUpstreamNodes(edge.destinationNode)
            .contains(entry.key)) {
          suffixes.add('unconditional');
        }
        suffixes.addAll(edge.guards);
        var suffix = suffixes.isNotEmpty ? ' (${suffixes.join(', ')})' : '';
        return '${edge.destinationNode}$suffix';
      });
      var suffixes = <String>[];
      if (entry.key.isNullable) {
        suffixes.add('nullable');
      }
      if (_nonNullIntentNodes.contains(entry.key)) {
        suffixes.add('non-null intent');
      }
      var suffix = suffixes.isNotEmpty ? ' (${suffixes.join(', ')})' : '';
      print('${entry.key}$suffix -> ${destinations.join(', ')}');
    }
  }

  /// Iterates through all nodes that are "downstream" of [node] (i.e. if
  /// [node] is nullable, then all the iterated nodes will either have to be
  /// nullable, or null checks will have to be added).
  ///
  /// There is no guarantee of uniqueness of the iterated nodes.
  Iterable<NullabilityNode> getDownstreamNodes(NullabilityNode node) =>
      (_downstream[node] ?? const [])
          .where((edge) => edge.primarySource == node)
          .map((edge) => edge.destinationNode);

  /// Iterates through all nodes that are "upstream" of [node] due to
  /// unconditional control flow.
  ///
  /// There is no guarantee of uniqueness of the iterated nodes.
  Iterable<NullabilityNode> getUnconditionalUpstreamNodes(
          NullabilityNode node) =>
      _unconditionalUpstream[node] ?? const [];

  /// Iterates through all nodes that are "upstream" of [node] (i.e. if
  /// any of the iterated nodes are nullable, then [node] will either have to be
  /// nullable, or null checks will have to be added).
  ///
  /// There is no guarantee of uniqueness of the iterated nodes.
  ///
  /// This method is inefficent since it has to search the entire graph, so it
  /// is for testing only.
  @visibleForTesting
  Iterable<NullabilityNode> getUpstreamNodesForTesting(
      NullabilityNode node) sync* {
    for (var entry in _downstream.entries) {
      for (var edge in entry.value) {
        if (edge.destinationNode == node) {
          yield entry.key;
        }
      }
    }
  }

  /// Determines the nullability of each node in the graph by propagating
  /// nullability information from one node to another.
  void propagate() {
    _propagateUpstream();
    _propagateDownstream();
  }

  /// Propagates nullability downstream.
  void _propagateDownstream() {
    var pendingEdges = <_NullabilityEdge>[]
      ..addAll(_downstream[NullabilityNode.always] ?? const []);
    var pendingSubstitutions = <NullabilityNodeForSubstitution>[];
    while (true) {
      nextEdge:
      while (pendingEdges.isNotEmpty) {
        var edge = pendingEdges.removeLast();
        var node = edge.destinationNode;
        if (_nonNullIntentNodes.contains(node)) {
          // Non-null intent nodes are never made nullable; a null check will need
          // to be added instead.
          continue;
        }
        for (var source in edge.sources) {
          if (!source.isNullable) {
            // Note all sources are nullable, so this edge doesn't apply yet.
            continue nextEdge;
          }
        }
        if (node.becomeNullable()) {
          // Was not previously nullable, so we need to propagate.
          pendingEdges.addAll(_downstream[node] ?? const []);
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
      pendingEdges.add(_NullabilityEdge(node.innerNode, const []));
    }
  }

  /// Propagates non-null intent upstream along unconditional control flow
  /// lines.
  void _propagateUpstream() {
    var pendingNodes = [NullabilityNode.never];
    while (pendingNodes.isNotEmpty) {
      var node = pendingNodes.removeLast();
      if (node == NullabilityNode.always) {
        // The "always" node cannot have non-null intent.
        continue;
      }
      if (_nonNullIntentNodes.add(node)) {
        // Was not previously in the set of non-null intent nodes, so we need to
        // propagate.
        pendingNodes.addAll(getUnconditionalUpstreamNodes(node));
      }
    }
  }
}

/// Data structure to keep track of the relationship from one [NullabilityNode]
/// object to another [NullabilityNode] that is "downstream" from it (meaning
/// that if the former node is nullable, then the latter node will either have
/// to be nullable, or null checks will have to be added).
class _NullabilityEdge {
  /// The node that is downstream.
  final NullabilityNode destinationNode;

  /// A set of source nodes.  By convention, the first node is the primary
  /// source and the other nodes are "guards".  The destination node will only
  /// need to be made nullable if all the source nodes are nullable.
  final List<NullabilityNode> sources;

  _NullabilityEdge(this.destinationNode, this.sources);

  Iterable<NullabilityNode> get guards => sources.skip(1);

  NullabilityNode get primarySource => sources.first;
}
