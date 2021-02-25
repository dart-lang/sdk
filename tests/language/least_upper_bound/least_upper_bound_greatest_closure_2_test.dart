// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import '../static_type_helper.dart';

class C1<X> {}

class C2 extends C1<C2> {}

var condition = true;

void main() {
  void f6<X1 extends FutureOr<X1>>(X1 x1, FutureOr<Object> t2) {
    // UP(X1 extends FutureOr<X1> /*B1*/, FutureOr<Object> /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as FutureOr<X1>);
    z1.expectStaticType<Exactly<FutureOr<X1>>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<FutureOr<Object?>>>();

    // UP(FutureOr<Object> /*T2*/, X1 extends FutureOr<X1> /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as FutureOr<X1>) : x1;
    z4.expectStaticType<Exactly<FutureOr<X1>>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<FutureOr<Object?>>>();
  }

  void f7<X1 extends FutureOr<X1?>>(X1 x1, FutureOr<Object> t2) {
    // UP(X1 extends FutureOr<X1?> /*B1*/, FutureOr<Object> /*T2*/) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z1 = condition ? x1 : ((throw 0) as FutureOr<X1?>);
    z1.expectStaticType<Exactly<FutureOr<X1?>>>();

    var z2 = condition ? x1 : throw 0;
    z2.expectStaticType<Exactly<X1>>();

    var z3 = condition ? x1 : t2;
    z3.expectStaticType<Exactly<FutureOr<Object?>>>();

    // UP(FutureOr<Object> /*T2*/, X1 extends FutureOr<X1?> /*B1*/) =
    //   X1 if T2 <: X1
    //   otherwise T2 if X1 <: T2
    //   otherwise UP(T2, B1a)
    //     where B1a is the greatest closure of B1 with respect to X1

    var z4 = condition ? ((throw 0) as FutureOr<X1?>) : x1;
    z4.expectStaticType<Exactly<FutureOr<X1?>>>();

    var z5 = condition ? throw 0 : x1;
    z5.expectStaticType<Exactly<X1>>();

    var z6 = condition ? t2 : x1;
    z6.expectStaticType<Exactly<FutureOr<Object?>>>();
  }
}
