// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import '../static_type_helper.dart';

// Test least upper bound for types involving `FutureOr`.

bool condition = true;

class A {}

class B {}

class C extends B {}

class D extends B {}

class E<T> {}

class F<T> extends E<T> {}

void main() {
  // Approach: First test operand types (with no occurrence of `FutureOr`)
  // then test those operands used as type arguments according to the
  // rules about **UP**(T1, T2) where T1 or T2 is of the form `FutureOr<S>`.

  void f1(int a, String b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<Object>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<Object>>();
  }

  void f2(FutureOr<int> a, FutureOr<String> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  void f3(Future<int> a, FutureOr<String> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  void f4(int a, FutureOr<String> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  void f5(int a, num b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<num>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<num>>();
  }

  void f6(FutureOr<int> a, FutureOr<num> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<num>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<num>>>();
  }

  void f7(Future<int> a, FutureOr<num> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<num>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<num>>>();
  }

  void f8(int a, FutureOr<num> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<num>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<num>>>();
  }

  void f9(List<int> a, List<String> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<List<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<List<Object>>>();
  }

  void f10(FutureOr<List<int>> a, FutureOr<List<String>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<List<Object>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<List<Object>>>>();
  }

  void f11(Future<List<int>> a, FutureOr<List<String>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<List<Object>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<List<Object>>>>();
  }

  void f12(List<int> a, FutureOr<List<String>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<List<Object>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<List<Object>>>>();
  }

  void f13(List<int> a, List<num> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<List<num>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<List<num>>>();
  }

  void f14(FutureOr<List<int>> a, FutureOr<List<num>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<List<num>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<List<num>>>>();
  }

  void f15(Future<List<int>> a, FutureOr<List<num>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<List<num>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<List<num>>>>();
  }

  void f16(List<int> a, FutureOr<List<num>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<List<num>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<List<num>>>>();
  }

  void f17(dynamic a, void b) {
    var x = condition ? a : b;
    /**/ x.toString();
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.

    var y = condition ? b : a;
    /**/ y.toString();
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }

  void f18(FutureOr<dynamic> a, FutureOr<void> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<void>>>();
    if (x is Future) throw 0;
    /**/ x.toString();
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<void>>>();
    if (y is Future) throw 0;
    /**/ y.toString();
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }

  void f19(Future<dynamic> a, FutureOr<void> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<void>>>();
    if (x is Future) throw 0;
    /**/ x.toString();
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<void>>>();
    if (y is Future) throw 0;
    /**/ y.toString();
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }

  void f20(dynamic a, FutureOr<void> b) {
    var x = condition ? a : b;
    // Verify that the type of `x` is `dynamic`.
    Never n = x; // It is `dynamic` or `Never`.
    x = 0; // It is a supertype of `int`.
    x = false; // It is a supertype of `bool`.

    var y = condition ? b : a;
    // Verify that the type of `y` is `dynamic`.
    n = y;
    y = 0;
    y = false;
  }

  void f21(A a, B b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<Object>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<Object>>();
  }

  void f22(FutureOr<A> a, FutureOr<B> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  void f23(Future<A> a, FutureOr<B> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  void f24(A a, FutureOr<B> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  void f25(B a, C b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<B>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<B>>();
  }

  void f26(FutureOr<B> a, FutureOr<C> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<B>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<B>>>();
  }

  void f27(Future<B> a, FutureOr<C> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<B>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<B>>>();
  }

  void f28(B a, FutureOr<C> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<B>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<B>>>();
  }

  void f29(C a, D b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<B>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<B>>();
  }

  void f30(FutureOr<C> a, FutureOr<D> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<B>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<B>>>();
  }

  void f31(Future<C> a, FutureOr<D> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<B>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<B>>>();
  }

  void f32(C a, FutureOr<D> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<B>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<B>>>();
  }

  void f33(E<B> a, E<C> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<E<B>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<E<B>>>();
  }

  void f34(FutureOr<E<B>> a, FutureOr<E<C>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<E<B>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<E<B>>>>();
  }

  void f35(Future<E<B>> a, FutureOr<E<C>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<E<B>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<E<B>>>>();
  }

  void f36(E<B> a, FutureOr<E<C>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<E<B>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<E<B>>>>();
  }

  void f37(E<B> a, F<C> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<E<B>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<E<B>>>();
  }

  void f38(FutureOr<E<B>> a, FutureOr<F<C>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<E<B>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<E<B>>>>();
  }

  void f39(Future<E<B>> a, FutureOr<F<C>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<E<B>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<E<B>>>>();
  }

  void f40(E<B> a, FutureOr<F<C>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<E<B>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<E<B>>>>();
  }

  void f41(int a, String? b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<Object?>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<Object?>>();
  }

  void f42(FutureOr<int> a, FutureOr<String?> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object?>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object?>>>();
  }

  void f43(Future<int> a, FutureOr<String?> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object?>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object?>>>();
  }

  void f44(int a, FutureOr<String?> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object?>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object?>>>();
  }

  void f45(List<int> a, List<String>? b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<List<Object>?>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<List<Object>?>>();
  }

  void f46(FutureOr<List<int>> a, FutureOr<List<String>?> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<List<Object>?>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<List<Object>?>>>();
  }

  void f47(Future<List<int>> a, FutureOr<List<String>?> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<List<Object>?>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<List<Object>?>>>();
  }

  void f48(List<int> a, FutureOr<List<String>?> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<List<Object>?>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<List<Object>?>>>();
  }

  void f49(E<C> a, F<B> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<Object>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<Object>>();
  }

  void f50(FutureOr<E<C>> a, FutureOr<F<B>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  void f51(Future<E<C>> a, FutureOr<F<B>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  void f52(E<C> a, FutureOr<F<B>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  // A sample of cases involving nested futures and nullable types.

  void f53(int a, FutureOr<Future<int>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  // Could soundly have been `FutureOr<Future<int>>`.
  void f54(Future<int> a, FutureOr<Future<int>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Object>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Object>>>();
  }

  void f55(Future<Future<int>> a, FutureOr<Future<int>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<Future<int>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<Future<int>>>>();
  }

  void f56(Future<FutureOr<int>> a, FutureOr<Future<int>> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<FutureOr<int>>>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<FutureOr<int>>>>();
  }

  void f57(Future<int?> a, FutureOr<int>? b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<int?>?>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<int?>?>>();
  }

  void f58(Future<int>? a, FutureOr<int?> b) {
    var x = condition ? a : b;
    x.expectStaticType<Exactly<FutureOr<int?>?>>();

    var y = condition ? b : a;
    y.expectStaticType<Exactly<FutureOr<int?>?>>();
  }
}
