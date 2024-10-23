// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inference-using-bounds

import '../static_type_helper.dart';

// For the motivational issue, see
// https://github.com/dart-lang/language/issues/1194

import 'dart:async';

class A {}

class A2 extends A {}

extension type EA(A? it) {}

class B<X> {}

T foo1<T extends Object>(T? t, dynamic r) => r as T;
bar1(FutureOr<Object?> x) => foo1(x, "")..expectStaticType<Exactly<Object>>();

T foo2<T extends num>(T? t, dynamic r) => r as T;
bar2(Null x) => foo2(x, 0)..expectStaticType<Exactly<num>>();

T foo3<T extends Object>(T? t, dynamic r) => r as T;
bar3(EA x) => foo3(x, false)..expectStaticType<Exactly<Object>>();

T foo4<T extends A>(T? t, dynamic r) => r as T;
bar4<S extends A?>(S x) => foo4(x, A())..expectStaticType<Exactly<A>>();

T foo5<T extends B<S>, S>(T? t, dynamic r) => r as T;
bar5<U extends B<U>?>(U x) =>
    foo5(x, B<Never>())..expectStaticType<Exactly<B<U>>>();

// The following test case checks that the implementations use `Object?` as the
// covariant replacement in the greatest closure of a type.
T foo6<T extends B<S>, S>(T? t, dynamic r) => r as T;
bar6(Null x) => foo6(x, B<Never>())..expectStaticType<Exactly<B<Object?>>>();

T foo7<T extends B<Function(S)>, S>(T? t, dynamic r) => r as T;
bar7<U extends B<Function(U)>?>(U x) =>
    foo7(x, B<Never>())..expectStaticType<Exactly<B<Function(U)>>>();

// The following test case checks that the implementations use `Never` as the
// covariant replacement in the greatest closure of a type.p
T foo8<T extends B<Function(S)>, S extends A2>(T? t, dynamic r) => r as T;
bar8<U extends B<Function(A)>?>(U? x) =>
    foo8(x, B<Never>())..expectStaticType<Exactly<B<Function(A)>>>();

T foo9<T extends Object>(T? t, dynamic r) => r as T;
bar9<S extends num?>(S? x) => foo9(x, 0)..expectStaticType<Exactly<num>>();

// The following checks that the trivial case of the absent bound of the
// variable being inferred isn't affected.
T foo10<T>(T? t, dynamic r) => r as T;
bar10<U extends B<U>?>(U? x) => foo10(x, B<Never>());

main() {
  bar1(null);
  bar1("");
  bar1(0);

  bar2(null);

  bar3(EA(null));
  bar3(EA(A()));

  bar4(null);
  bar4(A());

  bar5(null);
  bar5(B<Never>());
  bar5(B<B<Never>>());

  bar6(null);

  bar7(null);
  bar7(B<Function(Object?)>());
  bar7(B<Function(B<Function(Never)>)>());

  bar8(null);
  bar8(B<Function(A)>());
  bar8(B<Function(Object?)>());

  bar9(null);
  bar9(0);
  bar9(.1);
}
