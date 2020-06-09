// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests extension methods on the non-function, non-class types.

import "dart:async" show FutureOr;

import "package:expect/expect.dart";

void main() {
  M m = C();
  Object o = Object();
  Function fun = () => null;
  f() => 0;
  String f1(int x) => "$x";
  String f2([int x = 0, int y = 0]) => "${x + y}";
  int i = 0;
  Future<int> fi = Future<int>.value(0);
  Future<Future<int>> ffi = Future<Future<int>>.value(fi);
  FutureOr<FutureOr<int>> foi = 1;
  Future<Null> fn = Future<Null>.value(null);
  Null n = null;

  // `on M` matches mixin interface.
  Expect.equals(1, m.m);
  // `on void` matches anything.
  Expect.equals(2, o.v);
  Expect.equals(2, n.v);
  // `on dynamic` matches anything.
  Expect.equals(3, o.d);
  Expect.equals(3, n.d);
  // `on Function` matches any function type and Function itself.
  Expect.equals(4, f.f);
  Expect.equals(4, fun.f);
  Expect.equals(4, f1.f);
  Expect.equals(4, f2.f);
  // `on <function type>` matches those functions.
  Expect.equals(5, f1.fu);
  Expect.equals(5, f2.fu);
  // `on FutureOr<int>` matches both future and not.
  Expect.equals(6, i.fi);
  Expect.equals(6, fi.fi);
  // `on FutureOr<Object>` matches everything.
  Expect.equals(7, o.fo);
  Expect.equals(7, n.fo);
  // `on FutureOr<Future<Object>>` matches any future or futureOr.
  Expect.equals(8, fi.ffo);
  Expect.equals(8, ffi.ffo);
  // `on FutureOr<Null>` matches Null and FutureOr<Null>.
  Expect.equals(9, fn.fn);
  Expect.equals(9, n.fn);
  // `on Null` does match null. No errors for receiver being null.
  Expect.equals(10, n.n);

  // Matching can deconstruct static function types.
  Expect.equals(int, f1.parameterType);
  Expect.equals(String, f1.returnType);
  Expect.equals(int, f2.parameterType);
  Expect.equals(String, f2.returnType);
  // And static FutureOr types.
  Expect.equals(int, i.futureType);
  Expect.equals(int, fi.futureType);
  Expect.equals(type<Future<int>>(), ffi.futureType);
  Expect.equals(type<FutureOr<int>>(), foi.futureType);
  // TODO: Update and enable when
  //  https://github.com/dart-lang/language/issues/436
  // is resolved.
  // Expect.equals(dynamic, n.futureType); // Inference treats `null` as no hint.
}

Type type<T>() => T;

mixin M {}

class C = Object with M;

extension on M {
  int get m => 1;
}

extension on void {
  int get v => 2;
  testVoid() {
    // No access on void. Static type of `this` is void!
    this //
            .toString() //# 01: compile-time error
        ;
  }
}

extension on dynamic {
  int get d => 3;

  void testDynamic() {
    // Static type of `this` is dynamic, allows dynamic invocation.
    this.arglebargle();
  }
}

extension on Function {
  int get f => 4;

  void testFunction() {
    // Static type of `this` is Function. Allows any dynamic invocation.
    this();
    this(1);
    this(x: 1);
    // No function can have both optional positional and named parameters.
  }
}

extension on String Function(int) {
  int get fu => 5;
}

extension on FutureOr<int> {
  int get fi => 6;

  void testFutureOr() {
    var self = this;
    // The `this` type can be type-promoted to both Future<int> and int.
    if (self is Future<int>) {
      self.then((int x) {});
    } else if (self is int) {
      self + 2;
    }
  }
}

extension on FutureOr<Object> {
  int get fo => 7;
}

extension on FutureOr<Future<Object>> {
  int get ffo => 8;
}

extension on FutureOr<Null> {
  int get fn => 9;
}

extension on Null {
  int get n => 10;
}

// TODO: Type `Never` when it's added.

extension<T> on FutureOr<T> {
  Type get futureType => T;
}

extension<R, T> on R Function(T) {
  Type get returnType => R;
  Type get parameterType => T;
}
