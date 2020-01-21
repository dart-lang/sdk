// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

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

bad() {
  void localFunction(int i) {}
  List<int> a = <Object>[];
  Map<int, String> b = <Object, String>{};
  Map<int, String> c = <int, Object>{};
  int Function(Object) d = (int i) => i;
  D e = new C.fact();
  D f = new C.fact2();
  D g = new C.nonFact();
  D h = new C.nonFact2();
  void Function(Object) i = C.staticFunction;
  void Function(Object) j = topLevelFunction;
  void Function(Object) k = localFunction;
}

ok() {
  void localFunction(int i) {}
  List<int> a = <int>[];
  Map<int, String> b = <int, String>{};
  Map<int, String> c = <int, String>{};
  int Function(int) d = (int i) => i;
  D e = new C.fact();
  D f = new C.fact2();
  C g = new C.nonFact();
  C h = new C.nonFact2();
  void Function(int) i = C.staticFunction;
  void Function(int) j = topLevelFunction;
  void Function(int) k = localFunction;
}

main() {}
