// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  noSuchMethod(_) => 'foo';
  get hashCode => 42;
}

// Keep that list empty to make the inferrer infer an empty element
// type.
var a = [];
var b = [new A(), new Object() as dynamic];

main() {
  // The following [hashCode] call will create a selector whose
  // receiver type is empty. This used to make dart2js generate a
  // [noSuchMethod] handler for [hashCode] on the Object class, which
  // would override the actual implementation.
  Expect.throws(() => a[0].hashCode, (e) => e is RangeError);

  // This code calls the [hashCode] method put on the [Object] class,
  // which used to be a [noSuchMethod] handler method.
  Expect.isTrue(b[1].hashCode is int);

  // Sanity checks.
  Expect.equals(42, b[0].hashCode);
  Expect.equals('foo', b[0].foo());

  // Prevent optimizations on the [b] variable.
  b.clear();
}
