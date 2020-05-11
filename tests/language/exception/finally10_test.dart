// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to not treat the finally
// block as a successor of a catch block that throws.

import "package:expect/expect.dart";

class A {
  var field;
  start() {}
  stop() {
    field = 42;
  }
}

class B {
  var totalCompileTime = new A();
  var runCompiler = new Object();

  run() {
    totalCompileTime.start();
    try {
      throw 'foo';
    } catch (exception) {
      // Use [runCompiler] twice to ensure it will have a local
      // variable.
      runCompiler.toString();
      runCompiler.toString();
      rethrow;
    } finally {
      totalCompileTime.stop();
    }
  }
}

main() {
  var b = new B();
  try {
    b.run();
    throw 'Expected exception';
  } catch (exception) {
    // Expected exception.
  }

  Expect.equals(42, b.totalCompileTime.field);
}
