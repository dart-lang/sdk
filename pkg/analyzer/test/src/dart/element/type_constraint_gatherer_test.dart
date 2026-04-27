// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeConstraintGathererTest);
  });
}

@reflectiveTest
class TypeConstraintGathererTest extends AbstractTypeSystemTest {
  /// If `P` and `Q` are identical types, then the subtype match holds
  /// under no constraints.
  test_equal_left_right() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        parseType('int'),
        parseType('int'),
        true,
        ['_ <: T <: _'],
      );

      _checkMatch(
        [T],
        parseFunctionType('void Function(int)'),
        parseFunctionType('void Function(int)'),
        true,
        ['_ <: T <: _'],
      );

      _checkMatch(
        [T],
        parseFunctionType('T1 Function<T1>()'),
        parseFunctionType('T2 Function<T2>()'),
        true,
        ['_ <: T <: _'],
      );
    });
  }

  test_functionType_hasTypeFormals() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        scope.parseType('T Function<T1>(T1)'),
        parseFunctionType('int Function<S1>(S1)'),
        false,
        ['_ <: T <: int'],
      );

      _checkMatch(
        [T],
        parseFunctionType('int Function<T1>(T1)'),
        scope.parseType('T Function<S1>(S1)'),
        true,
        ['int <: T <: _'],
      );

      // We unified type formals, but still not match because return types.
      _checkNotMatch(
        [T],
        parseFunctionType('int Function<T1>(T1)'),
        parseFunctionType('String Function<S1>(S1)'),
        false,
      );
    });
  }

  test_functionType_hasTypeFormals_bounds_different_subtype() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkNotMatch(
        [T],
        scope.parseType('T Function<T1>()'),
        parseFunctionType('int Function<S1 extends num>()'),
        false,
      );
    });
  }

  test_functionType_hasTypeFormals_bounds_different_top() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        scope.parseType('T Function<T1 extends void>()'),
        parseFunctionType('int Function<S1 extends dynamic>()'),
        false,
        ['_ <: T <: int'],
      );
    });
  }

  test_functionType_hasTypeFormals_bounds_different_unrelated() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkNotMatch(
        [T],
        scope.parseType('T Function<T1 extends int>()'),
        parseFunctionType('int Function<S1 extends String>()'),
        false,
      );
    });
  }

  test_functionType_hasTypeFormals_bounds_same_leftDefault_rightDefault() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        scope.parseType('T Function<T1>()'),
        parseFunctionType('int Function<S1>()'),
        false,
        ['_ <: T <: int'],
      );
    });
  }

  test_functionType_hasTypeFormals_bounds_same_leftDefault_rightObjectQ() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        scope.parseType('T Function<T1>()'),
        parseFunctionType('int Function<S1 extends Object?>()'),
        false,
        ['_ <: T <: int'],
      );
    });
  }

  @FailingTest(reason: 'Closure of type constraints is not implemented yet')
  test_functionType_hasTypeFormals_closure() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        scope.parseType('T Function<X>(X)'),
        parseFunctionType('List<Y> Function<Y>(Y)'),
        true,
        ['_ <: T <: List<Object?>'],
      );
    });
  }

  test_functionType_hasTypeFormals_differentCount() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkNotMatch(
        [T],
        scope.parseType('T Function<T1>()'),
        parseFunctionType('int Function<S1, S2>()'),
        false,
      );
    });
  }

  test_functionType_noTypeFormals_parameters_extraOptionalLeft() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        parseFunctionType('void Function([int])'),
        parseFunctionType('void Function()'),
        true,
        ['_ <: T <: _'],
      );

      _checkMatch(
        [T],
        parseFunctionType('void Function({int a})'),
        parseFunctionType('void Function()'),
        true,
        ['_ <: T <: _'],
      );
    });
  }

  test_functionType_noTypeFormals_parameters_extraRequiredLeft() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkNotMatch(
        [T],
        parseFunctionType('void Function(int)'),
        parseFunctionType('void Function()'),
        true,
      );

      _checkNotMatch(
        [T],
        parseFunctionType('void Function({required int a})'),
        parseFunctionType('void Function()'),
        true,
      );
    });
  }

  test_functionType_noTypeFormals_parameters_extraRight() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkNotMatch(
        [T],
        parseFunctionType('void Function()'),
        scope.parseType('void Function(T)'),
        true,
      );
    });
  }

  test_functionType_noTypeFormals_parameters_leftOptionalNamed() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        parseFunctionType('void Function({int a})'),
        scope.parseType('void Function({T a})'),
        true,
        ['_ <: T <: int'],
      );

      _checkMatch(
        [T],
        scope.parseType('void Function({T a})'),
        parseFunctionType('void Function({int a})'),
        false,
        ['int <: T <: _'],
      );

      // int vs. String
      _checkNotMatch(
        [T],
        parseFunctionType('void Function({int a})'),
        parseFunctionType('void Function({String a})'),
        true,
      );

      // Skip left non-required named.
      _checkMatch(
        [T],
        parseFunctionType('void Function({int a, int b, int c})'),
        scope.parseType('void Function({T b})'),
        true,
        ['_ <: T <: int'],
      );

      // Not match if skip left required named.
      _checkNotMatch(
        [T],
        parseFunctionType('void Function({required int a, int b})'),
        scope.parseType('void Function({T b})'),
        true,
      );

      // Not match if skip right named.
      _checkNotMatch(
        [T],
        parseFunctionType('void Function({int b})'),
        scope.parseType('void Function({int a, T b})'),
        true,
      );
    });
  }

  test_functionType_noTypeFormals_parameters_leftOptionalPositional() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        scope.parseType('void Function([int])'),
        scope.parseType('void Function(T)'),
        true,
        ['_ <: T <: int'],
      );

      _checkMatch(
        [T],
        scope.parseType('void Function([T])'),
        scope.parseType('void Function(int)'),
        false,
        ['int <: T <: _'],
      );
      _checkMatch(
        [T],
        scope.parseType('void Function([int])'),
        scope.parseType('void Function([T])'),
        true,
        ['_ <: T <: int'],
      );

      _checkMatch(
        [T],
        scope.parseType('void Function([T])'),
        scope.parseType('void Function([int])'),
        false,
        ['int <: T <: _'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('void Function([int])'),
        scope.parseType('void Function(String)'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('void Function([int])'),
        scope.parseType('void Function([String])'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('void Function([int])'),
        scope.parseType('void Function({int a})'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('void Function([int])'),
        scope.parseType('void Function({int a})'),
        false,
      );
    });
  }

  test_functionType_noTypeFormals_parameters_leftRequiredPositional() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        scope.parseType('void Function(int)'),
        scope.parseType('void Function(T)'),
        true,
        ['_ <: T <: int'],
      );

      _checkMatch(
        [T],
        scope.parseType('void Function(T)'),
        scope.parseType('void Function(int)'),
        false,
        ['int <: T <: _'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('void Function(int)'),
        scope.parseType('void Function(String)'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('void Function(int)'),
        scope.parseType('void Function([T])'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('void Function(int)'),
        scope.parseType('void Function({T a})'),
        true,
      );
    });
  }

  test_functionType_noTypeFormals_returnType() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        scope.parseType('T Function()'),
        parseFunctionType('int Function()'),
        false,
        ['_ <: T <: int'],
      );

      _checkNotMatch(
        [T],
        parseFunctionType('String Function()'),
        parseFunctionType('int Function()'),
        false,
      );
    });
  }

  /// If `P` is `C<M0, ..., Mk>` and `Q` is `C<N0, ..., Nk>`, then the match
  /// holds under constraints `C0 + ... + Ck`:
  ///   If `Mi` is a subtype match for `Ni` with respect to L under
  ///   constraints `Ci`.
  test_interfaceType_same() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        scope.parseType('List<T>'),
        parseType('List<num>'),
        false,
        ['_ <: T <: num'],
      );
      _checkMatch(
        [T],
        parseType('List<int>'),
        scope.parseType('List<T>'),
        true,
        ['int <: T <: _'],
      );

      _checkNotMatch(
        [T],
        parseType('List<int>'),
        parseType('List<String>'),
        false,
      );

      _checkMatch(
        [T],
        scope.parseType('Map<int, List<T>>'),
        parseType('Map<num, List<String>>'),
        false,
        ['_ <: T <: String'],
      );
      _checkMatch(
        [T],
        parseType('Map<int, List<String>>'),
        scope.parseType('Map<num, List<T>>'),
        true,
        ['String <: T <: _'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('Map<T, List<int>>'),
        parseType('Map<num, List<String>>'),
        false,
      );
    });
  }

  /// If `P` is `C0<M0, ..., Mk>` and `Q` is `C1<N0, ..., Nj>` then the match
  /// holds with respect to `L` under constraints `C`:
  ///   If `C1<B0, ..., Bj>` is a superinterface of `C0<M0, ..., Mk>` and
  ///   `C1<B0, ..., Bj>` is a subtype match for `C1<N0, ..., Nj>` with
  ///   respect to `L` under constraints `C`.
  test_interfaceType_superInterface() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        scope.parseType('List<T>'),
        parseType('Iterable<num>'),
        false,
        ['_ <: T <: num'],
      );
      _checkMatch(
        [T],
        parseType('List<int>'),
        scope.parseType('Iterable<T>'),
        true,
        ['int <: T <: _'],
      );

      _checkNotMatch(
        [T],
        parseType('List<int>'),
        parseType('Iterable<String>'),
        true,
      );
    });
  }

  void test_interfaceType_topMerge() {
    var testClassIndex = 0;

    void check1(
      String extendsTypeArgument,
      String implementsTypeArgument,
      String expectedConstraint,
    ) {
      buildTestLibrary(
        classes: [
          ClassSpec('class A<T>'),
          ClassSpec('class B<T> extends A<T>'),
          ClassSpec(
            'class ${'C$testClassIndex'} extends ${'A<$extendsTypeArgument>'} '
            'implements ${'B<$implementsTypeArgument>'}',
          ),
        ],
      );
      testClassIndex++;

      // class B<T> extends A<T> {}
      // class Cx extends A<> implements B<> {}
      var C = classElement('C${testClassIndex - 1}');

      withTypeParameterScope('T', (scope) {
        var T = scope.typeParameter('T');
        _checkMatch(
          [T],
          parseType(C.name!),
          scope.parseType('A<T>'),
          true,
          [expectedConstraint],
        );
      });
    }

    void check(
      String typeArgument1,
      String typeArgument2,
      String expectedConstraint,
    ) {
      check1(typeArgument1, typeArgument2, expectedConstraint);
      check1(typeArgument2, typeArgument1, expectedConstraint);
    }

    check('Object?', 'dynamic', 'Object? <: T <: _');
    check('void', 'Object?', 'Object? <: T <: _');
  }

  /// If `P` is `FutureOr<P0>` the match holds under constraint set `C1 + C2`:
  ///   If `Future<P0>` is a subtype match for `Q` under constraint set `C1`.
  ///   And if `P0` is a subtype match for `Q` under constraint set `C2`.
  test_left_futureOr() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        scope.parseType('FutureOr<T>'),
        parseType('FutureOr<int>'),
        false,
        ['_ <: T <: int'],
      );

      // This is 'T <: int' and 'T <: Future<int>'.
      _checkMatch(
        [T],
        scope.parseType('FutureOr<T>'),
        parseType('Future<int>'),
        false,
        ['_ <: T <: Never'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('FutureOr<T>'),
        parseType('int'),
        false,
      );
    });
  }

  /// If `P` is `Never` then the match holds under no constraints.
  test_left_never() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        parseType('Never'),
        parseType('int'),
        false,
        ['_ <: T <: _'],
      );
    });
  }

  /// If `P` is `Null`, then the match holds under no constraints:
  ///  Only if `Q` is nullable.
  test_left_null() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkNotMatch([T], parseType('Null'), parseType('int'), true);

      _checkMatch(
        [T],
        parseType('Null'),
        scope.parseType('T'),
        true,
        ['Null <: T <: _'],
      );

      _checkMatch(
        [T],
        parseType('Null'),
        scope.parseType('FutureOr<T>'),
        true,
        ['Null <: T <: _'],
      );

      void matchNoConstraints(TypeImpl Q) {
        _checkMatch([T], parseType('Null'), Q, true, ['_ <: T <: _']);
      }

      matchNoConstraints(scope.parseType('List<T>?'));
      matchNoConstraints(parseType('String?'));
      matchNoConstraints(parseType('void'));
      matchNoConstraints(parseType('dynamic'));
      matchNoConstraints(parseType('Object?'));
      matchNoConstraints(parseType('Null'));
      matchNoConstraints(parseFunctionType('void Function()?'));
    });
  }

  /// If `P` is `P0?` the match holds under constraint set `C1 + C2`:
  ///   If `P0` is a subtype match for `Q` under constraint set `C1`.
  ///   And if `Null` is a subtype match for `Q` under constraint set `C2`.
  test_left_suffixQuestion() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      // TODO(scheglov): any better test case?
      _checkMatch(
        [T],
        parseType('num?'),
        parseType('dynamic'),
        true,
        ['_ <: T <: _'],
      );

      _checkNotMatch([T], scope.parseType('T?'), parseType('int'), true);
    });
  }

  /// If `Q` is `Q0?` the match holds under constraint set `C`:
  ///   Or if `P` is `dynamic` or `void` and `Object` is a subtype match
  ///   for `Q0` under constraint set `C`.
  test_left_top_right_nullable() {
    withTypeParameterScope('U extends Object', (scope) {
      var U = scope.typeParameter('U');
      var U_question = scope.parseType('U?');

      _checkMatch(
        [U],
        parseType('dynamic'),
        U_question,
        false,
        ['Object <: U <: _'],
      );
      _checkMatch(
        [U],
        parseType('void'),
        U_question,
        false,
        ['Object <: U <: _'],
      );
    });
  }

  /// If `P` is a type variable `X` in `L`, then the match holds:
  ///   Under constraint `_ <: X <: Q`.
  test_left_typeParameter2() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      void checkMatch(TypeImpl right, String expected) {
        _checkMatch([T], scope.parseType('T'), right, false, [expected]);
      }

      checkMatch(parseType('num'), '_ <: T <: num');
      checkMatch(parseType('num?'), '_ <: T <: num?');
    });
  }

  /// If `P` is a type variable `X` with bound `B` (or a promoted type
  /// variable `X & B`), the match holds with constraint set `C`:
  ///   If `B` is a subtype match for `Q` with constraint set `C`.
  /// Note: we have already eliminated the case that `X` is a variable in `L`.
  test_left_typeParameterOther() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      scope.withTypeParameterScope('U extends int', (scope) {
        _checkMatch(
          [T],
          scope.parseType('U'),
          parseType('num'),
          false,
          ['_ <: T <: _'],
        );
      });

      scope.withTypeParameterScope('U', (scope) {
        _checkMatch(
          [T],
          scope.parseType('U & int'),
          parseType('num'),
          false,
          ['_ <: T <: _'],
        );

        _checkNotMatch([T], scope.parseType('U'), parseType('num'), false);
      });
    });
  }

  /// If `P` is `_` then the match holds with no constraints.
  test_left_unknown() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        parseType('UnknownInferredType'),
        parseType('num'),
        true,
        ['_ <: T <: _'],
      );
    });
  }

  test_recordType_differentShape() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkNotMatch(
        [T],
        scope.parseType('(T, int)'),
        scope.parseType('(int,)'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('(T,)'),
        scope.parseType('(int, int)'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('({T f1})'),
        scope.parseType('({int f2})'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('({T f1, int f2})'),
        scope.parseType('({int f1})'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('({T f1})'),
        scope.parseType('({int f1, int f2})'),
        true,
      );

      _checkNotMatch(
        [T],
        scope.parseType('(int, {T f2})'),
        scope.parseType('({int f1, int f2})'),
        true,
      );
    });
  }

  test_recordType_recordClass() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        scope.parseType('(T,)'),
        parseType('Record'),
        true,
        ['_ <: T <: _'],
      );
    });
  }

  test_recordType_sameShape_named() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        scope.parseType('({T f1})'),
        scope.parseType('({int f1})'),
        true,
        ['_ <: T <: int'],
      );

      _checkMatch(
        [T],
        scope.parseType('({int f1})'),
        scope.parseType('({T f1})'),
        false,
        ['int <: T <: _'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('({int f1})'),
        scope.parseType('({String f1})'),
        false,
      );

      _checkMatch(
        [T],
        scope.parseType('({int f1, T f2})'),
        scope.parseType('({num f1, String f2})'),
        true,
        ['_ <: T <: String'],
      );

      _checkMatch(
        [T],
        scope.parseType('({int f1, String f2})'),
        scope.parseType('({num f1, T f2})'),
        false,
        ['String <: T <: _'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('(T, int, {T f1, int f2})'),
        scope.parseType('({int f1, String f2})'),
        true,
      );
    });
  }

  test_recordType_sameShape_positional() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        scope.parseType('(T,)'),
        scope.parseType('(num,)'),
        true,
        ['_ <: T <: num'],
      );

      _checkMatch(
        [T],
        scope.parseType('(int,)'),
        scope.parseType('(T,)'),
        false,
        ['int <: T <: _'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('(int,)'),
        scope.parseType('(String,)'),
        false,
      );

      _checkMatch(
        [T],
        scope.parseType('(int, T)'),
        scope.parseType('(num, String)'),
        true,
        ['_ <: T <: String'],
      );

      _checkMatch(
        [T],
        scope.parseType('(int, String)'),
        scope.parseType('(num, T)'),
        false,
        ['String <: T <: _'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('(T, int)'),
        scope.parseType('(num, String)'),
        true,
      );
    });
  }

  test_right_functionClass() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        parseFunctionType('void Function()'),
        parseType('Function'),
        true,
        ['_ <: T <: _'],
      );
    });
  }

  /// If `Q` is `FutureOr<Q0>` the match holds under constraint set `C`:
  test_right_futureOr() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      // If `P` is `FutureOr<P0>` and `P0` is a subtype match for `Q0` under
      // constraint set `C`.
      _checkMatch(
        [T],
        scope.parseType('FutureOr<T>'),
        parseType('FutureOr<num>'),
        false,
        ['_ <: T <: num'],
      );
      _checkMatch(
        [T],
        parseType('FutureOr<num>'),
        scope.parseType('FutureOr<T>'),
        true,
        ['num <: T <: _'],
      );
      _checkNotMatch(
        [T],
        parseType('FutureOr<String>'),
        parseType('FutureOr<int>'),
        true,
      );

      // Or if `P` is a subtype match for `Future<Q0>` under non-empty
      // constraint set `C`.
      _checkMatch(
        [T],
        scope.parseType('Future<T>'),
        parseType('FutureOr<num>'),
        false,
        ['_ <: T <: num'],
      );
      _checkMatch(
        [T],
        parseType('Future<int>'),
        scope.parseType('FutureOr<T>'),
        true,
        ['int <: T <: _'],
      );
      _checkMatch(
        [T],
        parseType('Future<int>'),
        parseType('FutureOr<Object>'),
        true,
        ['_ <: T <: _'],
      );
      _checkNotMatch(
        [T],
        parseType('Future<String>'),
        parseType('FutureOr<int>'),
        true,
      );

      // Or if `P` is a subtype match for `Q0` under constraint set `C`.
      _checkMatch(
        [T],
        scope.parseType('List<T>'),
        parseType('FutureOr<List<int>>'),
        false,
        ['_ <: T <: int'],
      );
      _checkMatch(
        [T],
        parseType('Never'),
        scope.parseType('FutureOr<T>'),
        true,
        ['Never <: T <: _'],
      );

      // Or if `P` is a subtype match for `Future<Q0>` under empty
      // constraint set `C`.
      _checkMatch(
        [T],
        parseType('Future<int>'),
        parseType('FutureOr<num>'),
        false,
        ['_ <: T <: _'],
      );

      // Otherwise.
      _checkNotMatch(
        [T],
        scope.parseType('List<T>'),
        parseType('FutureOr<int>'),
        false,
      );
    });
  }

  /// If `Q` is `Object`, then the match holds under no constraints:
  ///  Only if `P` is non-nullable.
  test_right_object() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        [T],
        parseType('int'),
        parseType('Object'),
        false,
        ['_ <: T <: _'],
      );
      _checkNotMatch([T], parseType('int?'), parseType('Object'), false);

      _checkNotMatch([T], parseType('dynamic'), parseType('Object'), false);

      scope.withTypeParameterScope('U extends num?', (scope) {
        _checkNotMatch([T], scope.parseType('U'), parseType('Object'), false);
      });
    });
  }

  /// If `Q` is `Q0?` the match holds under constraint set `C`:
  test_right_suffixQuestion() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      var T_question = scope.parseType('T?');

      // If `P` is `P0?` and `P0` is a subtype match for `Q0` under
      // constraint set `C`.
      _checkMatch([T], T_question, parseType('num?'), false, ['_ <: T <: num']);
      _checkMatch([T], parseType('int?'), T_question, true, ['int <: T <: _']);

      // Or if `P` is a subtype match for `Q0` under non-empty
      // constraint set `C`.
      _checkMatch([T], parseType('int'), T_question, false, ['int <: T <: _']);

      // Or if `P` is a subtype match for `Null` under constraint set `C`.
      _checkMatch(
        [T],
        parseType('Null'),
        parseType('int?'),
        true,
        ['_ <: T <: _'],
      );

      // Or if `P` is a subtype match for `Q0` under empty
      // constraint set `C`.
      _checkMatch(
        [T],
        parseType('int'),
        parseType('int?'),
        true,
        ['_ <: T <: _'],
      );

      _checkNotMatch([T], parseType('int'), parseType('String?'), true);
      _checkNotMatch([T], parseType('int?'), parseType('String?'), true);
    });
  }

  /// If `Q` is `dynamic`, `Object?`, or `void` then the match holds under
  /// no constraints.
  test_right_top() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        parseType('int'),
        parseType('dynamic'),
        false,
        ['_ <: T <: _'],
      );
      _checkMatch(
        [T],
        parseType('int'),
        parseType('Object?'),
        false,
        ['_ <: T <: _'],
      );
      _checkMatch(
        [T],
        parseType('int'),
        parseType('void'),
        false,
        ['_ <: T <: _'],
      );
    });
  }

  /// If `Q` is a type variable `X` in `L`, then the match holds:
  ///   Under constraint `P <: X <: _`.
  test_right_typeParameter2() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      void checkMatch(TypeImpl left, String expected) {
        _checkMatch([T], left, scope.parseType('T'), true, [expected]);
      }

      checkMatch(parseType('num'), 'num <: T <: _');
      checkMatch(parseType('num?'), 'num? <: T <: _');
    });
  }

  /// If `Q` is `_` then the match holds with no constraints.
  test_right_unknown() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        [T],
        parseType('num'),
        parseType('UnknownInferredType'),
        true,
        ['_ <: T <: _'],
      );
      _checkMatch(
        [T],
        parseType('num'),
        parseType('UnknownInferredType'),
        true,
        ['_ <: T <: _'],
      );
    });
  }

  void _checkMatch(
    List<TypeParameterElementImpl> typeParameters,
    TypeImpl P,
    TypeImpl Q,
    bool leftSchema,
    List<String> expected,
  ) {
    var gatherer = TypeConstraintGatherer(
      typeParameters: typeParameters,
      typeSystemOperations: TypeSystemOperations(
        typeSystem,
        strictCasts: false,
      ),
      inferenceUsingBoundsIsEnabled: false,
      dataForTesting: null,
    );

    var isMatch = gatherer.performSubtypeConstraintGenerationInternal(
      P,
      Q,
      leftSchema: leftSchema,
      astNodeForTesting: null,
    );
    expect(isMatch, isTrue);

    var constraints = gatherer.computeConstraints();
    var constraintsStr = constraints.entries.map((e) {
      var lowerStr = e.value.lower.getDisplayString();
      var upperStr = e.value.upper.getDisplayString();
      return '$lowerStr <: ${e.key.name} <: $upperStr';
    }).toList();

    expect(constraintsStr, unorderedEquals(expected));
  }

  void _checkNotMatch(
    List<TypeParameterElementImpl> typeParameters,
    TypeImpl P,
    TypeImpl Q,
    bool leftSchema,
  ) {
    var gatherer = TypeConstraintGatherer(
      typeParameters: typeParameters,
      typeSystemOperations: TypeSystemOperations(
        typeSystem,
        strictCasts: false,
      ),
      inferenceUsingBoundsIsEnabled: false,
      dataForTesting: null,
    );

    var isMatch = gatherer.performSubtypeConstraintGenerationInternal(
      P,
      Q,
      leftSchema: leftSchema,
      astNodeForTesting: null,
    );
    expect(isMatch, isFalse);
    expect(gatherer.isConstraintSetEmpty, isTrue);
  }
}
