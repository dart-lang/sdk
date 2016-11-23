// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to work with graphs. It contains a couple algorithms, including
/// Tarjan's algorithm to compute strongly connected components in a graph and
/// Cooper et al's dominator algorithm.
///
/// Portions of the code in this library was adapted from
/// `package:analyzer/src/generated/collection_utilities.dart`.
// TODO(sigmund): move this into a shared place, like quiver?
library dart2js_info.src.graph;

import 'dart:math' as math;

abstract class Graph<N> {
  Iterable<N> get nodes;
  bool get isEmpty;
  int get nodeCount;
  Iterable<N> targetsOf(N source);
  Iterable<N> sourcesOf(N source);

  /// Run a topological sort of the graph. Since the graph may contain cycles,
  /// this results in a list of strongly connected components rather than a list
  /// of nodes. The nodes in each strongly connected components only have edges
  /// that point to nodes in the same component or earlier components.
  List<List<N>> computeTopologicalSort() {
    _SccFinder<N> finder = new _SccFinder<N>(this);
    return finder.computeTopologicalSort();
  }

  /// Whether [source] can transitively reach [target].
  bool containsPath(N source, N target) {
    Set<N> seen = new Set<N>();
    bool helper(N node) {
      if (identical(node, target)) return true;
      if (!seen.add(node)) return false;
      return targetsOf(node).any(helper);
    }

    return helper(source);
  }

  /// Returns all nodes reachable from [root] in post order.
  Iterable<N> postOrder(N root) sync* {
    var seen = new Set<N>();
    Iterable<N> helper(N n) sync* {
      if (!seen.add(n)) return;
      for (var x in targetsOf(n)) {
        yield* helper(x);
      }
      yield n;
    }

    yield* helper(root);
  }

  /// Returns an iterable of all nodes reachable from [root] in preorder.
  Iterable<N> preOrder(N root) sync* {
    var seen = new Set<N>();
    var stack = <N>[root];
    while (stack.isNotEmpty) {
      var next = stack.removeLast();
      if (!seen.contains(next)) {
        seen.add(next);
        yield next;
        stack.addAll(targetsOf(next));
      }
    }
  }

  /// Returns a list of nodes that form a cycle containing the given node. If
  /// the node is not part of a cycle in this graph, then a list containing only
  /// the node itself will be returned.
  List<N> findCycleContaining(N node) {
    assert(node != null);
    _SccFinder<N> finder = new _SccFinder<N>(this);
    return finder._componentContaining(node);
  }

  /// Returns a dominator tree starting from root. This is a new graph, with the
  /// same nodes as this graph, but where edges exist between a node and the
  /// nodes it immediately dominates. For example, this graph:
  ///
  ///       root
  ///       /   \
  ///      a     b
  ///      |    / \
  ///      c   d   e
  ///       \ / \ /
  ///        f   g
  ///
  /// Produces this tree:
  ///
  ///       root
  ///       /|  \
  ///      a |   b
  ///      | |  /|\
  ///      c | d | e
  ///        |   |
  ///        f   g
  ///
  /// Internally we compute dominators using (Cooper, Harvey, and Kennedy's
  /// algorithm)[http://www.cs.rice.edu/~keith/EMBED/dom.pdf].
  Graph<N> dominatorTree(N root) {
    var iDom = (new _DominatorFinder(this)..run(root)).immediateDominators;
    var graph = new EdgeListGraph<N>();
    for (N node in iDom.keys) {
      if (node != root) graph.addEdge(iDom[node], node);
    }
    return graph;
  }
}

class EdgeListGraph<N> extends Graph<N> {
  /// Edges in the graph.
  Map<N, Set<N>> _edges = new Map<N, Set<N>>();

  /// The reverse of _edges.
  Map<N, Set<N>> _revEdges = new Map<N, Set<N>>();

  Iterable<N> get nodes => _edges.keys;
  bool get isEmpty => _edges.isEmpty;
  int get nodeCount => _edges.length;

  final _empty = new Set<N>();

  Iterable<N> targetsOf(N source) => _edges[source] ?? _empty;
  Iterable<N> sourcesOf(N source) => _revEdges[source] ?? _empty;

  void addEdge(N source, N target) {
    assert(source != null);
    assert(target != null);
    addNode(source);
    addNode(target);
    _edges[source].add(target);
    _revEdges[target].add(source);
  }

  void addNode(N node) {
    assert(node != null);
    _edges.putIfAbsent(node, () => new Set<N>());
    _revEdges.putIfAbsent(node, () => new Set<N>());
  }

  /// Remove the edge from the given [source] node to the given [target] node.
  /// If there was no such edge then the graph will be unmodified: the number of
  /// edges will be the same and the set of nodes will be the same (neither node
  /// will either be added or removed).
  void removeEdge(N source, N target) {
    _edges[source]?.remove(target);
  }

  /// Remove the given node from this graph. As a consequence, any edges for
  /// which that node was either a head or a tail will also be removed.
  void removeNode(N node) {
    _edges.remove(node);
    var sources = _revEdges[node];
    if (sources == null) return;
    for (var source in sources) {
      _edges[source].remove(node);
    }
  }

