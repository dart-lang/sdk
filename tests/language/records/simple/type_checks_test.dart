// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code as governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=150

import "package:expect/expect.dart";
import "package:expect/variations.dart";

dynamic getP2(x, y) => (x, y);
dynamic getN2(x, y) => (foo: x, bar: y);
dynamic getP2N2(x, y, z, w) => (x, y, foo: z, bar: w);

class A<T> {
  typeCheck(T x) {}
  boundCheck<X extends T>() {}
}

verifyIsTests() {
  Expect.isTrue((1, 2) is (int, int));
  Expect.isTrue((1, 2) is (num, Object));
  Expect.isTrue((1, 2) is (Object, int));
  Expect.isFalse((1, 2) is (int, String));

  Expect.isTrue(getP2(10, 'abc') is (int, String));
  Expect.isTrue(getP2(10, 'abc') is (int foo, String bar));
  Expect.isTrue(getP2(10, 'abc') is (int bar, String foo));
  Expect.isFalse(getP2(10, 'abc') is (String bar, int foo));
  Expect.isFalse(getP2(10, 'abc') is ({int foo, String bar}));
  Expect.isFalse(getP2(10, 'abc') is (int foo, {String bar}));

  Expect.isTrue(getN2(<int>[], 10) is ({List foo, num bar}));
  Expect.isTrue(getN2(<int>[], 10) is ({List<int> foo, Object bar}));
  Expect.isTrue(getN2(<int>[], 10) is ({List<num> foo, int bar}));
  Expect.isTrue(getN2(<int>[], 10) is ({num bar, List foo}));
  Expect.isFalse(getN2(<int>[], 10) is ({List bar, num foo}));
  Expect.isFalse(getN2(<int>[], 10) is ({List foo}));
  Expect.isFalse(getN2(<int>[], 10) is ({List foo, num bar, int baz}));
  Expect.isFalse(getN2(<int>[], 10) is (List foo, {num bar}));

  Expect.isTrue(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      is (List<int>, Map<int, String>, {A<num> foo, int bar}));
  Expect.isTrue(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      is (List<int?>, Map<int?, String?>, {A<num?> foo, int? bar}));
  Expect.isTrue(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      is (List<dynamic>, Map<dynamic, dynamic>, {A<dynamic> foo, dynamic bar}));
  Expect.isTrue(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      is (dynamic, dynamic, {dynamic foo, dynamic bar}));
  Expect.isFalse(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      is (dynamic, dynamic, {dynamic foo, dynamic baz}));
  Expect.isFalse(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      is (dynamic, dynamic, dynamic, {dynamic foo, dynamic bar}));
  Expect.isFalse(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      is (dynamic, dynamic, dynamic foo, dynamic bar));
  Expect.isFalse(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      is (dynamic, dynamic, {dynamic foo, dynamic bar, dynamic baz}));
}

verifyAsChecks() {
  final results = [];
  results.add((1, 2) as (int, int));
  results.add((1, 2) as (num, Object));
  results.add((1, 2) as (Object, int));
  Expect.throwsTypeError(() => (1, 2) as (int, String));

  results.add(getP2(10, 'abc') as (int, String));
  results.add(getP2(10, 'abc') as (int foo, String bar));
  results.add(getP2(10, 'abc') as (int bar, String foo));
  Expect.throwsTypeError(() => getP2(10, 'abc') as (String bar, int foo));
  Expect.throwsTypeError(() => getP2(10, 'abc') as ({int foo, String bar}));
  Expect.throwsTypeError(() => getP2(10, 'abc') as (int foo, {String bar}));

  results.add(getN2(<int>[], 10) as ({List foo, num bar}));
  results.add(getN2(<int>[], 10) as ({List<int> foo, Object bar}));
  results.add(getN2(<int>[], 10) as ({List<num> foo, int bar}));
  results.add(getN2(<int>[], 10) as ({num bar, List foo}));
  Expect.throwsTypeError(() => getN2(<int>[], 10) as ({List bar, num foo}));
  Expect.throwsTypeError(() => getN2(<int>[], 10) as ({List foo}));
  Expect.throwsTypeError(
      () => getN2(<int>[], 10) as ({List foo, num bar, int baz}));
  Expect.throwsTypeError(() => getN2(<int>[], 10) as (List foo, {num bar}));

  results.add(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      as (List<int>, Map<int, String>, {A<num> foo, int bar}));
  results.add(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      as (List<int?>, Map<int?, String?>, {A<num?> foo, int? bar}));
  results.add(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      as (List<dynamic>, Map<dynamic, dynamic>, {A<dynamic> foo, dynamic bar}));
  results.add(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)
      as (dynamic, dynamic, {dynamic foo, dynamic bar}));
  Expect.throwsTypeError(() =>
      getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10) as (
        dynamic,
        dynamic, {
        dynamic foo,
        dynamic baz
      }));
  Expect.throwsTypeError(() =>
      getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10) as (
        dynamic,
        dynamic,
        dynamic, {
        dynamic foo,
        dynamic bar
      }));
  Expect.throwsTypeError(() =>
      getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10) as (
        dynamic,
        dynamic,
        dynamic foo,
        dynamic bar
      ));
  Expect.throwsTypeError(() =>
      getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10) as (
        dynamic,
        dynamic, {
        dynamic foo,
        dynamic bar,
        dynamic baz
      }));

  return results;
}

