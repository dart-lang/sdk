// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that a getter is evaluated after the arguments, when a getter is
// for invoking a method. See chapter 'Method Invocation' in specification.

import "package:expect/expect.dart";

var counter = 0;

class Test1 {
  get a {
    Expect.equals(1, counter);
    counter++;
    return (c) {};
  }

  b() {
    Expect.equals(0, counter);
    counter++;
    return 1;
  }
}

class Test2 {
  static get a {
    Expect.equals(0, counter);
    counter++;
    return (c) {};
  }

  static b() {
    Expect.equals(1, counter);
    counter++;
    return 1;
  }
}

get a {
  Expect.equals(0, counter);
  counter++;
  return (c) {};
}

b() {
  Expect.equals(1, counter);
  counter++;
  return 1;
}

main() {
  var failures = [];
  try {
    // Check instance getters.
    counter = 0;
    var o = new Test1();
    o.a(o.b());
    Expect.equals(2, counter);
  } catch (exc, stack) {
    failures.add(exc);
    failures.add(stack);
  }
  try {
    // Check static getters.
    counter = 0;
    Test2.a(Test2.b());
    Expect.equals(2, counter);
  } catch (exc, stack) {
    failures.add(exc);
    failures.add(stack);
  }
  try {
    // Check top-level getters.
    counter = 0;
    a(b());
    Expect.equals(2, counter);
  } catch (exc, stack) {
    failures.add(exc);
    failures.add(stack);
  }
  // If any of the tests failed print out the details and fail the test.
  if (failures.length != 0) {
    for (var msg in failures) {
      print(msg.toString());
    }
    throw "${failures.length ~/ 2} tests failed.";
  }
}
