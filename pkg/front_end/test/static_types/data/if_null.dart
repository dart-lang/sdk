// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

// -------------------------- If-null expression. ------------------------------

T hest1<T>() => /*Never*/ throw /*String!*/ "hest";

test1() {
  String? foo() => /*Null*/ null;
  String bar() => /*String!*/ "bar";

  var s = /*invoke: String?*/ foo() ?? /*invoke: String!*/ bar();
  /*String!*/ s;

  String s2 = /*invoke: String?*/ hest1/*<String?>*/() ?? /*String!*/ "fisk";
}

// ------------------------- If-null property set. -----------------------------
class A2 {
  String? foo;
}

test2(A2 a) {
  var s =
      (/*A2!*/ a. /*String?*/ /*update: String!*/ foo ??= /*String!*/ "bar");
  /*String!*/ s;
}

// ------------------------------ If-null set. ---------------------------------
test3() {
  String? s = /*Null*/ null;
  var s2 = (/*String?*/ /*update: String!*/ s ??= /*String!*/ "bar");
  /*String!*/ s2;
}

// --------------------------- If-null index set. ------------------------------
test4() {
  List<String?> list = /*List<String?>!*/ [/*Null*/ null];
  var s = (/*List<String?>!*/ list /*String?*/ /*update: void*/ [/*int!*/ 0] ??=
      /*String!*/ "bar");
  /*String!*/ s;
}

// ------------------------ If-null super index set. ---------------------------
class A5 {
  void operator []=(int index, String? value) {}
  String? operator [](int index) => /*Null*/ null;
}

class B5 extends A5 {
  test5() {
    var s = (super[/*int!*/ 0] ??= /*String!*/ "bar");
    /*String!*/ s;
  }
}

// -------------------------- Extension index set. -----------------------------
extension E6 on double {
  void operator []=(int index, String? value) {}
  String? operator [](int index) => /*Null*/ null;
}

test6() {
  var s = (E6(/*double!*/ 3.14) /*invoke: String?|void*/ [
      /*int!*/ 0] ??= /*String!*/ "bar");
  /*String!*/ s;
}

// ------------------------ Null-aware if-null set. ----------------------------
class A7 {
  String foo = /*String!*/ "foo";
  String? bar;
}

test7(A7? a) {
  var s =
      (/*A7?*/ a?. /*String!*/ /*update: String!*/ foo ??= /*String!*/ "bar");
  /*String?*/ s;

  var s2 =
      (/*A7?*/ a?. /*String?*/ /*update: String!*/ bar ??= /*String!*/ "bar");
  /*String?*/ s2;
}

main() {}
