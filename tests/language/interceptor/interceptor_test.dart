// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that interceptors (that is, methods in classes implemented as
// JavaScript primitives) in dart2js work.

class A {
  codeUnitAt(a) => a;
}

main() {
  var res = <dynamic>[[], 1, 'foo', new A()];
  Expect.throws(() => res[0].codeUnitAt(1));
  Expect.throws(() => (res[0].codeUnitAt)(1));

  Expect.throws(() => res[1].codeUnitAt(1));
  Expect.throws(() => (res[1].codeUnitAt)(1));

  Expect.equals(111, res[2].codeUnitAt(1));
  Expect.equals(111, (res[2].codeUnitAt)(1));
  Expect.throws(() => res[2].codeUnitAt(1, 4));
  Expect.throws(() => res[2].codeUnitAt());
  Expect.throws(() => (res[2].codeUnitAt)(1, 4));
  Expect.throws(() => (res[2].codeUnitAt)());

  Expect.equals(1, res[3].codeUnitAt(1));
  Expect.equals(1, (res[3].codeUnitAt)(1));
  Expect.throws(() => res[3].codeUnitAt(1, 4));
  Expect.throws(() => res[3].codeUnitAt());
  Expect.throws(() => (res[3].codeUnitAt)(1, 4));
  Expect.throws(() => (res[3].codeUnitAt)());
}
