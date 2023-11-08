// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'field_access_lib.dart';

extension on dynamic {
  void set it(value) {}
}

extension type InlineClass(int it) {
  void test() {
    var a1 = this.it;
    var a2 = it;
    var b1 = this.it<int>; // Error
    var b2 = it<int>; // Error
    var c1 = this.it = 42; // Error, should not resolve to extension method.
    var c2 = it = 42; // Error, should not resolve to extension method.
  }
}

extension type GenericInlineClass<T>(T it) {
  void test(T t) {
    var a1 = this.it;
    var a2 = it;
    var b1 = this.it<int>; // Error
    var b2 = it<int>; // Error
    var c1 = this.it = t; // Error, should not resolve to extension method.
    var c2 = it = t; // Error, should not resolve to extension method.
  }
}

extension type FunctionInlineClass<T>(T Function() it) {
  void test(T Function()  t) {
    var a1 = this.it;
    var a2 = it;
    var b1 = this.it<int>; // Error
    var b2 = it<int>; // Error
    var c1 = this.it = t; // Error, should not resolve to extension method.
    var c2 = it = t; // Error, should not resolve to extension method.
    var d1 = this.it();
    var d2 = it();
    var d3 = this.it.call();
    var d4 = it.call();
  }
}

extension type GenericFunctionInlineClass(T Function<T>() it) {
  void test() {
    var a1 = this.it;
    var a2 = it;
    int Function() a3 = this.it;
    int Function() a4 = it;
    var b1 = this.it<int>;
    var b2 = it<int>;
    var c1 = this.it = t; // Error, should not resolve to extension method.
    var c2 = it = t; // Error, should not resolve to extension method.
    var d1 = this.it();
    var d2 = it();
    var d3 = this.it.call();
    var d4 = it.call();
    var e1 = this.it<int>();
    var e2 = it<int>();
  }
}


extension type DynamicInlineClass(dynamic it) {
  void test() {
    var a1 = this.it;
    var a2 = it;
    var b1 = this.it<int>; // Error
    var b2 = it<int>; // Error
    var c1 = this.it = 42; // Error, should not resolve to extension method.
    var c2 = it = 42; // Error, should not resolve to extension method.
    var d1 = this.it();
    var d2 = it();
    var d3 = this.it.call();
    var d4 = it.call();
  }
}

extension type ErroneousInlineClass(int a, String b) {
  void test() {
    var a1 = this.a;
    var a2 = a;
    var a3 = this.b; // Error
    var a4 = b; // Error
    var b1 = this.a<int>; // Error
    var b2 = a<int>; // Error
    var b3 = this.b<int>; // Error
    var b4 = b<int>; // Error
    var c1 = this.a = 42; // Error
    var c2 = a = 42; // Error
    var c3 = this.b = '42'; // Error
    var c4 = b = '42'; // Error
    var d1 = this.a(); // Error
    var d2 = a(); // Error
    var d3 = this.a.call(); // Error
    var d4 = a.call(); // Error
    var e1 = this.b(); // Error
    var e2 = b(); // Error
    var e3 = this.b.call(); // Error
    var e4 = b.call(); // Error
  }
}

void test(
    InlineClass inlineClass,
    GenericInlineClass<String> genericInlineClass,
    FunctionInlineClass<String> functionInlineClass,
    GenericFunctionInlineClass genericFunctionInlineClass,
    DynamicInlineClass dynamicInlineClass,
    ErroneousInlineClass erroneousInlineClass,
    PrivateInlineClass privateInlineClass) {

  var a1 = inlineClass.it;
  var a2 = inlineClass.it<int>; // Error
  var a3 = inlineClass.it = 42; // Error,
                                // should not resolve to extension method.

  var b1 = genericInlineClass.it;
  var b2 = genericInlineClass.it<int>; // Error
  var b3 = genericInlineClass.it = '42'; // Error, should not
                                         // resolve to extension method.

  var c1 = functionInlineClass.it;
  var c2 = functionInlineClass.it<int>; // Error
  var c3 = functionInlineClass.it();
  var c4 = functionInlineClass.it.call();
  var c5 = functionInlineClass.it = () => '42'; // Error, should not
                                                // resolve to extension method.

  var d1 = genericFunctionInlineClass.it;
  int Function() d2 = genericFunctionInlineClass.it;
  var d3 = genericFunctionInlineClass.it<int>;
  var d4 = genericFunctionInlineClass.it<int>();
  var d5 = genericFunctionInlineClass.it.call<int>();
  var d6 = genericFunctionInlineClass.it = <T>() => throw ''; // Error, should
                                           // not resolve to extension method.

  var e1 = dynamicInlineClass.it;
  var e2 = dynamicInlineClass.it<int>; // Error
  var e3 = dynamicInlineClass.it();
  var e4 = dynamicInlineClass.it = '42'; // Error, should not resolve
                                         // to extension method.

  var f1 = erroneousInlineClass.a;
  var f2 = erroneousInlineClass.a<int>; // Error
  var f3 = erroneousInlineClass.a = 42; // Error, should not resolve
                                       // to extension method.
  var g1 = erroneousInlineClass.b;
  var g2 = erroneousInlineClass.a<int>; // Error
  var g3 = erroneousInlineClass.b = '42'; // Error, should not resolve
                                         // to extension method.

  var h1 = privateInlineClass._it; // Error
  var h2 = privateInlineClass._it<int>; // Error
  var h3 = privateInlineClass._it = 42; // Error
}
