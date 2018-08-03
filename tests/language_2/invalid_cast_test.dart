// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  C();
  factory C.fact() => null;
  factory C.fact2() = D;
  C.nonFact();
  C.nonFact2() : this.nonFact();
  static void staticFunction(int i) {}
}

class D extends C {}

void topLevelFunction(int i) {}

test() {
  void localFunction(int i) {}
  List<int> a = <Object>[]; //# 01: compile-time error
  Map<int, String> b = <Object, String>{}; //# 02: compile-time error
  Map<int, String> c = <int, Object>{}; //# 03: compile-time error
  int Function(Object) d = (int i) => i; //# 04: compile-time error
  D e = new C.fact(); //# 05: ok
  D f = new C.fact2(); //# 06: ok
  D g = new C.nonFact(); //# 07: compile-time error
  D h = new C.nonFact2(); //# 08: compile-time error
  void Function(Object) i = C.staticFunction; //# 09: compile-time error
  void Function(Object) j = topLevelFunction; //# 10: compile-time error
  void Function(Object) k = localFunction; //# 11: compile-time error
}

main() {}
