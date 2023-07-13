// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--verify_store_buffer
// VMOptions=--verify_after_marking
// VMOptions=--stress_write_barrier_elimination
// VMOptions=--no_eliminate_write_barriers
// VMOptions=--no_inline_alloc

// Stress test for write barrier elimination that leaves many stores with
// eliminated barriers that create the only reference to an object in flight at
// the same time.

class Node {
  Node? left, right;
  int depth;
  Node(this.depth);
}

buildTopDown(Node n, int depth) {
  if (depth == 0) return;

  Node l = new Node(depth);
  Node ll = new Node(depth);
  Node lr = new Node(depth);
  Node r = new Node(depth);
  Node rl = new Node(depth);
  Node rr = new Node(depth);
  n.left = l; // barrier
  n.right = r; // barrier
  l.left = ll; // no-barrier
  l.right = lr; // no-barrier
  r.left = rl; // no-barrier
  r.right = rr; // no-barrier

  buildTopDown(ll, depth - 1);
  buildTopDown(lr, depth - 1);
  buildTopDown(rl, depth - 1);
  buildTopDown(rr, depth - 1);
}

checkTopDown(Node n, int depth) {
  if (depth == 0) {
    if (n.left != null) throw "Bad";
    if (n.right != null) throw "Bad";
    return;
  }

  if (n.left!.depth != depth) throw "Bad";
  if (n.left!.left!.depth != depth) throw "Bad";
  if (n.left!.right!.depth != depth) throw "Bad";
  if (n.right!.depth != depth) throw "Bad";
  if (n.right!.right!.depth != depth) throw "Bad";
  checkTopDown(n.left!.left!, depth - 1);
  checkTopDown(n.left!.right!, depth - 1);
  checkTopDown(n.right!.left!, depth - 1);
  checkTopDown(n.right!.right!, depth - 1);
}

runTopDown() {
  Node n = new Node(10);
  buildTopDown(n, 10);
  checkTopDown(n, 10);
}

Node buildBottomUp(int depth) {
  if (depth == 0) {
    return new Node(depth);
  }

  Node ll = buildBottomUp(depth - 1);
  Node lr = buildBottomUp(depth - 1);
  Node rl = buildBottomUp(depth - 1);
  Node rr = buildBottomUp(depth - 1);

  Node l = new Node(depth);
  Node r = new Node(depth);
  Node n = new Node(depth);

  n.left = l; // no-barrier
  n.right = r; // no-barrier
  l.left = ll; // no-barrier
  l.right = lr; // no-barrier
  r.left = rl; // no-barrier
  r.right = rr; // no-barrier

  return n;
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

runBottomUp() {
  Node n = buildBottomUp(10);
  checkButtomUp(n, 10);
}

main() {
  for (var i = 0; i < 10; i++) {
    runTopDown();
    runBottomUp();
  }
}
