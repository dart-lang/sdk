// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:noInline')
int opaqueVal() => int.parse('42');

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:noInline')
void callClosure(void Function() func) {
  if (opaqueVal() == 1) func();
}

// All of the local variables in [foo45] are expected to be captured: a, b, and
// c. When the loop-depth allocation strategy is enabled, all of the variables
// are expected to be put in the same context.
void foo45() {
  int a = 10;

  callClosure(() {
    a += 11;
  });

  if (opaqueVal() == 1) {
    int b = 20;

    callClosure(() {
      a += 12;
      b += 22;
    });
  }

  if (opaqueVal() == 1) {
    int c = 30;

    callClosure(() {
      a += 13;
      c += 33;
    });
  }
}
