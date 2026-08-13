// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test for type inference and ?? operator.

// -------------------------- If-null expression. ------------------------------

T hest1<T>() => throw "hest";

test1() {
  String? foo() => null;
  String bar() => "bar";

  var s = foo() ?? bar();

  String s2 = hest1() ?? "fisk";
}

// ------------------------- If-null property set. -----------------------------
class A2 {
  String? foo;
}

test2(A2 a) {
  var s = (a.foo ??= "bar");
}

// ------------------------------ If-null set. ---------------------------------
test3() {
  String? s = null;
  var s2 = (s ??= "bar");
}

// --------------------------- If-null index set. ------------------------------
test4() {
  List<String?> list = [null];
  var s = (list[0] ??= "bar");
}

// ------------------------ If-null super index set. ---------------------------
class A5 {
  void operator []=(int index, String? value) {}
  String? operator [](int index) => null;
}

class B5 extends A5 {
  test5() {
    var s = (super[0] ??= "bar");
  }
}

// -------------------------- Extension index set. -----------------------------
extension E6 on double {
  void operator []=(int index, String? value) {}
  String? operator [](int index) => null;
}

test6() {
  var s = (E6(3.14)[0] ??= "bar");
}

// ------------------------ Null-aware if-null set. ----------------------------
class A7 {
  String foo = "foo";
  String? bar;
}

test7(A7? a) {
  var s = (a?.foo ??= "bar");

  var s2 = (a?.bar ??= "bar");
}

main() {}
