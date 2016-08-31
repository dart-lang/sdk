// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 13134. Invocation of a type parameter.

import "package:expect/expect.dart";

class C<T> {
  noSuchMethod(Invocation im) {
    Expect.equals(#T, im.memberName);
    return 42;
  }

  // Class 'C' has no instance method 'T': call noSuchMethod.
  foo() => T();  /// 01: static type warning

  // T is in scope, even in static context. Compile-time error to call this.T().
  static bar() => T();  /// 02: compile-time error

  // X is not in scope. NoSuchMethodError.
  static baz() => X();  /// 03: static type warning

  // Class 'C' has no static method 'T': NoSuchMethodError.
  static qux() => C.T();  /// 04: static type warning

  // Class '_Type' has no instance method 'call': NoSuchMethodError.
  quux() => (T)();  /// 05: static type warning

  // Runtime type T not accessible from static context. Compile-time error.
  static corge() => (T)();  /// 06: compile-time error

  // Class '_Type' has no [] operator: NoSuchMethodError.
  grault() => T[0];  /// 07: static type warning

  // Runtime type T not accessible from static context. Compile-time error.
  static garply() => T[0];  /// 08: compile-time error

  // Class '_Type' has no member m: NoSuchMethodError.
  waldo() => T.m;  /// 09: static type warning

  // Runtime type T not accessible from static context. Compile-time error.
  static fred() => T.m;  /// 10: compile-time error
}

main() {
  Expect.equals(42, new C().foo());  /// 01: continued
  C.bar();  /// 02: continued
  Expect.throws(() => C.baz(), (e) => e is NoSuchMethodError);  /// 03: continued
  Expect.throws(() => C.qux(), (e) => e is NoSuchMethodError);  /// 04: continued
  Expect.throws(() => new C().quux(), (e) => e is NoSuchMethodError);  /// 05: continued
  C.corge();  /// 06: continued
  Expect.throws(() => new C().grault(), (e) => e is NoSuchMethodError);  /// 07: continued
  C.garply();  /// 08: continued
  Expect.throws(() => new C().waldo(), (e) => e is NoSuchMethodError);  /// 09: continued
  C.fred();  /// 10: continued
}