A<Object?> getA<T>() => int.parse("1") == 1 ? A<T>() : A<Never>();

checkParameterType<T>(x) {
  getA<T>().typeCheck(x);
}

verifyParameterTypeChecks() {
  final results = [];
  checkParameterType<(int, int)>((1, 2));
  checkParameterType<(num, Object)>((1, 2));
  checkParameterType<(Object, int)>((1, 2));
  Expect.throwsTypeError(() => checkParameterType<(int, String)>((1, 2)));

  checkParameterType<(int, String)>(getP2(10, 'abc'));
  checkParameterType<(int foo, String bar)>(getP2(10, 'abc'));
  checkParameterType<(int bar, String foo)>(getP2(10, 'abc'));
  Expect.throwsTypeError(
      () => checkParameterType<(String bar, int foo)>(getP2(10, 'abc')));
  Expect.throwsTypeError(
      () => checkParameterType<({int foo, String bar})>(getP2(10, 'abc')));
  Expect.throwsTypeError(
      () => checkParameterType<(int foo, {String bar})>(getP2(10, 'abc')));

  checkParameterType<({List foo, num bar})>(getN2(<int>[], 10));
  checkParameterType<({List<int> foo, Object bar})>(getN2(<int>[], 10));
  checkParameterType<({List<num> foo, int bar})>(getN2(<int>[], 10));
  checkParameterType<({num bar, List foo})>(getN2(<int>[], 10));
  Expect.throwsTypeError(
      () => checkParameterType<({List bar, num foo})>(getN2(<int>[], 10)));
  Expect.throwsTypeError(
      () => checkParameterType<({List foo})>(getN2(<int>[], 10)));
  Expect.throwsTypeError(() =>
      checkParameterType<({List foo, num bar, int baz})>(getN2(<int>[], 10)));
  Expect.throwsTypeError(
      () => checkParameterType<(List foo, {num bar})>(getN2(<int>[], 10)));

  checkParameterType<(List<int>, Map<int, String>, {A<num> foo, int bar})>(
      getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10));
  checkParameterType<(List<int?>, Map<int?, String?>, {A<num?> foo, int? bar})>(
      getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10));
  checkParameterType<
      (
        List<dynamic>,
        Map<dynamic, dynamic>, {
        A<dynamic> foo,
        dynamic bar
      })>(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10));
  checkParameterType<(dynamic, dynamic, {dynamic foo, dynamic bar})>(
      getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10));
  Expect.throwsTypeError(() =>
      checkParameterType<(dynamic, dynamic, {dynamic foo, dynamic baz})>(
          getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)));
  Expect.throwsTypeError(() => checkParameterType<
      (
        dynamic,
        dynamic,
        dynamic, {
        dynamic foo,
        dynamic bar
      })>(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)));
  Expect.throwsTypeError(() =>
      checkParameterType<(dynamic, dynamic, dynamic foo, dynamic bar)>(
          getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)));
  Expect.throwsTypeError(() => checkParameterType<
      (
        dynamic,
        dynamic, {
        dynamic foo,
        dynamic bar,
        dynamic baz
      })>(getP2N2(const <int>[42], <int, String>{1: 'hi'}, A<num>(), 10)));
}

checkTypeParameterBound<T, Bound>() {
  getA<Bound>().boundCheck<T>();
}

void verifyTypeParameterBoundsChecks() {
  checkTypeParameterBound<(int, int), (int, int)>();
  checkTypeParameterBound<(int, int), (num, int)>();
  checkTypeParameterBound<(int, int), (int, Object)>();
  checkTypeParameterBound<(int, int), (int, int?)>();
  checkTypeParameterBound<(int, int), (int, int)?>();
  Expect.throwsTypeError(
      () => checkTypeParameterBound<(int, Object), (int, int)>());
  if (!unsoundNullSafety) {
    Expect.throwsTypeError(
        () => checkTypeParameterBound<(int, int?), (int, int)>());
    Expect.throwsTypeError(
        () => checkTypeParameterBound<(int, int)?, (int, int)>());
  }

  checkTypeParameterBound<(String, {int foo}), (String, {int foo})>();
  Expect.throwsTypeError(() =>
      checkTypeParameterBound<(String, {int foo}), (String, {int bar})>());
  Expect.throwsTypeError(() =>
      checkTypeParameterBound<(String, {num foo}), (String, {int foo})>());
  if (!unsoundNullSafety) {
    Expect.throwsTypeError(() =>
        checkTypeParameterBound<(String, {int? foo}), (String, {int foo})>());
  }

  checkTypeParameterBound<({int foo, Object bar}), ({Object bar, int foo})>();
  checkTypeParameterBound<({int foo, Object bar}),
      ({Object foo, Object? bar})>();
  Expect.throwsTypeError(() => checkTypeParameterBound<({int foo, Object bar}),
      ({Object foo, int bar})>());

  checkTypeParameterBound<(int, String, double), (num, String, num)>();
  Expect.throwsTypeError(() =>
      checkTypeParameterBound<(int, String, Object), (num, String, num)>());
}

doTests() {
  verifyIsTests();
  verifyAsChecks();
  verifyParameterTypeChecks();
  verifyTypeParameterBoundsChecks();
}

main() {
  for (int i = 0; i < 200; ++i) {
    doTests();
  }
}
