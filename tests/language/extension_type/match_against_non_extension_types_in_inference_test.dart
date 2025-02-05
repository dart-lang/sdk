// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/static_type_helper.dart';

class A<X> {}

extension type ET1<Y>(A<Y> it) implements A<Y> {}

ET1<T> producingET1<T>() => ET1<T>(A<T>());

// In type constraint generation, ET1<T> is compared against A<num>, yielding
// the constraint T <: num.
test1() =>
    context<A<num>>(producingET1()..expectStaticType<Exactly<ET1<num>>>());

T acceptingFunctionET1<T>(T Function(ET1<T>) f) => f(ET1<T>(A<T>()));

num Function(A<num>) producingFunctionA() => ((A<num> a) => 0);

// In type constraint generation, A<num> is compared against ET1<T>, yielding
// the constraint num <: T.
test2() =>
    acceptingFunctionET1(producingFunctionA()).expectStaticType<Exactly<num>>();

enum E<X> {
  element<String>();
}

extension type ET2<Y>(E<Y> it) implements E<Y> {}

E<T> producingE<T>() => E.element as E<T>;

ET2<T> producingET2<T>() => ET2<T>(producingE<T>());

// In type constraint generation, ET2<T> is compared against E<String>,
// yielding the constraint T <: String.
test3() => context<E<String>>(
    producingET2()..expectStaticType<Exactly<ET2<String>>>());

T acceptingFunctionET2<T>(T Function(ET2<T>) f) => f(ET2<T>(producingE<T>()));

String Function(E<String>) producingFunctionE() => ((E<String> e) => "");

// In type constraint generation, E<String> is compared against ET2<T>,
// yielding the constraint String <: T.
test4() => acceptingFunctionET2(producingFunctionE())
    .expectStaticType<Exactly<String>>();

extension type ET3<Y>(A<Y> it) implements ET1<Y> {}

ET3<T> producingET3<T>() => ET3<T>(A<T>());

// In type constraint generation, ET3<T> is compared against A<num>, yielding
// the constraint T <: num.
test5() =>
    context<A<num>>(producingET3()..expectStaticType<Exactly<ET3<num>>>());

T acceptingFunctionET3<T>(T Function(ET3<T>) f) => f(ET3<T>(A<T>()));

// In type constraint generation, A<num> is compared against ET3<T>, yielding
// the constraint num <: T.
test6() =>
    acceptingFunctionET3(producingFunctionA()).expectStaticType<Exactly<num>>();

extension type ET4<Y>(E<Y> it) implements ET2<Y> {}

ET4<T> producingET4<T>() => ET4<T>(producingE<T>());

// In type constraint generation, ET4<T> is compared against E<String>,
// yielding the constraint T <: String.
test7() => context<E<String>>(
    producingET4()..expectStaticType<Exactly<ET4<String>>>());

T acceptingFunctionET4<T>(Function(ET4<T>) f) => f(ET4<T>(producingE<T>()));

// In type constraint generation, E<String> is compared against ET4<T>,
// yielding the constraint String <: T.
test8() => acceptingFunctionET4(producingFunctionE())
    .expectStaticType<Exactly<String>>();

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
  test8();
}
