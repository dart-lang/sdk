// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Note: we pass --save-debugging-info=* without --dwarf-stack-traces to
// make this test pass on vm-aot-dwarf-* builders.
//
// VMOptions=--save-debugging-info=$TEST_COMPILATION_DIR/debug.so
// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

// @dart=2.9

import 'awaiter_stacks/harness.dart' as harness;

class A {
  void takesA(A a) {
    print("Hello A");
  }
}

class B extends A {
  void takesA(covariant B b) {
    print("Hello B");
  }
}

StackTrace trace = null;

void main() async {
  if (harness.shouldSkip()) {
    // Skip the test in this configuration.
    return;
  }
  harness.configure(currentExpectations);

  A a = new A();
  A b = new B();
  try {
    b.takesA(a);
  } catch (e, st) {
    trace = st;
  }

  await harness.checkExpectedStack(trace);
  harness.updateExpectations();
}

// CURRENT EXPECTATIONS BEGIN
final currentExpectations = [
  """
#0    B.takesA (%test%)
#1    main (%test%)
#2    _delayEntrypointInvocation.<anonymous closure> (isolate_patch.dart)
#3    _RawReceivePort._handleMessage (isolate_patch.dart)"""
];
// CURRENT EXPECTATIONS END
