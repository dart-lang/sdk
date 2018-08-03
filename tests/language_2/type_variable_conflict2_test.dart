// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 13134. Invocation of a type parameter.

import "package:expect/expect.dart";

class C<T> {
  noSuchMethod(Invocation im) {
    throw "noSuchMethod shouldn't be called in this test.";
  }

  // This is equivalent to (T).call(). See issue 19725
  foo() => T(); //# 01: compile-time error

  // T is in scope, even in static context. Compile-time error to call this.T().
  static bar() => T(); //# 02: compile-time error

  // X is not in scope. NoSuchMethodError.
  static baz() => X(); //# 03: compile-time error

  // Class 'C' has no static method 'T': NoSuchMethodError.
  static qux() => C.T(); //# 04: compile-time error

  // Class '_Type' has no instance method 'call': NoSuchMethodError.
  quux() => (T)(); //# 05: compile-time error

  // Runtime type T not accessible from static context. Compile-time error.
  static corge() => (T)(); //# 06: compile-time error

  // Class '_Type' has no [] operator: NoSuchMethodError.
  grault() => T[0]; //# 07: compile-time error

  // Runtime type T not accessible from static context. Compile-time error.
  static garply() => T[0]; //# 08: compile-time error

  // Class '_Type' has no member m: NoSuchMethodError.
  waldo() => T.m; //# 09: compile-time error

  // Runtime type T not accessible from static context. Compile-time error.
  static fred() => T.m; //# 10: compile-time error
}

main() {
  Expect.throwsNoSuchMethodError(() => new C().foo()); //# 01: continued
  C.bar(); //# 02: continued
  Expect.throwsNoSuchMethodError(() => C.baz()); //# 03: continued
  Expect.throwsNoSuchMethodError(() => C.qux()); //# 04: continued
  Expect.throwsNoSuchMethodError(() => new C().quux()); //# 05: continued
  C.corge(); //# 06: continued
  Expect.throwsNoSuchMethodError(() => new C().grault()); //# 07: continued
  C.garply(); //# 08: continued
  Expect.throwsNoSuchMethodError(() => new C().waldo()); //# 09: continued
  C.fred(); //# 10: continued
}
