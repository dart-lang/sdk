// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var c0 = const C0(); //# 01: compile-time error
  var i0 = const I0(); //# 02: compile-time error
  var c1 = const C1();
  var c2 = const C2(); //# 03: compile-time error
  var c3 = const C3();
}

abstract class I0 {
  factory I0() = C0;
}

class C0 implements I0 {
  C0();
}

class C1 {
  const C1();
  var modifiable; //# 04: compile-time error
}

class C2 {
  C2();
}

class C3 {
  const C3()
      : field = new C0() //# 05: compile-time error
  ;
  final field = null;
}
