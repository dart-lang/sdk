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

// Both a and b in [foo48] are expected to be captured. When the loop-depth
// allocation strategy is enabled, they are expected to be split into two
// distinct contexts.
void foo48() {
  if (opaqueVal() == 1) {
    int a = 10;

    callClosure(() {
      a += 11;
    });
  }

  if (opaqueVal() == 1) {
    int b = 20;

    callClosure(() {
      b += 22;
    });
  }
}