  /// Remove all of the given nodes from this graph. As a consequence, any edges
  /// for which those nodes were either a head or a tail will also be removed.
  void removeAllNodes(List<N> nodes) => nodes.forEach(removeNode);
}

/// Used by the [SccFinder] to maintain information about the nodes that have
/// been examined. There is an instance of this class per node in the graph.
class _NodeInfo<N> {
  /// Depth of the node corresponding to this info.
  int index = 0;

  /// Depth of the first node in a cycle.
  int lowlink = 0;

  /// Whether the corresponding node is on the stack. Used to remove the need
  /// for searching a collection for the node each time the question needs to be
  /// asked.
  bool onStack = false;

  /// Component that contains the corresponding node.
  List<N> component;

  _NodeInfo(int depth)
      : index = depth,
        lowlink = depth,
        onStack = false;
}

/// Implements Tarjan's Algorithm for finding the strongly connected components
/// in a graph.
class _SccFinder<N> {
  /// The graph to process.
  final Graph<N> _graph;

  /// The index used to uniquely identify the depth of nodes.
  int _index = 0;

  /// Nodes that are being visited in order to identify components.
  List<N> _stack = new List<N>();

  /// Information associated with each node.
  Map<N, _NodeInfo<N>> _info = <N, _NodeInfo<N>>{};

  /// All strongly connected components found, in topological sort order (each
  /// node in a strongly connected component only has edges that point to nodes
  /// in the same component or earlier components).
  List<List<N>> _allComponents = new List<List<N>>();

  _SccFinder(this._graph);

  /// Return a list containing the nodes that are part of the strongly connected
  /// component that contains the given node.
  List<N> _componentContaining(N node) => _strongConnect(node).component;

  /// Run Tarjan's algorithm and return the resulting list of strongly connected
  /// components. The list is in topological sort order (each node in a strongly
  /// connected component only has edges that point to nodes in the same
  /// component or earlier components).
  List<List<N>> computeTopologicalSort() {
    for (N node in _graph.nodes) {
      var nodeInfo = _info[node];
      if (nodeInfo == null) _strongConnect(node);
    }
    return _allComponents;
  }

  /// Remove and return the top-most element from the stack.
  N _pop() {
    N node = _stack.removeAt(_stack.length - 1);
    _info[node].onStack = false;
    return node;
  }

  /// Add the given node to the stack.
  void _push(N node) {
    _info[node].onStack = true;
    _stack.add(node);
  }

  /// Compute the strongly connected component that contains the given node as
  /// well as any components containing nodes that are reachable from the given
  /// component.
  _NodeInfo<N> _strongConnect(N v) {
    // Set the depth index for v to the smallest unused index
    var vInfo = new _NodeInfo<N>(_index++);
    _info[v] = vInfo;
    _push(v);

    for (N w in _graph.targetsOf(v)) {
      var wInfo = _info[w];
      if (wInfo == null) {
        // Successor w has not yet been visited; recurse on it
        wInfo = _strongConnect(w);
        vInfo.lowlink = math.min(vInfo.lowlink, wInfo.lowlink);
      } else if (wInfo.onStack) {
        // Successor w is in stack S and hence in the current SCC
        vInfo.lowlink = math.min(vInfo.lowlink, wInfo.index);
      }
    }

    // If v is a root node, pop the stack and generate an SCC
    if (vInfo.lowlink == vInfo.index) {
      var component = new List<N>();
      N w;
      do {
        w = _pop();
        component.add(w);
        _info[w].component = component;
      } while (!identical(w, v));
      _allComponents.add(component);
    }
    return vInfo;
  }
}

/// Computes dominators using (Cooper, Harvey, and Kennedy's
/// algorithm)[http://www.cs.rice.edu/~keith/EMBED/dom.pdf].
class _DominatorFinder<N> {
  final Graph<N> _graph;
  Map<N, N> immediateDominators = {};
  Map<N, int> postOrderId = {};
  _DominatorFinder(this._graph);

  run(N root) {
    immediateDominators[root] = root;
    bool changed = true;
    int i = 0;
    var nodesInPostOrder = _graph.postOrder(root).toList();
    for (var n in nodesInPostOrder) {
      postOrderId[n] = i++;
    }
    var nodesInReversedPostOrder = nodesInPostOrder.reversed;
    while (changed) {
      changed = false;
      for (var n in nodesInReversedPostOrder) {
        if (n == root) continue;
        bool first = true;
        N idom;
        for (var p in _graph.sourcesOf(n)) {
          if (immediateDominators[p] != null) {
            if (first) {
              idom = p;
              first = false;
            } else {
              idom = _intersect(p, idom);
            }
          }
        }
        if (immediateDominators[n] != idom) {
          immediateDominators[n] = idom;
          changed = true;
        }
      }
    }
  }

  N _intersect(N b1, N b2) {
    var finger1 = b1;
    var finger2 = b2;
    while (finger1 != finger2) {
      while (postOrderId[finger1] < postOrderId[finger2]) {
        finger1 = immediateDominators[finger1];
      }
      while (postOrderId[finger2] < postOrderId[finger1]) {
        finger2 = immediateDominators[finger2];
      }
    }
    return finger1;
  }
}
