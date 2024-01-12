// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--verify_store_buffer
// VMOptions=--verify_after_marking
// VMOptions=--runtime_allocate_old
// VMOptions=--runtime_allocate_spill_tlab
// VMOptions=--no_inline_alloc --runtime_allocate_spill_tlab
// VMOptions=--no_inline_alloc

// Stress test for write barrier elimination in SuspendState clone.

class Node {
  Node? left, right;
  int depth;
  var retain;
  Node(this.depth);
}

Iterable<Node> buildBottomUp(int depth) sync* {
  for (;;) {
    if (depth == 0) {
      yield new Node(depth);
    } else {
      var i = buildBottomUp(depth - 1);
      var i1 = i.iterator; // SuspendState.clone
      i1.moveNext();
      Node ll = i1.current;
      var i2 = i.iterator; // SuspendState.clone
      i2.moveNext();
      Node lr = i2.current;
      var i3 = i.iterator; // SuspendState.clone
      i3.moveNext();
      Node rl = i3.current;
      var i4 = i.iterator; // SuspendState.clone
      i4.moveNext();
      Node rr = i4.current;

      Node l = new Node(depth);
      Node r = new Node(depth);
      Node n = new Node(depth);

      n.left = l; // no-barrier
      n.right = r; // no-barrier
      l.left = ll; // no-barrier
      l.right = lr; // no-barrier
      r.left = rl; // no-barrier
      r.right = rr; // no-barrier

      n.retain = i;
      l.retain = i1;
      r.retain = i2;

      yield n;
    }
  }
}

checkButtomUp(Node n, int depth) {
  if (depth == 0) {
    if (n.left != null) throw "Bad";
    if (n.right != null) throw "Bad";
    return;
  }

  if (n.depth != depth) throw "Bad";
  if (n.left!.depth != depth) throw "Bad";
  if (n.right!.depth != depth) throw "Bad";
  checkButtomUp(n.left!.left!, depth - 1);
  checkButtomUp(n.left!.right!, depth - 1);
  checkButtomUp(n.right!.left!, depth - 1);
  checkButtomUp(n.right!.right!, depth - 1);
}

runBottomUp(int depth) {
  var i = buildBottomUp(depth).iterator;
  i.moveNext();
  Node n = i.current;
  checkButtomUp(n, depth);
}

main() {
  for (var i = 0; i < 10; i++) {
    runBottomUp(9);
  }
}
