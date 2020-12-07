// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/// Dijkstra's algorithm for single source shortest path.
///
/// Adopted from https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm#Pseudocode
///
/// Note that this is not an optimal implementation in that it uses a
/// (Splay) Tree as the priority queue which takes O(log n) time to (fake) a
/// decrease of priority whereas e.g. a fibonacci heap would have done it in
/// (amortized) O(1).
class DijkstrasAlgorithm<E> {
  Map<GraphNode<E>, int> dist = new Map<GraphNode<E>, int>();
  Map<GraphNode<E>, GraphNode<E>> prev = new Map<GraphNode<E>, GraphNode<E>>();

  DijkstrasAlgorithm(Iterable<GraphNode<E>> graphNodes, GraphNode<E> source,
      int Function(E, E) comparator, int Function(E, E) distance) {
    SplayTreeSet<GraphNode<E>> q = new SplayTreeSet<GraphNode<E>>((a, b) {
      int distA = dist[a];
      int distB = dist[b];

      int when0() {
        if (identical(a, b)) return 0;
        int result = comparator(a.node, b.node);
        if (result == 0) {
          throw "The nodes ${b.node} and ${a.node} are not the same but "
              "compares to the same. That's not allowed!";
        }
        return result;
      }

      if (distA != null && distB == null) return -1;
      if (distA == null && distB != null) return 1;
      if (distA == null && distB == null) {
        return when0();
      }
      if (distA < distB) return -1;
      if (distA > distB) return 1;
      return when0();
    });

    dist[source] = 0;
    int index = 0;
    for (GraphNode<E> g in graphNodes) {
      // dist and prev not set, we see "null" as "infinity" and "undefined".
      if (!q.add(g)) {
        throw "Couldn't add ${g.node} (index $index).";
      }
      index++;
    }

    while (q.isNotEmpty) {
      GraphNode<E> u = q.first;
      int distToU = dist[u];
      if (distToU == null) {
        // No path to any of the remaining ${q.length} nodes.
        break;
      }
      q.remove(u);
      for (GraphNode<E> v in u.outgoing) {
        // Wikipedia says "only v that are still in Q" but it shouldn't matter
        // --- the length via u would be longer.
        int distanceUToV = distance(u.node, v.node);
        if (distanceUToV < 0) throw "Got negative distance. That's not allowed";
        int alt = distToU + distanceUToV;
        int distToV = dist[v];
        if (distToV == null || alt < distToV) {
          // Decrease length (decrease priority in priority queue).
          q.remove(v);
          dist[v] = alt;
          prev[v] = u;
          q.add(v);
        }
      }
    }
  }

  List<E> getPathFromTarget(GraphNode<E> source, GraphNode<E> target) {
    List<E> path = <E>[];
    GraphNode<E> u = target;
    while (u == source || prev[u] != null) {
      path.add(u.node);
      u = prev[u];
    }
    return path.reversed.toList();
  }
}

class GraphNode<E> {
  final E node;
  final Set<GraphNode<E>> outgoing = new Set<GraphNode<E>>();
  final Set<GraphNode<E>> incoming = new Set<GraphNode<E>>();

  GraphNode(this.node);

  void addOutgoing(GraphNode<E> other) {
    if (outgoing.add(other)) {
      other.incoming.add(this);
    }
  }

  String toString() {
    return "GraphNode[$node]";
  }
}
