// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that Null inherits properties from Object.

main() {
  var x;

  Expect.isTrue(x is Object);
  Expect.isTrue(x is dynamic);
  Expect.isTrue(x is! String);
  Expect.isTrue(x is! int);

  // These shouldn't throw.
  x.runtimeType;
  x.toString();
  x.hashCode;

  // operator== is inherited from Object. It's the same as identical.
  // It's not really testable.
  Expect.isTrue(identical(x, null));
  Expect.isTrue(x == null);

  // Methods can be closurized and yields the same result.
  var ts = x.toString;
  Expect.equals(null.toString(), ts());

  // noSuchMethod is tested in null_nosuchmethod_test.dart.
}
