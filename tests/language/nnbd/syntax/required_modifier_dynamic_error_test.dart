// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong
import 'package:expect/expect.dart';

class Foo {
  int foo(
      {required String a,
      required String b,
      required String c,
      required String d}) {
    return a.length + b.length + c.length + d.length;
  }
}

int baz(
    {required String a,
    required String b,
    required String c,
    required String d}) {
  return a.length + b.length + c.length + d.length;
}

main() {
  Expect.equals(8, Foo().foo(a: "aa", b: "bb", c: "cc", d: "dd"));

  // Test that we throw a NoSuchMethodError, not a TypeError due to c.length.
  dynamic f = Foo();
  Expect.throwsNoSuchMethodError(() => f.foo(a: "aa", b: "bb", d: "dd"));

  dynamic tearOff = baz;
  Expect.throwsNoSuchMethodError(() => tearOff(a: "aa", c: "cc", d: "dd"));

  dynamic closure = (
      {required String a,
      required String b,
      required String c,
      required String d}) {
    return a.length + b.length + c.length + d.length;
  };
  Expect.throwsNoSuchMethodError(() => closure(a: "aa", c: "cc", d: "dd"));
}
