// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.dominators;

class Vertex<T extends Vertex<T>> {
  // Input: vertices directly reachable from this vertex.
  final List<T> successors = <T>[];

  // Output: the nearest vertex that all paths from the root must go through to
  // reach this vertex.
  T dominator;

  bool isDominatedBy(T other) {
    var d = this;
    while (d != null) {
      if (d == other) {
        return true;
      }
      d = d.dominator;
    }
    return false;
  }

  // Temporaries. See Lengauer and Tarjan.
  final List<T> _predecessors = <T>[];
  int _semi = 0;
  T _label;
  T _ancestor;
  T _parent;
  List<T> _bucket;
}

// T. Lengauer and R. E. Tarjan. "A Fast Algorithm for Finding Dominators
// in a Flowgraph."
computeDominators<T extends Vertex<T>>(T root) {
  // Lengauer and Tarjan Step 1.
  final vertex = <T>[];
  vertex.add(null);

  var n = 0;
  dfs(T v) {
    n++;

    vertex.add(v);
    v._semi = n;
    v._label = v;
    v._ancestor = null;

    for (final w in v.successors) {
      if (w._semi == 0) {
        w._parent = v;
        dfs(w);
      }
      w._predecessors.add(v);
    }
  }

  dfs(root);

  forestCompress(T v) {
    if (v._ancestor._ancestor != null) {
      forestCompress(v._ancestor);
      if (v._ancestor._label._semi < v._label._semi) {
        v._label = v._ancestor._label;
      }
      v._ancestor = v._ancestor._ancestor;
    }
  }

  forestEval(T v) {
    if (v._ancestor == null) {
      return v;
    } else {
      forestCompress(v);
      return v._label;
    }
  }

  forestLink(T v, T w) {
    w._ancestor = v;
  }

  for (var i = vertex.length - 1; i > 1; i--) {
    Vertex<T> w = vertex[i];

    // Lengauer and Tarjan Step 2.
    for (Vertex<T> v in w._predecessors) {
      if (v._semi == 0) continue; // Unreachable

      final u = forestEval(v);
      if (u._semi < w._semi) {
        w._semi = u._semi;
      }
    }

    Vertex<T> z = vertex[w._semi];
    var b = z._bucket;
    if (b == null) {
      z._bucket = b = <T>[];
    }
    b.add(w);
    forestLink(w._parent, w);

    // Lengauer and Tarjan Step 3.
    z = w._parent;
    assert(z != null);
    b = z._bucket;
    z._bucket = null;
    if (b != null) {
      for (final v in b) {
        final u = forestEval(v);
        v.dominator = u._semi < v._semi ? u : w._parent;
      }
    }
  }

  // Lengauer and Tarjan Step 4.
  for (var i = 2; i < vertex.length; i++) {
    final w = vertex[i];
    if (w.dominator != vertex[w._semi]) {
      w.dominator = w.dominator.dominator;
    }
  }
}
