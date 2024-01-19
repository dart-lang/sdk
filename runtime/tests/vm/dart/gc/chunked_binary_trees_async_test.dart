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

// Stress test for write barrier elimination in SuspendState suspend.

class Node {
  Node? left, right;
  int depth;
  Node(this.depth);
}

buildTopDown(Node n, int depth) async {
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

  var f1 = buildTopDown(ll, depth - 1);
  var f2 = buildTopDown(lr, depth - 1);
  await f1;
  await f2;
  var f3 = buildTopDown(rl, depth - 1);
  var f4 = buildTopDown(rr, depth - 1);
  await f3;
  await f4;
}

checkTopDown(Node n, int depth) async {
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
  await checkTopDown(n.left!.left!, depth - 1);
  await checkTopDown(n.left!.right!, depth - 1);
  await checkTopDown(n.right!.left!, depth - 1);
  await checkTopDown(n.right!.right!, depth - 1);
}

runTopDown(int depth) async {
  Node n = new Node(depth);
  await buildTopDown(n, depth);
  await checkTopDown(n, depth);
}

Future<Node> buildBottomUp(int depth) async {
  if (depth == 0) {
    return new Node(depth);
  }

  var f1 = buildBottomUp(depth - 1);
  var f2 = buildBottomUp(depth - 1);
  Node ll = await f1;
  Node lr = await f2;
  var f3 = buildBottomUp(depth - 1);
  var f4 = buildBottomUp(depth - 1);
  Node rl = await f3;
  Node rr = await f4;

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

checkButtomUp(Node n, int depth) async {
  if (depth == 0) {
    if (n.left != null) throw "Bad";
    if (n.right != null) throw "Bad";
    return;
  }

  if (n.depth != depth) throw "Bad";
  if (n.left!.depth != depth) throw "Bad";
  if (n.right!.depth != depth) throw "Bad";
  await checkButtomUp(n.left!.left!, depth - 1);
  await checkButtomUp(n.left!.right!, depth - 1);
  await checkButtomUp(n.right!.left!, depth - 1);
  await checkButtomUp(n.right!.right!, depth - 1);
}

runBottomUp(int depth) async {
  Node n = await buildBottomUp(depth);
  await checkButtomUp(n, depth);
}

main() async {
  for (var i = 0; i < 5; i++) {
    await runTopDown(9);
    await runBottomUp(9);
  }
}
