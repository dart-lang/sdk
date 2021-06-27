// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import '../static_type_helper.dart';

class C1<X> {}

class C2 extends C1<C2> {}

var condition = true;

void main() {
  void f0<X1 extends int>(X1 x1, String t2) {
    // UP(X1 extends int /*B1*/, String /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as int);
    z1.expectStaticType<Exactly<int>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<Object>>();

    // UP(String /*T2*/, X1 extends int /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as int) : x1;
    z4.expectStaticType<Exactly<int>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<Object>>();
  }

  void g0<X1>(X1 x1, String t2) {
    if (x1 is int) {
      // UP(X1 & int /*B1*/, String /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<Object>>();

      // UP(String /*T2*/, X1 & int /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<Object>>();
    }
  }

  void f1<X1 extends C1<X1>>(X1 x1, C1<C2> t2) {
    // UP(X1 extends C1<X1> /*B1*/, C1<C2> /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as C1<X1>);
    z1.expectStaticType<Exactly<C1<X1>>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<C1<Object?>>>();

    // UP(C1<C2> /*T2*/, X1 extends C1<X1> /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as C1<X1>) : x1;
    z4.expectStaticType<Exactly<C1<X1>>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<C1<Object?>>>();
  }

  void g1<X1>(X1 x1, C1<C2> t2) {
    if (x1 is C1<X1>) {
      // UP(X1 & C1<X1> /*B1*/, C1<C2> /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<C1<Object?>>>();

      // UP(C1<C2> /*T2*/, X1 & C1<X1> /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<C1<Object?>>>();
    }
  }

  void f2<X1 extends C1<X1>>(X1 x1, C1<C2>? t2) {
    // UP(X1 extends C1<X1> /*B1*/, C1<C2>? /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as C1<X1>);
    z1.expectStaticType<Exactly<C1<X1>>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<C1<Object?>?>>();

    // UP(C1<C2>? /*T2*/, X1 extends C1<X1> /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as C1<X1>) : x1;
    z4.expectStaticType<Exactly<C1<X1>>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<C1<Object?>?>>();
  }

  void g2<X1>(X1 x1, C1<C2>? t2) {
    if (x1 is C1<X1>) {
      // UP(X1 & C1<X1> /*B1*/, C1<C2>? /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<C1<Object?>?>>();

      // UP(C1<C2>? /*T2*/, X1 & C1<X1> /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<C1<Object?>?>>();
    }
  }

  void f3<X1 extends C1<X1>?>(X1 x1, C1<C2> t2) {
    // UP(X1 extends C1<X1>? /*B1*/, C1<C2> /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as C1<X1>?);
    z1.expectStaticType<Exactly<C1<Object?>?>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<C1<Object?>?>>();

    // UP(C1<C2> /*T2*/, X1 extends C1<X1>? /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as C1<X1>?) : x1;
    z4.expectStaticType<Exactly<C1<Object?>?>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<C1<Object?>?>>();
  }

  void g3<X1>(X1 x1, C1<C2> t2) {
    if (x1 is C1<X1>?) {
      // UP(X1 & C1<X1>? /*B1*/, C1<C2> /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<C1<Object?>?>>();

      // UP(C1<C2> /*T2*/, X1 & C1<X1>? /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<C1<Object?>?>>();
    }
  }

  void f4<X1 extends C1<X1>?>(X1 x1, C1<C2>? t2) {
    // UP(X1 extends C1<X1>? /*B1*/, C1<C2>? /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as C1<X1>?);
    z1.expectStaticType<Exactly<C1<Object?>?>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<C1<Object?>?>>();

    // UP(C1<C2>? /*T2*/, X1 extends C1<X1>? /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as C1<X1>?) : x1;
    z4.expectStaticType<Exactly<C1<Object?>?>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<C1<Object?>?>>();
  }

  void g4<X1>(X1 x1, C1<C2>? t2) {
    if (x1 is C1<X1>?) {
      // UP(X1 & C1<X1>? /*B1*/, C1<C2>? /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<C1<Object?>?>>();

      // UP(C1<C2>? /*T2*/, X1 & C1<X1>? /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<C1<Object?>?>>();
    }
  }

  void f5<X1 extends Iterable<Iterable<X1>?>>(
      X1 x1, Iterable<List<Object?>?> t2) {
    // UP(X1 extends Iterable<Iterable<X1>?> /*B1*/,
    //     Iterable<List<Object?>?> /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as Iterable<Iterable<X1>?>);
    z1.expectStaticType<Exactly<Iterable<Iterable<X1>?>>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<Iterable<Iterable<Object?>?>>>();

    // UP(Iterable<List<Object?>?> /*T2*/,
    //     X1 extends Iterable<Iterable<X1>?> /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as Iterable<Iterable<X1>?>) : x1;
    z4.expectStaticType<Exactly<Iterable<Iterable<X1>?>>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<Iterable<Iterable<Object?>?>>>();
  }

  void g5<X1>(X1 x1, Iterable<List<Object?>?> t2) {
    if (x1 is Iterable<Iterable<X1>?>) {
      // UP(X1 & Iterable<Iterable<X1>?> /*B1*/,
      //     Iterable<List<Object?>?> /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<Iterable<Iterable<Object?>?>>>();

      // UP(Iterable<List<Object?>?> /*T2*/,
      //     X1 & Iterable<Iterable<X1>?> /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<Iterable<Iterable<Object?>?>>>();
    }
  }

  void g6<X1>(X1 x1, FutureOr<Object> t2) {
    if (x1 is FutureOr<X1>) {
      // UP(X1 & FutureOr<X1> /*B1*/, FutureOr<Object> /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<FutureOr<Object>?>>();

      // UP(FutureOr<Object> /*T2*/, X1 & FutureOr<X1> /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<FutureOr<Object>?>>();
    }
  }

  void g7<X1>(X1 x1, FutureOr<Object> t2) {
    if (x1 is FutureOr<X1?>) {
      // UP(X1 & FutureOr<X1?> /*B1*/, FutureOr<Object> /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<FutureOr<Object>?>>();

      // UP(FutureOr<Object> /*T2*/, X1 & FutureOr<X1?> /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<FutureOr<Object>?>>();
    }
  }

  void f8<X1 extends void Function(X1)>(X1 x1, void Function(Null) t2) {
    // UP(X1 extends void Function(X1) /*B1*/, void Function(Null) /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as void Function(X1));
    z1.expectStaticType<Exactly<void Function(X1)>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<void Function(Never)>>();

    // UP(void Function(Null) /*T2*/, X1 extends void Function(X1) /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as void Function(X1)) : x1;
    z4.expectStaticType<Exactly<void Function(X1)>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<void Function(Never)>>();
  }

  void g8<X1>(X1 x1, void Function(Null) t2) {
    if (x1 is void Function(X1)) {
      // UP(X1 & void Function(X1) /*B1*/, void Function(Null) /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<void Function(Never)>>();

      // UP(void Function(Null) /*T2*/, X1 & void Function(X1) /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<void Function(Never)>>();
    }
  }

  void f9<X1 extends void Function([X1])>(X1 x1, void Function([Null]) t2) {
    // UP(X1 extends void Function([X1]) /*B1*/, void Function([Null]) /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as void Function([X1]));
    z1.expectStaticType<Exactly<void Function([X1])>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<void Function([Never])>>();

    // UP(void Function([Null]) /*T2*/, X1 extends void Function([X1]) /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as void Function([X1])) : x1;
    z4.expectStaticType<Exactly<void Function([X1])>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<void Function([Never])>>();
  }

  void g9<X1>(X1 x1, void Function([Null]) t2) {
    if (x1 is void Function([X1])) {
      // UP(X1 & void Function([X1]) /*B1*/, void Function([Null]) /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<void Function([Never])>>();

      // UP(void Function([Null]) /*T2*/, X1 & void Function([X1]) /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<void Function([Never])>>();
    }
  }

  void f10<X1 extends void Function({X1 p})>(
      X1 x1, void Function({Null p}) t2) {
    // UP(X1 extends void Function({X1 p}) /*B1*/,
    //     void Function({Null p}) /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as void Function({X1 p}));
    z1.expectStaticType<Exactly<void Function({X1 p})>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<void Function({Never p})>>();

    // UP(void Function({Null p}) /*T2*/,
    //     X1 extends void Function({X1 p}) /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as void Function({X1 p})) : x1;
    z4.expectStaticType<Exactly<void Function({X1 p})>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<void Function({Never p})>>();
  }

  void g10<X1>(X1 x1, void Function({Null p}) t2) {
    if (x1 is void Function({X1 p})) {
      // UP(X1 & void Function({X1 p}) /*B1*/, void Function({Null p}) /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<void Function({Never p})>>();

      // UP(void Function({Null p}) /*T2*/, X1 & void Function({X1 p}) /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<void Function({Never p})>>();
    }
  }

  void f11<X1 extends void Function({required X1 p})>(
      X1 x1, void Function({X1 p}) t2) {
    // UP(X1 extends void Function({required X1 p}) /*B1*/,
    //     void Function({X1 p}) /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as void Function({required X1 p}));
    z1.expectStaticType<Exactly<void Function({required X1 p})>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<void Function({required Never p})>>();

    // UP(void Function({X1 p}) /*T2*/,
    //     X1 extends void Function({required X1 p}) /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as void Function({required X1 p})) : x1;
    z4.expectStaticType<Exactly<void Function({required X1 p})>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<void Function({required Never p})>>();
  }

  void g11<X1>(X1 x1, void Function({X1 p}) t2) {
    if (x1 is void Function({required X1 p})) {
      // UP(X1 & void Function({required X1 p}) /*B1*/,
      //     void Function({X1 p}) /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<void Function({required Never p})>>();

      // UP(void Function({X1 p}) /*T2*/,
      //     X1 & void Function({required X1 p}) /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<void Function({required Never p})>>();
    }
  }

  void f12<X1 extends void Function(FutureOr<X1>)>(
      X1 x1, void Function(FutureOr<Null>) t2) {
    // UP(X1 extends void Function(FutureOr<X1>) /*B1*/,
    //     void Function(FutureOr<Null>) /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as void Function(FutureOr<X1>));
    z1.expectStaticType<Exactly<void Function(FutureOr<X1>)>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<void Function(FutureOr<Never>)>>();

    // UP(void Function(FutureOr<Null>) /*T2*/,
    //     X1 extends void Function(FutureOr<X1>) /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as void Function(FutureOr<X1>)) : x1;
    z4.expectStaticType<Exactly<void Function(FutureOr<X1>)>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<void Function(FutureOr<Never>)>>();
  }

  void g12<X1>(X1 x1, void Function(FutureOr<Null>) t2) {
    if (x1 is void Function(FutureOr<X1>)) {
      // UP(X1 & void Function(FutureOr<X1>) /*B1*/,
      //     void Function(FutureOr<Null>) /*T2*/) =
      //   T2 if X1 <: T2
      //   otherwise X1 if T2 <: X1
      //   otherwise UP(B1a, T2)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z1 = condition ? x1 : (null as Object?);
      z1.expectStaticType<Exactly<Object?>>();

      var z2 = condition ? x1 : throw 0;
      z2.expectStaticType<Exactly<X1>>();

      var z3 = condition ? x1 : t2;
      z3.expectStaticType<Exactly<void Function(FutureOr<Never>)>>();

      // UP(void Function(FutureOr<Null>) /*T2*/,
      //     X1 & void Function(FutureOr<X1>) /*B1*/) =
      //   X1 if T2 <: X1
      //   otherwise T2 if X1 <: T2
      //   otherwise UP(T2, B1a)
      //     where B1a is the greatest closure of B1 with respect to X1

      var z4 = condition ? null as Object? : x1;
      z4.expectStaticType<Exactly<Object?>>();

      var z5 = condition ? throw 0 : x1;
      z5.expectStaticType<Exactly<X1>>();

      var z6 = condition ? t2 : x1;
      z6.expectStaticType<Exactly<void Function(FutureOr<Never>)>>();
    }
  }
}
