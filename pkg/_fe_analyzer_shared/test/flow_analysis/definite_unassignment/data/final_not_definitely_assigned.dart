// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a final variable that is not definitely assigned before a loop,
// `try` statement, or closure is not considered definitely unassigned inside
// it. (Regression test for a bug in `inference-update-4`.)

lateFinal_loop(bool b) {
  late final int v;
  /*unassigned*/
  v;
  while (b) {
    v;
    v = 0;
  }
  v;
}

lateFinal_tryCatch() {
  late final int v;
  /*unassigned*/
  v;
  try {
    v = 0;
  } catch (_) {
    v;
  }
  v;
}

lateFinal_closure() {
  late final int v;
  /*unassigned*/
  v;
  () {
    v;
  };
  /*unassigned*/
  v;
  v = 0;
  v;
}
