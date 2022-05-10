// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that horizontal inference works properly when the invocation is an
// extension member.  This is an important corner case because the front end
// adds an implicit `this` argument to extension members as part of the lowering
// process.  We need to make sure that the dependency tracking logic properly
// accounts for this extra argument.

// SharedOptions=--enable-experiment=inference-update-1

import '../static_type_helper.dart';

testLaterUnnamedParameter(int i) {
  i._laterUnnamedParameter(0, (x) {
    x.expectStaticType<Exactly<int>>();
  });
}

/// This special case verifies that the implementations correctly associate the
/// zeroth positional parameter with the corresponding argument (even if that
/// argument isn't in the zeroth position at the call site).
testLaterUnnamedParameterDependsOnNamedParameter(int i) {
  i._laterUnnamedParameterDependsOnNamedParameter(a: 0, (x) {
    x.expectStaticType<Exactly<int>>();
  });
}

testEarlierUnnamedParameter(int i) {
  i._earlierUnnamedParameter((x) {
    x.expectStaticType<Exactly<int>>();
  }, 0);
}

testLaterNamedParameter(int i) {
  i._laterNamedParameter(
      a: 0,
      b: (x) {
        x.expectStaticType<Exactly<int>>();
      });
}

testEarlierNamedParameter(int i) {
  i._earlierNamedParameter(
      a: (x) {
        x.expectStaticType<Exactly<int>>();
      },
      b: 0);
}

/// This special case verifies that the implementations correctly associate the
/// zeroth positional parameter with the corresponding argument (even if that
/// argument isn't in the zeroth position at the call site).
testEarlierNamedParameterDependsOnUnnamedParameter(int i) {
  i._earlierNamedParameterDependsOnUnnamedParameter(a: (x) {
    x.expectStaticType<Exactly<int>>();
  }, 0);
}

testPropagateToReturnType(int i) {
  i
      ._propagateToReturnType(0, (x) => [x])
      .expectStaticType<Exactly<List<int>>>();
}

// The test cases below exercise situations where there are multiple closures in
// the invocation, and they need to be inferred in the right order.

testClosureAsParameterType(int i) {
  i
      ._closureAsParameterType(
          () => 0, (h) => [h()]..expectStaticType<Exactly<List<int>>>())
      .expectStaticType<Exactly<List<int>>>();
}

testPropagateToEarlierClosure(int i) {
  i
      ._propagateToEarlierClosure(
          (x) => [x]..expectStaticType<Exactly<List<int>>>(), () => 0)
      .expectStaticType<Exactly<List<int>>>();
}

testPropagateToLaterClosure(int i) {
  i
      ._propagateToLaterClosure(
          () => 0, (x) => [x]..expectStaticType<Exactly<List<int>>>())
      .expectStaticType<Exactly<List<int>>>();
}

testLongDependencyChain(int i) {
  i
      ._longDependencyChain(
          () => [0],
          (x) => x.single..expectStaticType<Exactly<int>>(),
          (y) => {y}..expectStaticType<Exactly<Set<int>>>())
      .expectStaticType<Exactly<Set<int>>>();
}

testDependencyCycle(int i) {
  i
      ._dependencyCycle((x) => [x]..expectStaticType<Exactly<List<Object?>>>(),
          (y) => {y}..expectStaticType<Exactly<Set<Object?>>>())
      .expectStaticType<Exactly<Map<List<Object?>, Set<Object?>>>>();
}

testPropagateFromContravariantReturnType(int i) {
  i
      ._propagateFromContravariantReturnType(
          () => (int i) {}, (x) => [x]..expectStaticType<Exactly<List<int>>>())
      .expectStaticType<Exactly<List<int>>>();
}

testPropagateToContravariantParameterType(int i) {
  i
      ._propagateToContravariantParameterType(() => 0,
          (x) => [x]..expectStaticType<Exactly<List<void Function(int)>>>())
      .expectStaticType<Exactly<List<void Function(int)>>>();
}

testReturnTypeRefersToMultipleTypeVars(int i) {
  i._returnTypeRefersToMultipleTypeVars(() => {0: ''}, (k) {
    k.expectStaticType<Exactly<int>>();
  }, (v) {
    v.expectStaticType<Exactly<String>>();
  });
}

testUnnecessaryDueToNoDependency(int i) {
  i
      ._unnecessaryDueToNoDependency(() => 0, null)
      .expectStaticType<Exactly<int?>>();
}

testUnnecessaryDueToExplicitParameterTypeNamed(int i) {
  var a = i._unnecessaryDueToExplicitParameterTypeNamed(
      null, ({int? x, required y}) => (x ?? 0) + y);
  a.expectStaticType<Exactly<int?>>();
}

testParenthesized(int i) {
  i._parenthesized(0, ((x) {
    x.expectStaticType<Exactly<int>>();
  }));
}

testParenthesizedNamed(int i) {
  i._parenthesizedNamed(
      a: 0,
      b: ((x) {
        x.expectStaticType<Exactly<int>>();
      }));
}

testParenthesizedTwice(int i) {
  i._parenthesizedTwice(0, (((x) {
    x.expectStaticType<Exactly<int>>();
  })));
}

testParenthesizedTwiceNamed(int i) {
  i._parenthesizedTwiceNamed(
      a: 0,
      b: (((x) {
        x.expectStaticType<Exactly<int>>();
      })));
}

extension on int {
  T _laterUnnamedParameter<T>(T x, void Function(T) y) => throw '';
  void _laterUnnamedParameterDependsOnNamedParameter<T>(void Function(T) x,
          {required T a}) =>
      throw '';
  void _earlierUnnamedParameter<T>(void Function(T) x, T y) => throw '';
  void _laterNamedParameter<T>({required T a, required void Function(T) b}) =>
      throw '';
  void _earlierNamedParameter<T>({required void Function(T) a, required T b}) =>
      throw '';
  void _earlierNamedParameterDependsOnUnnamedParameter<T>(T b,
          {required void Function(T) a}) =>
      throw '';
  U _propagateToReturnType<T, U>(T x, U Function(T) y) => throw '';
  U _closureAsParameterType<T, U>(T x, U Function(T) y) => throw '';
  U _propagateToEarlierClosure<T, U>(U Function(T) x, T Function() y) =>
      throw '';
  U _propagateToLaterClosure<T, U>(T Function() x, U Function(T) y) => throw '';
  V _longDependencyChain<T, U, V>(
          T Function() x, U Function(T) y, V Function(U) z) =>
      throw '';
  Map<T, U> _dependencyCycle<T, U>(T Function(U) x, U Function(T) y) =>
      throw '';
  U _propagateFromContravariantReturnType<T, U>(
          void Function(T) Function() x, U Function(T) y) =>
      throw '';
  U _propagateToContravariantParameterType<T, U>(
          T Function() x, U Function(void Function(T)) y) =>
      throw '';
  void _returnTypeRefersToMultipleTypeVars<T, U>(
          Map<T, U> Function() x, void Function(T) y, void Function(U) z) =>
      throw '';
  T _unnecessaryDueToNoDependency<T>(T Function() x, T y) => throw '';
  T _unnecessaryDueToExplicitParameterTypeNamed<T>(
          T x, T Function({required T x, required int y}) y) =>
      throw '';
  void _parenthesized<T>(T x, void Function(T) y) => throw '';
  void _parenthesizedNamed<T>({required T a, required void Function(T) b}) =>
      throw '';
  void _parenthesizedTwice<T>(T x, void Function(T) y) => throw '';
  void _parenthesizedTwiceNamed<T>(
          {required T a, required void Function(T) b}) =>
      throw '';
}

main() {}
