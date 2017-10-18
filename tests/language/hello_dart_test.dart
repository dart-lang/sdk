// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Simple test program invoked with an option to eagerly
// compile all code that is loaded in the isolate.
// VMOptions=--compile_all --error-on-bad-type --error-on-bad-override

class HelloDartTest {
  static testMain() {
    print("Hello, Darter!");
  }
}

main() {
  HelloDartTest.testMain();
}
