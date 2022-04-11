// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when the feature is disabled, inferred types do not flow
// "horizontally" from a non-closure argument of an invocation to a closure
// argument.

// @dart=2.17

import '../static_type_helper.dart';

testLaterUnnamedParameter(void Function<T>(T, void Function(T)) f) {
  f(0, (x) {
    x.expectStaticType<Exactly<Object?>>();
  });
}

testEarlierUnnamedParameter(void Function<T>(void Function(T), T) f) {
  f((x) {
    x.expectStaticType<Exactly<Object?>>();
  }, 0);
}

testLaterNamedParameter(
    void Function<T>({required T a, required void Function(T) b}) f) {
  f(
      a: 0,
      b: (x) {
        x.expectStaticType<Exactly<Object?>>();
      });
}

testEarlierNamedParameter(
    void Function<T>({required void Function(T) a, required T b}) f) {
  f(
      a: (x) {
        x.expectStaticType<Exactly<Object?>>();
      },
      b: 0);
}

testPropagateToReturnType(U Function<T, U>(T, U Function(T)) f) {
  f(0, (x) => [x]).expectStaticType<Exactly<List<Object?>>>();
}

testUnnecessaryDueToNoDependency(T Function<T>(T Function(), T) f) {
  f(() => 0, null).expectStaticType<Exactly<int?>>();
}

main() {}
