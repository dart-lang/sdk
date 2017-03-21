// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  Function closure;
  A._(this.closure);

  factory A() {
    return new A._(() => new Set<T>());
  }

  A.bar() {
    closure = () => new Set<T>();
  }

  static
  T /// 01: static type warning, dynamic type error
  staticMethod(
  T /// 02: static type warning, dynamic type error
  a) {
    final
    T /// 03: static type warning, dynamic type error
    a = "not_null";
    print(a);
    return a;
  }

  static final
  T /// 04: static type warning, dynamic type error
  staticFinalField = "not_null";

  static const
  T /// 05: static type warning, checked mode compile-time error
  staticConstField = "not_null";

  static not_null() => "not_null";
  static final
  T /// 06: static type warning, dynamic type error
  staticFinalField2 = not_null();

  // Assigning null to a malformed type is not a dynamic error.
  static
  T staticMethod2(T a) {
    final T a = null;
    print(a);
    return a;
  }

  static final T staticFinalField3 = null;

  static null_() => null;
  static final T staticFinalField4 = null_();
}

main() {
  var s = ((new A()).closure)();
  Expect.isTrue(s is Set);

  s = ((new A.bar()).closure)();
  Expect.isTrue(s is Set);

  s = ((new A<int>()).closure)();
  Expect.isTrue(s is Set<int>);
  Expect.isFalse(s is Set<double>);

  s = ((new A<int>.bar()).closure)();
  Expect.isTrue(s is Set<int>);
  Expect.isFalse(s is Set<double>);

  A.staticMethod("not_null");
  print(A.staticFinalField);
  print(A.staticConstField);
  print(A.staticFinalField2);

  A.staticMethod2(null);
  print(A.staticFinalField3);
  print(A.staticFinalField4);
}
