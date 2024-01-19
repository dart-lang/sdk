// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--verify_store_buffer
// VMOptions=--verify_after_marking
// VMOptions=--runtime_allocate_old
// VMOptions=--runtime_allocate_spill_tlab
// VMOptions=--no_inline_alloc

// Stress test for write barrier elimination that leaves many stores with
// eliminated barriers that create the only reference to an object in flight at
// the same time.

buildTopDown(List n, int depth) {
  if (depth == 0) return;

  List l = new List<dynamic>.filled(3, null);
  l[2] = depth; // no-barrier
  List ll = new List<dynamic>.filled(3, null);
  ll[2] = depth; // no-barrier
  List lr = new List<dynamic>.filled(3, null);
  lr[2] = depth; // no-barrier
  List r = new List<dynamic>.filled(3, null);
  r[2] = depth; // no-barrier
  List rl = new List<dynamic>.filled(3, null);
  rl[2] = depth; // no-barrier
  List rr = new List<dynamic>.filled(3, null);
  rr[2] = depth; // no-barrier

  n[0] = l; // barrier
  n[1] = r; // barrier
  l[0] = ll; // no-barrier
  l[1] = lr; // no-barrier
  r[0] = rl; // no-barrier
  r[1] = rr; // no-barrier

  buildTopDown(ll, depth - 1);
  buildTopDown(lr, depth - 1);
  buildTopDown(rl, depth - 1);
  buildTopDown(rr, depth - 1);
}

checkTopDown(List n, int depth) {
  if (depth == 0) {
    if (n[0] != null) throw "Bad";
    if (n[1] != null) throw "Bad";
    return;
  }

  if (n[0][2] != depth) throw "Bad";
  if (n[0][0][2] != depth) throw "Bad";
  if (n[0][1][2] != depth) throw "Bad";
  if (n[1][2] != depth) throw "Bad";
  if (n[1][1][2] != depth) throw "Bad";
  checkTopDown(n[0][0]!, depth - 1);
  checkTopDown(n[0][1]!, depth - 1);
  checkTopDown(n[1][0]!, depth - 1);
  checkTopDown(n[1][1]!, depth - 1);
}

runTopDown(int depth) {
  List n = new List<dynamic>.filled(3, null);
  n[2] = depth;
  buildTopDown(n, depth);
  checkTopDown(n, depth);
}

List buildBottomUp(int depth) {
  if (depth == 0) {
    var n = new List<dynamic>.filled(3, null);
    n[2] = depth;
    return n;
  }

  List ll = buildBottomUp(depth - 1);
  List lr = buildBottomUp(depth - 1);
  List rl = buildBottomUp(depth - 1);
  List rr = buildBottomUp(depth - 1);

  List l = new List<dynamic>.filled(3, null);
  l[2] = depth; // no-barrier
  List r = new List<dynamic>.filled(3, null);
  r[2] = depth; // no-barrier
  List n = new List<dynamic>.filled(3, null);
  n[2] = depth; // no-barrier

  n[0] = l; // no-barrier
  n[1] = r; // no-barrier
  l[0] = ll; // no-barrier
  l[1] = lr; // no-barrier
  r[0] = rl; // no-barrier
  r[1] = rr; // no-barrier

  return n;
}

checkButtomUp(List n, int depth) {
  if (depth == 0) {
    if (n[0] != null) throw "Bad";
    if (n[1] != null) throw "Bad";
    return;
  }

  if (n[2] != depth) throw "Bad";
  if (n[0][2] != depth) throw "Bad";
  if (n[1][2] != depth) throw "Bad";
  checkButtomUp(n[0][0]!, depth - 1);
  checkButtomUp(n[0][1]!, depth - 1);
  checkButtomUp(n[1][0]!, depth - 1);
  checkButtomUp(n[1][1]!, depth - 1);
}

runBottomUp(int depth) {
  List n = buildBottomUp(depth);
  checkButtomUp(n, depth);
}

main() {
  for (var i = 0; i < 5; i++) {
    runTopDown(10);
    runBottomUp(10);
  }
}
