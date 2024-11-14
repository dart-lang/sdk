// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';

import '../mini_ast.dart';
import '../mini_types.dart';

main() {
  setUp(() {
    TypeRegistry.init();
    TypeRegistry.addInterfaceTypeName('Contravariant');
    TypeRegistry.addInterfaceTypeName('Invariant');
    TypeRegistry.addInterfaceTypeName('MyListOfInt');
    TypeRegistry.addInterfaceTypeName('Unrelated');
  });

  tearDown(() {
    TypeRegistry.uninit();
  });

  group('performSubtypeConstraintGenerationForFunctionTypes:', () {
    test('Matching functions with no parameters', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
              Type('void Function()'), Type('void Function()'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .equals(true);
      check(tcg._constraints).isEmpty();
    });

    group('Matching functions with positional parameters:', () {
      test('None optional', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, String)'), Type('void Function(T, U)'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });

      test('Some optional on LHS', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, [String])'),
                Type('void Function(T, U)'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });
    });

    group('Non-matching functions with positional parameters:', () {
      test('Non-matching due to return types', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('int Function(int)'), Type('String Function(int)'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to parameter types', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int)'), Type('void Function(String)'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to optional parameters on RHS', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function()'), Type('void Function([int])'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to more parameters being required on LHS', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int)'), Type('void Function([int])'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });
    });

    group('Matching functions with named parameters:', () {
      test('None optional', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({required int x, required String y})'),
                Type('void Function({required T x, required U y})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });

      test('Some optional on LHS', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({required int x, String y})'),
                Type('void Function({required T x, required U y})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });

      test('Optional named parameter on LHS', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, {String x})'),
                Type('void Function(T)'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int']);
      });

      test('Extra optional named parameter on LHS', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({String x, int y})'),
                Type('void Function({T y})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int']);
      });
    });

    group('Non-matching functions with named parameters:', () {
      test('Non-matching due to return types', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('int Function({int x})'), Type('String Function({int x})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to named parameter types', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({int x})'),
                Type('void Function({String x})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to required named parameter on LHS', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({required int x})'),
                Type('void Function()'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to optional named parameter on RHS', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function()'), Type('void Function({int x})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to named parameter on RHS, with decoys on LHS',
          () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function({int x, int y})'),
                Type('void Function({int z})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });
    });

    test('Matching functions with named and positional parameters', () {
      var tcg = _TypeConstraintGatherer({'T', 'U'});
      check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
              Type('void Function(int, {String y})'),
              Type('void Function(T, {U y})'),
              leftSchema: false,
              astNodeForTesting: Node.placeholder()))
          .equals(true);
      check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
    });

    group('Non-matching functions with named and positional parameters:', () {
      test(
          'Non-matching due to LHS not accepting optional positional parameter',
          () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, {String x})'),
                Type('void Function(int, [String])'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to positional parameter length mismatch', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('void Function(int, {String x})'),
                Type('void Function(int, String)'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });
    });
  });

  group('performSubtypeConstraintGenerationForRecordTypes:', () {
    test('Matching empty records', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForRecordTypes(
              Type('()'), Type('()'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .equals(true);
      check(tcg._constraints).isEmpty();
    });

    group('Matching records:', () {
      test('Without named parameters', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('(int, String)'), Type('(T, U)'),
                leftSchema: true, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['int <: T', 'String <: U']);
      });

      test('With named parameters', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('(int, {String foo})'), Type('(T, {U foo})'),
                leftSchema: true, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['int <: T', 'String <: U']);
      });
    });

    group('Non-matching records without named parameters:', () {
      test('Non-matching due to positional types', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('(int,)'), Type('(String,)'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to parameter numbers', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('()'), Type('(int,)'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to more parameters on LHS', () {
        var tcg = _TypeConstraintGatherer({});
        check(tcg.performSubtypeConstraintGenerationForFunctionTypes(
                Type('(int,)'), Type('()'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });
    });

    group('Matching records with named parameters:', () {
      test('No type parameter occurrences', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('({int x, String y})'), Type('({int x, String y})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).unorderedEquals([]);
      });

      test('Type parameters in RHS', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('({int x, String y})'), Type('({T x, U y})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).unorderedEquals(['int <: T', 'String <: U']);
      });

      test('Type parameters in LHS', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('({T x, U y})'), Type('({int x, String y})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });
    });

    group('Matching records with named parameters:', () {
      test('No type parameter occurrences', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('({int x, String y})'), Type('({int x, String y})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).unorderedEquals([]);
      });

      test('Type parameters in RHS', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('({int x, String y})'), Type('({T x, U y})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).unorderedEquals(['int <: T', 'String <: U']);
      });

      test('Type parameters in LHS', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('({T x, U y})'), Type('({int x, String y})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });
    });

    group('Non-matching records with named parameters:', () {
      test('Non-matching due to positional parameter numbers', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('(num, num, {T x, U y})'),
                Type('(num, {int x, String y})'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to named parameter numbers', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('({T x, U y, num z})'), Type('({int x, String y})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Non-matching due to named parameter names', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForRecordTypes(
                Type('(num, {T x, U y})'), Type('(num, {int x, String x2})'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });
    });
  });

  group('performSubtypeConstraintGenerationForFutureOr:', () {
    test('FutureOr matches FutureOr with constraints based on arguments', () {
      // `FutureOr<T> <# FutureOr<int>` reduces to `T <# int`
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
              Type('FutureOr<T>'), Type('FutureOr<int>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: int']);
    });

    test('FutureOr does not match FutureOr because arguments fail to match',
        () {
      // `FutureOr<int> <# FutureOr<String>` reduces to `int <# String`
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
              Type('FutureOr<int>'), Type('FutureOr<String>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isFalse();
      check(tcg._constraints).isEmpty();
    });

    test('Future matches FutureOr favoring Future branch', () {
      // `Future<int> <# FutureOr<T>` could match in two possible ways:
      // - `Future<int> <# Future<T>` (taking the "Future" branch of the
      //   FutureOr), producing `int <: T`
      // - `Future<int> <# T` (taking the "non-Future" branch of the FutureOr),
      //   producing `Future<int> <: T`
      // In cases where both branches produce a constraint, the "Future" branch
      // is favored.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
              Type('Future<int>'), Type('FutureOr<T>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['int <: T']);
    });

    test('Future matches FutureOr preferring to generate constraints', () {
      // `Future<_> <# FutureOr<T>` could match in two possible ways:
      // - `Future<_> <# Future<T>` (taking the "Future" branch of the
      //   FutureOr), producing no constraints
      // - `Future<_> <# T` (taking the "non-Future" branch of the FutureOr),
      //   producing `Future<_> <: T`
      // In cases where only one branch produces a constraint, that branch is
      // favored.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
              Type('Future<_>'), Type('FutureOr<T>'),
              leftSchema: true, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['Future<_> <: T']);
    });

    test('Type matches FutureOr favoring the Future branch', () {
      // `T <# FutureOr<int>` could match in two possible ways:
      // - `T <# Future<int>` (taking the "Future" branch of the FutureOr),
      //   producing `T <: Future<int>`
      // - `T <# int` (taking the "non-Future" branch of the FutureOr),
      //   producing `T <: int`
      // In cases where both branches produce a constraint, the "Future" branch
      // is favored.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
              Type('T'), Type('FutureOr<int>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: Future<int>']);
    });

    test('Testing FutureOr as the lower bound of the constraint', () {
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForLeftFutureOr(
              Type('FutureOr<T>'), Type('dynamic'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: dynamic']);
    });

    test('FutureOr does not match Future in general', () {
      // `FutureOr<P0> <# Q` if `Future<P0> <# Q` and `P0 <# Q`. This test case
      // verifies that if `Future<P0> <# Q` matches but `P0 <# Q` does not, then
      // the match fails.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForLeftFutureOr(
              Type('FutureOr<(T,)>'), Type('Future<(int,)>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isFalse();
      check(tcg._constraints).isEmpty();
    });

    test('Testing nested FutureOr as the lower bound of the constraint', () {
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForLeftFutureOr(
              Type('FutureOr<FutureOr<T>>'), Type('FutureOr<dynamic>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: dynamic', 'T <: dynamic']);
    });

    test('Future matches FutureOr with no constraints', () {
      // `Future<int> <# FutureOr<int>` matches (taking the "Future" branch of
      // the FutureOr) without generating any constraints.
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
              Type('Future<int>'), Type('FutureOr<int>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).isEmpty();
    });

    test('Type matches FutureOr favoring the branch that matches', () {
      // `List<T> <# FutureOr<List<int>>` could only match by taking the
      // "non-Future" branch of the FutureOr, so the constraint `T <: int` is
      // produced.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
              Type('List<T>'), Type('FutureOr<List<int>>'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: int']);
    });

    group('Nullable FutureOr on RHS:', () {
      test('Does not match, according to spec', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
                Type('FutureOr<T>'), Type('FutureOr<int>?'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Matches, according to CFE discrepancy', () {
        var tcg = _TypeConstraintGatherer({'T'},
            enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr: true);
        check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
                Type('FutureOr<T>'), Type('FutureOr<int>?'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).deepEquals(['T <: int']);
      });
    });

    group('Nullable FutureOr on LHS:', () {
      test('Does not match, according to spec', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
                Type('FutureOr<T>?'), Type('FutureOr<int>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isFalse();
        check(tcg._constraints).isEmpty();
      });

      test('Matches, according to CFE discrepancy', () {
        var tcg = _TypeConstraintGatherer({'T'},
            enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr: true);
        check(tcg.performSubtypeConstraintGenerationForRightFutureOr(
                Type('FutureOr<T>?'), Type('FutureOr<int>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .isTrue();
        check(tcg._constraints).deepEquals(['T <: int']);
      });
    });
  });

  group('performSubtypeConstraintGenerationForLeftNullableType:', () {
    test('Nullable matches nullable with constraints based on base types', () {
      // `T? <# int?` reduces to `T <# int?`
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForLeftNullableType(
              Type('T?'), Type('Null'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: Null']);
    });

    test('Nullable does not match Nullable because base types fail to match',
        () {
      // `int? <# String?` reduces to `int <# String`
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForLeftNullableType(
              Type('int?'), Type('String?'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isFalse();
      check(tcg._constraints).isEmpty();
    });

    test('Nullable does not match non-nullable', () {
      // `(int, T)? <# (int, String)` does not match
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForLeftNullableType(
              Type('(int, T)?'), Type('(int, String)'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isFalse();
      check(tcg._constraints).isEmpty();
    });

    test('Both LHS and RHS nullable, matching', () {
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForRightNullableType(
              Type('T?'), Type('int?'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: int']);
    });

    test('Both LHS and RHS nullable, not matching', () {
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForRightNullableType(
              Type('(T, int)?'), Type('(int, String)?'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isFalse();
      check(tcg._constraints).isEmpty();
    });
  });

  group('performSubtypeConstraintGenerationForRightNullableType:', () {
    test('Null matches Nullable favoring non-Null branch', () {
      // `Null <# T?` could match in two possible ways:
      // - `Null <# Null` (taking the "Null" branch of the FutureOr), producing
      //   the empty constraint set.
      // - `Null <# T` (taking the "non-Null" branch of the FutureOr),
      //   producing `Null <: T`
      // In cases where both branches produce a constraint, the "non-Null"
      // branch is favored.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForRightNullableType(
              Type('Null'), Type('T?'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['Null <: T']);
    });

    test('Type matches Nullable favoring the non-Null branch', () {
      // `T <# int?` could match in two possible ways:
      // - `T <# Null` (taking the "Null" branch of the Nullable),
      //   producing `T <: Null`
      // - `T <# int` (taking the "non-Null" branch of the Nullable),
      //   producing `T <: int`
      // In cases where both branches produce a constraint, the "non-Null"
      // branch is favored.
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationForRightNullableType(
              Type('T'), Type('int?'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).deepEquals(['T <: int']);
    });

    test('Null matches Nullable with no constraints', () {
      // `Null <# int?` matches (taking the "Null" branch of
      // the Nullable) without generating any constraints.
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForRightNullableType(
              Type('Null'), Type('int?'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).isEmpty();
    });

    test('Dynamic matches Object?', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForRightNullableType(
              Type('dynamic'), Type('Object?'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).isEmpty();
    });

    test('void matches Object?', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForRightNullableType(
              Type('void'), Type('Object?'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).isEmpty();
    });

    test('LHS not nullable, matches with no constraints', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForRightNullableType(
              Type('int'), Type('int?'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).isEmpty();
    });
  });

  group('performSubtypeConstraintGenerationForTypeDeclarationTypes', () {
    group('Same base type on both sides:', () {
      test('Covariant, matching', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Map<T, U>'), Type('Map<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['T <: int', 'U <: String']);
      });

      test('Covariant, not matching', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Map<T, int>'), Type('Map<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });

      test('Contravariant, matching', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        tcg.typeAnalyzerOperations.addVariance(
            'Contravariant', [Variance.contravariant, Variance.contravariant]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Contravariant<T, U>'), Type('Contravariant<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(['int <: T', 'String <: U']);
      });

      test('Contravariant, not matching', () {
        var tcg = _TypeConstraintGatherer({'T'});
        tcg.typeAnalyzerOperations.addVariance(
            'Contravariant', [Variance.contravariant, Variance.contravariant]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Contravariant<T, int>'),
                Type('Contravariant<int, String>'),
                leftSchema: false,
                astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });

      test('Invariant, matching', () {
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        tcg.typeAnalyzerOperations
            .addVariance('Invariant', [Variance.invariant, Variance.invariant]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Invariant<T, U>'), Type('Invariant<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).unorderedEquals(
            ['T <: int', 'U <: String', 'int <: T', 'String <: U']);
      });

      test('Invariant, not matching', () {
        var tcg = _TypeConstraintGatherer({'T'});
        tcg.typeAnalyzerOperations
            .addVariance('Invariant', [Variance.invariant, Variance.invariant]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Invariant<T, int>'), Type('Invariant<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });

      test('Unrelated, matchable', () {
        // When the variance is "unrelated", type inference doesn't even try to
        // match up the type parameters; they are always considered to match.
        var tcg = _TypeConstraintGatherer({'T', 'U'});
        tcg.typeAnalyzerOperations
            .addVariance('Unrelated', [Variance.unrelated, Variance.unrelated]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Unrelated<T, U>'), Type('Unrelated<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).isEmpty();
      });

      test('Unrelated, not matchable', () {
        // When the variance is "unrelated", type inference doesn't even try to
        // match up the type parameters; they are always considered to match.
        var tcg = _TypeConstraintGatherer({'T'});
        tcg.typeAnalyzerOperations
            .addVariance('Unrelated', [Variance.unrelated, Variance.unrelated]);
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('Unrelated<T, int>'), Type('Unrelated<int, String>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).isEmpty();
      });
    });

    group('Related types on both sides:', () {
      test('No change in type args', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('List<T>'), Type('Iterable<int>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).deepEquals(['T <: int']);
      });

      test('Change in type args', () {
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('MyListOfInt'), Type('List<T>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(true);
        check(tcg._constraints).deepEquals(['int <: T']);
      });

      test('LHS nullable', () {
        // When the LHS is a nullable type,
        // performSubtypeConstraintGenerationForTypeDeclarationTypes considers
        // it not to match (this is handled by other parts of the subtyping
        // algorithm)
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('List<T>?'), Type('Iterable<int>'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });

      test('RHS nullable', () {
        // When the RHS is a nullable type,
        // performSubtypeConstraintGenerationForTypeDeclarationTypes considers
        // it not to match (this is handled by other parts of the subtyping
        // algorithm)
        var tcg = _TypeConstraintGatherer({'T'});
        check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
                Type('List<T>'), Type('Iterable<int>?'),
                leftSchema: false, astNodeForTesting: Node.placeholder()))
            .equals(false);
        check(tcg._constraints).isEmpty();
      });
    });

    test('Non-interface type on LHS', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
              Type('void Function()'), Type('int'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isNull();
      check(tcg._constraints).isEmpty();
    });

    test('Non-interface type on RHS', () {
      var tcg = _TypeConstraintGatherer({});
      check(tcg.performSubtypeConstraintGenerationForTypeDeclarationTypes(
              Type('int'), Type('void Function()'),
              leftSchema: false, astNodeForTesting: Node.placeholder()))
          .isNull();
      check(tcg._constraints).isEmpty();
    });
  });

  group('matchTypeParameterBoundInternal', () {
    test('Non-promoted parameter on LHS', () {
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationInternal(
              TypeParameterType(TypeRegistry.addTypeParameter('X')
                ..bound = Type('Future<String>')),
              Type('Future<T>'),
              leftSchema: false,
              astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).unorderedEquals(['String <: T']);
    });

    test('Promoted parameter on LHS', () {
      var tcg = _TypeConstraintGatherer({'T'});
      check(tcg.performSubtypeConstraintGenerationInternal(
              TypeParameterType(
                  TypeRegistry.addTypeParameter('X')..bound = Type('Object'),
                  promotion: Type('Future<num>')),
              Type('Future<T>'),
              leftSchema: false,
              astNodeForTesting: Node.placeholder()))
          .isTrue();
      check(tcg._constraints).unorderedEquals(['num <: T']);
    });
  });
}

class _TypeConstraintGatherer extends TypeConstraintGenerator<Type,
        NamedFunctionParameter, Var, TypeParameter, Type, String, Node>
    with
        TypeConstraintGeneratorMixin<Type, NamedFunctionParameter, Var,
            TypeParameter, Type, String, Node> {
  @override
  final Set<TypeParameter> typeParametersToConstrain = <TypeParameter>{};

  @override
  final bool enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr;

  @override
  final MiniAstOperations typeAnalyzerOperations = MiniAstOperations();

  final _constraints = <String>[];

  _TypeConstraintGatherer(Set<String> typeVariablesBeingConstrained,
      {this.enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr = false})
      : super(inferenceUsingBoundsIsEnabled: false) {
    for (var typeVariableName in typeVariablesBeingConstrained) {
      typeParametersToConstrain
          .add(TypeRegistry.addTypeParameter(typeVariableName));
    }
  }

  @override
  TypeConstraintGeneratorState get currentState =>
      TypeConstraintGeneratorState(_constraints.length);

  @override
  List<Type>? getTypeArgumentsAsInstanceOf(Type type, String typeDeclaration) {
    // We just have a few cases hardcoded here to make the tests work.
    // TODO(paulberry): if this gets too unwieldy, replace it with a more
    // general implementation.
    switch ((type, typeDeclaration)) {
      case (PrimaryType(name: 'List', :var args), 'Iterable'):
        // List<T> inherits from Iterable<T>
        return args;
      case (PrimaryType(name: 'MyListOfInt'), 'List'):
        // MyListOfInt inherits from List<int>
        return [Type('int')];
      case (PrimaryType(name: 'Future'), 'int'):
      case (PrimaryType(name: 'int'), 'String'):
      case (PrimaryType(name: 'List'), 'Future'):
      case (PrimaryType(name: 'String'), 'int'):
      case (PrimaryType(name: 'Future'), 'String'):
        // Unrelated types
        return null;
      default:
        throw UnimplementedError(
            'getTypeArgumentsAsInstanceOf($type, $typeDeclaration)');
    }
  }

  @override
  void restoreState(TypeConstraintGeneratorState state) {
    _constraints.length = state.count;
  }

  @override
  void addUpperConstraintForParameter(TypeParameter typeParameter, Type upper,
      {required Node? astNodeForTesting}) {
    _constraints.add('$typeParameter <: $upper');
  }

  @override
  void addLowerConstraintForParameter(TypeParameter typeParameter, Type lower,
      {required Node? astNodeForTesting}) {
    _constraints.add('$lower <: $typeParameter');
  }

  @override
  void eliminateTypeParametersInGeneratedConstraints(
      Object eliminator, TypeConstraintGeneratorState eliminationStartState,
      {required Node? astNodeForTesting}) {
    // TODO(paulberry): implement eliminateTypeParametersInGeneratedConstraints
  }

  @override
  (
    Type,
    Type, {
    List<TypeParameter> typeParametersToEliminate
  }) instantiateFunctionTypesAndProvideFreshTypeParameters(
      SharedFunctionTypeStructure<Type, TypeParameter, NamedFunctionParameter>
          p,
      SharedFunctionTypeStructure<Type, TypeParameter, NamedFunctionParameter>
          q,
      {required bool leftSchema}) {
    // TODO(paulberry): implement instantiateFunctionTypesAndProvideEliminator
    throw UnimplementedError();
  }
}
