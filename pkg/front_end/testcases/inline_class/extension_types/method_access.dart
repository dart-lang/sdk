// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension on Object {
  int get setter => 42;

  void set getter(int value) {}
}

extension type InlineClass(int it) {
  test() {
    var a = this + 2;
    var b = -this;
    var c = this[2];
    var d = this[3] = 42;
    var e1 = this.getter;
    var e2 = getter;
    var f1 = this.method;
    var f2 = method;
    var g1 = this.setter = 42;
    var g2 = setter = 42;
    this.setter = 87;
    setter = 87;
    int Function(int) h1 = this.genericMethod;
    int Function(int) h2 = genericMethod;
    this.setter; // Error, should not resolve to extension method.
    setter; // Error, should not resolve to extension method.
    this.getter = 42; // Error, should not resolve to extension method.
    getter = 42; // Error, should not resolve to extension method.
    var i1 = this.method();
    var i2 = method();
    num j1 = this.genericMethod(0);
    num j2 = genericMethod(0);
    var k1 = this.genericMethod(0);
    var k2 = genericMethod(0);
    var l1 = this.genericMethod<num>(0);
    var l2 = genericMethod<num>(0);
    var m = this();
    var n1 = this.call();
    var n2 = call();
  }

  int operator +(int other) => 42;

  int operator -() => 87;

  int operator [](int index) => 123;

  void operator []=(int index, int value) {}

  int get getter => 42;

  int method() => 42;

  void set setter(int value) {}

  T genericMethod<T>(T t) => t;

  int call() => 321;
}

test(InlineClass ic) {
  var a = ic + 2;
  var b = -ic;
  var c = ic[2];
  var d = ic[3] = 42;
  var e = ic.getter;
  var f = ic.method;
  var g = ic.setter = 42;
  ic.setter = 87;
  int Function(int) h = ic.genericMethod;
  ic.setter; // Error, should not resolve to extension method.
  ic.getter = 42; // Error, should not resolve to extension method.
  var i = ic.method();
  num j = ic.genericMethod(0);
  var k = ic.genericMethod(0);
  var l = ic.genericMethod<num>(0);
  var m = ic();
  var n = ic.call();
}