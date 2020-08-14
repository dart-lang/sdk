// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--lazy-dispatchers
// VMOptions=--no-lazy-dispatchers

import "package:expect/expect.dart";

// Test that Null's noSuchMethod can be closurized and called directly.

class InvocationFactory {
  static final dynamic instance = new InvocationFactory();
  noSuchMethod(i) => i;
}

main() {
  dynamic x;
  // Non-existing method calls noSuchMethod.
  Expect.throwsNoSuchMethodError(() => x.foo());

  var invocation = InvocationFactory.instance.foo;

  // Calling noSuchMethod directly.
  Expect.throwsNoSuchMethodError(() => x.noSuchMethod(invocation, []));

  // Closurizing noSuchMethod and calling it.
  dynamic nsm = x.noSuchMethod;
  Expect.notEquals(null, nsm);
  Expect.throwsTypeError(() => nsm("foo"));

  Expect.throwsNoSuchMethodError(() => nsm(invocation));
  Expect.throwsNoSuchMethodError(
      () => nsm(invocation, [])); // wrong number of args

  // Wrong number and type of arguments.
  Expect.throwsNoSuchMethodError(() => nsm("foo", [])); //# 01: ok
}
