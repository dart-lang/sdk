// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--stacktrace_every=1 --deterministic --optimization-counter-threshold=6 --optimization-filter=baz

// Regression test for https://github.com/dart-lang/sdk/issues/38743.
// Verifies that VM doesn't crash when collecting debugger stack traces in
// closures inside instance methods.

class A {
  foo(unusedArg0) {
    baz() {
      for (int i = 0; i < 3; ++i) {
        print('[$i] $unusedArg0');
      }
    }

    baz();
  }
}

main() {
  A().foo(null);
}
