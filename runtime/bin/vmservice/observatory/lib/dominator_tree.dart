// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dominator_tree;

// Flowgraph dominators in O(m log n) time. Implements the algorithm from
// [Lengauer & Tarjan 1979]
// T. Lengauer and R.E. Tarjan,
// "A fast algorithm for finding dominators in a flowgraph",
// ACM Transactions on Programming Language and Systems, 1(1):121-141, 1979.

// Internal vertex information used inside 'Dominator'.
// Field names mostly follow naming in [Lengauer & Tarjan 1979].
class _Vertex {
  final Object id;
  _Vertex dom;
  _Vertex parent;
  _Vertex ancestor;
  _Vertex label;
  int semi;
  final List<_Vertex> pred = new List<_Vertex>();
  final List<_Vertex> bucket = new List<_Vertex>();
  // TODO(koda): Avoid duplication by having an interface for 'id' with
  // access to outgoing edges, and/or clearing 'succ' after constructing
  // inverse graph in 'pred'.
  final List<_Vertex> succ = new List<_Vertex>();
  _Vertex(this.id) { label = this; }
}

// Utility to compute immediate dominators. Usage:
// 1. Build the flowgraph using 'addEdges'.
// 2. Call 'computeDominatorTree' once.
// 3. Use 'dominator' to access result.
// The instance can only be used once.
class Dominator {
  final Map<Object, _Vertex> _idToVertex = new Map<Object, _Vertex>();
  final List<_Vertex> _vertex = new List<_Vertex>();
  
  void addEdges(Object u, Iterable<Object> vs) {
    _asVertex(u).succ.addAll(vs.map(_asVertex));
  }
  
  // Returns the immediate dominator of 'v', or null if 'v' is the root.
  Object dominator(Object v) {
    _Vertex dom = _asVertex(v).dom;
    return dom == null ? null : dom.id;
  }
  
  _Vertex _asVertex(Object u) {
    return _idToVertex.putIfAbsent(u, () => new _Vertex(u));
  }
  
  void _dfs(_Vertex v) {
    v.semi = _vertex.length;
    _vertex.add(v);
    for (_Vertex w in v.succ) {
      if (w.semi == null) {
        w.parent = v;
        _dfs(w);
      }
      w.pred.add(v);
    }
  }

  void _compress(_Vertex v) {
    if (v.ancestor.ancestor != null) {
      _compress(v.ancestor);
      if (v.ancestor.label.semi < v.label.semi) {
        v.label = v.ancestor.label;
      }
      v.ancestor = v.ancestor.ancestor;
    }
  }

  _Vertex _eval(_Vertex v) {
    if (v.ancestor == null) {
      return v;
    } else {
      _compress(v);
      return v.label;
    }
  }

  void _link(_Vertex v, _Vertex w) {
    w.ancestor = v;
  }
  
  void computeDominatorTree(Object root) {
    _Vertex r = _asVertex(root);
    int n = _idToVertex.length;
    _dfs(r);
    if (_vertex.length != n) {
      throw new StateError("Not a flowgraph: "
          "only ${_vertex.length} of $n vertices reachable");
    }
    for (int i = n - 1; i >= 1; --i) {
      _Vertex w = _vertex[i];
      for (_Vertex v in w.pred) {
        _Vertex u = _eval(v);
        if (u.semi < w.semi) {
          w.semi = u.semi;
        }
      }
      _vertex[w.semi].bucket.add(w);
      _link(w.parent, w);
      for (_Vertex v in w.parent.bucket) {
        _Vertex u = _eval(v);
        v.dom = u.semi < v.semi ? u : w.parent;
      }
      w.parent.bucket.clear();
    }
    for (int i = 1; i < n; ++i) {
      _Vertex w = _vertex[i];
      if (w.dom != _vertex[w.semi]) {
        w.dom = w.dom.dom;
      }
    }
    r.dom = null;
  }
}