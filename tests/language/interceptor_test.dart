// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that interceptors (that is, methods in classes implemented as
// JavaScript primitives) in dart2js work.

class A {
  charCodeAt(a) => a;
}

main() {
  var res = [[], 1, 'foo', new A()];
  Expect.throws(() => res[0].charCodeAt(1));
  Expect.throws(() => (res[0].charCodeAt)(1));

  Expect.throws(() => res[1].charCodeAt(1));
  Expect.throws(() => (res[1].charCodeAt)(1));

  Expect.equals(111, res[2].charCodeAt(1));
  Expect.equals(111, (res[2].charCodeAt)(1));
  Expect.throws(() => res[2].charCodeAt(1, 4));
  Expect.throws(() => res[2].charCodeAt());
  Expect.throws(() => (res[2].charCodeAt)(1, 4));
  Expect.throws(() => (res[2].charCodeAt)());

  Expect.equals(1, res[3].charCodeAt(1));
  Expect.equals(1, (res[3].charCodeAt)(1));
  Expect.throws(() => res[3].charCodeAt(1, 4));
  Expect.throws(() => res[3].charCodeAt());
  Expect.throws(() => (res[3].charCodeAt)(1, 4));
  Expect.throws(() => (res[3].charCodeAt)());
}
