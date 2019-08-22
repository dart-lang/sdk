// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that only constant types are allowed in some positions,
// not type parameters.

import "package:expect/expect.dart";

class T<X> {
  final Object value;
  const T.test1()
      : value = const //
            <X> //# 01: compile-time error
            [];
  const T.test2(Object o)
      : value = o //
            as X //# 02: compile-time error
  ;
  const T.test3(Object o)
      : value = o //
            is X //# 03: compile-time error
  ;
  const T.test4()
      : value = null //
            ?? X //# 04: compile-time error
  ;
}

class T2 {
  final Object value;
  const T2.test1() : value = const <int>[];
  const T2.test2(Object o) : value = o as int;
  const T2.test3(Object o) : value = o is int;
  const T2.test4() : value = int;
}

main() {
  // The errors in class T are errors independently of whether the
  // constructor is invoked or not.

  // Constant type expressions are allowed.
  Expect.equals(const <int>[], const T2.test1().value);
  Expect.equals(2, const T2.test2(2).value);
  Expect.isTrue(const T2.test3(2).value);
  Expect.equals(int, const T2.test4().value);
}
