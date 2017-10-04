// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that Null's noSuchMethod can be closurized and called directly.

class InvocationFactory {
  static final dynamic instance = new InvocationFactory();
  noSuchMethod(i) => i;
}

main() {
  var x;
  // Non-existing method calls noSuchMethod.
  Expect.throwsNoSuchMethodError(() => x.foo());

  // Calling noSuchMethod directly.
  Expect.throwsNoSuchMethodError(() => x.noSuchMethod("foo", []));

  // Closurizing noSuchMethod and calling it.
  var nsm = x.noSuchMethod;
  Expect.notEquals(null, nsm);
  Expect.throwsTypeError(() => nsm("foo"));

  var i = InvocationFactory.instance.foo;
  Expect.throwsNoSuchMethodError(() => nsm(i));
  Expect.throwsNoSuchMethodError(() => nsm(i, [])); // wrong number of args

  // Wrong number and type of arguments.
  Expect.throwsNoSuchMethodError(() => nsm("foo", [])); //# 01: ok
}
