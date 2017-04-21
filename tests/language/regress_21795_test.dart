// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 21795.

foo(t) {
  try {
    if (t == 123) throw 42;
  } finally {}
}

bar() {
  try {
    return 42;
  } finally {}
}

class A {
  test(t) {
    try {
      foo(t);
    } finally {
      if (t == 0) {
        try {} catch (err, st) {}
      }
    }
  }
}

main() {
  var a = new A();
  for (var i = 0; i < 10000; ++i) a.test(0);
  try {
    a.test(123);
  } catch (e, s) {
    if (s.toString().indexOf("foo") == -1) {
      print(s);
      throw "Expected foo in stacktrace!";
    }
  }
}
