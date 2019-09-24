// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--optimization-counter-threshold=5 --use-bytecode-compiler
//
// Test that block merging takes phis into account.
//
// The problem only reproduces with bytecode compiler (--use-bytecode-compiler)
// as bytecode doesn't have backward branches for the redundant loops.
// OSR handling code inserts Phi instructions to JoinEntry
// even when there is only one predecessor. This results in a flow graph
// suitable for block merging with a successor block containing Phi.

import 'package:expect/expect.dart';

void testBottomUpInference() {
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1]);
}

main() {
  testBottomUpInference();
}
