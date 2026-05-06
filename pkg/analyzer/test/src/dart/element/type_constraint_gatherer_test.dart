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
        typeParameters: [T],
        P: parseType('int'),
        Q: parseType('int'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
      );

      _checkMatch(
        typeParameters: [T],
        P: parseFunctionType('void Function(int)'),
        Q: parseFunctionType('void Function(int)'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
      );

      _checkMatch(
        typeParameters: [T],
        P: parseFunctionType('T1 Function<T1>()'),
        Q: parseFunctionType('T2 Function<T2>()'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
      );
    });
  }

  test_functionType_hasTypeFormals() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('T Function<T1>(T1)'),
        Q: parseFunctionType('int Function<S1>(S1)'),
        leftSchema: false,
        expected: ['_ <: T <: int'],
      );

      _checkMatch(
        typeParameters: [T],
        P: parseFunctionType('int Function<T1>(T1)'),
        Q: scope.parseType('T Function<S1>(S1)'),
        leftSchema: true,
        expected: ['int <: T <: _'],
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
        typeParameters: [T],
        P: scope.parseType('T Function<T1 extends void>()'),
        Q: parseFunctionType('int Function<S1 extends dynamic>()'),
        leftSchema: false,
        expected: ['_ <: T <: int'],
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
        typeParameters: [T],
        P: scope.parseType('T Function<T1>()'),
        Q: parseFunctionType('int Function<S1>()'),
        leftSchema: false,
        expected: ['_ <: T <: int'],
      );
    });
  }

  test_functionType_hasTypeFormals_bounds_same_leftDefault_rightObjectQ() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('T Function<T1>()'),
        Q: parseFunctionType('int Function<S1 extends Object?>()'),
        leftSchema: false,
        expected: ['_ <: T <: int'],
      );
    });
  }

  @FailingTest(reason: 'Closure of type constraints is not implemented yet')
  test_functionType_hasTypeFormals_closure() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('T Function<X>(X)'),
        Q: parseFunctionType('List<Y> Function<Y>(Y)'),
        leftSchema: true,
        expected: ['_ <: T <: List<Object?>'],
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
        typeParameters: [T],
        P: parseFunctionType('void Function([int])'),
        Q: parseFunctionType('void Function()'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
      );

      _checkMatch(
        typeParameters: [T],
        P: parseFunctionType('void Function({int a})'),
        Q: parseFunctionType('void Function()'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
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
        typeParameters: [T],
        P: parseFunctionType('void Function({int a})'),
        Q: scope.parseType('void Function({T a})'),
        leftSchema: true,
        expected: ['_ <: T <: int'],
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('void Function({T a})'),
        Q: parseFunctionType('void Function({int a})'),
        leftSchema: false,
        expected: ['int <: T <: _'],
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
        typeParameters: [T],
        P: parseFunctionType('void Function({int a, int b, int c})'),
        Q: scope.parseType('void Function({T b})'),
        leftSchema: true,
        expected: ['_ <: T <: int'],
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
        typeParameters: [T],
        P: scope.parseType('void Function([int])'),
        Q: scope.parseType('void Function(T)'),
        leftSchema: true,
        expected: ['_ <: T <: int'],
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('void Function([T])'),
        Q: scope.parseType('void Function(int)'),
        leftSchema: false,
        expected: ['int <: T <: _'],
      );
      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('void Function([int])'),
        Q: scope.parseType('void Function([T])'),
        leftSchema: true,
        expected: ['_ <: T <: int'],
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('void Function([T])'),
        Q: scope.parseType('void Function([int])'),
        leftSchema: false,
        expected: ['int <: T <: _'],
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
        typeParameters: [T],
        P: scope.parseType('void Function(int)'),
        Q: scope.parseType('void Function(T)'),
        leftSchema: true,
        expected: ['_ <: T <: int'],
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('void Function(T)'),
        Q: scope.parseType('void Function(int)'),
        leftSchema: false,
        expected: ['int <: T <: _'],
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
        typeParameters: [T],
        P: scope.parseType('T Function()'),
        Q: parseFunctionType('int Function()'),
        leftSchema: false,
        expected: ['_ <: T <: int'],
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
        typeParameters: [T],
        P: scope.parseType('List<T>'),
        Q: parseType('List<num>'),
        leftSchema: false,
        expected: ['_ <: T <: num'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('List<int>'),
        Q: scope.parseType('List<T>'),
        leftSchema: true,
        expected: ['int <: T <: _'],
      );

      _checkNotMatch(
        [T],
        parseType('List<int>'),
        parseType('List<String>'),
        false,
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('Map<int, List<T>>'),
        Q: parseType('Map<num, List<String>>'),
        leftSchema: false,
        expected: ['_ <: T <: String'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('Map<int, List<String>>'),
        Q: scope.parseType('Map<num, List<T>>'),
        leftSchema: true,
        expected: ['String <: T <: _'],
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
        typeParameters: [T],
        P: scope.parseType('List<T>'),
        Q: parseType('Iterable<num>'),
        leftSchema: false,
        expected: ['_ <: T <: num'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('List<int>'),
        Q: scope.parseType('Iterable<T>'),
        leftSchema: true,
        expected: ['int <: T <: _'],
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
    var classes = <ClassSpec>[];

    void addClasses(
      int index,
      String extendsTypeArgument,
      String implementsTypeArgument,
    ) {
      classes.addAll([
        ClassSpec('class A$index<T>'),
        ClassSpec('class B$index<T> extends A$index<T>'),
        ClassSpec(
          'class C$index extends A$index<$extendsTypeArgument> '
          'implements B$index<$implementsTypeArgument>',
        ),
      ]);
    }

    addClasses(0, 'Object?', 'dynamic');
    addClasses(1, 'dynamic', 'Object?');
    addClasses(2, 'void', 'Object?');
    addClasses(3, 'Object?', 'void');

    buildTestLibrary(classes: classes);

    void checkMatch(int index, String expectedConstraint) {
      withTypeParameterScope('T', (scope) {
        var T = scope.typeParameter('T');
        _checkMatch(
          typeParameters: [T],
          P: parseType('C$index'),
          Q: scope.parseType('A$index<T>'),
          leftSchema: true,
          expected: [expectedConstraint],
        );
      });
    }

    checkMatch(0, 'Object? <: T <: _');
    checkMatch(1, 'Object? <: T <: _');
    checkMatch(2, 'Object? <: T <: _');
    checkMatch(3, 'Object? <: T <: _');
  }

  /// If `P` is `FutureOr<P0>` the match holds under constraint set `C1 + C2`:
  ///   If `Future<P0>` is a subtype match for `Q` under constraint set `C1`.
  ///   And if `P0` is a subtype match for `Q` under constraint set `C2`.
  test_left_futureOr() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('FutureOr<T>'),
        Q: parseType('FutureOr<int>'),
        leftSchema: false,
        expected: ['_ <: T <: int'],
      );

      // This is 'T <: int' and 'T <: Future<int>'.
      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('FutureOr<T>'),
        Q: parseType('Future<int>'),
        leftSchema: false,
        expected: ['_ <: T <: Never'],
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
        typeParameters: [T],
        P: parseType('Never'),
        Q: parseType('int'),
        leftSchema: false,
        expected: ['_ <: T <: _'],
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
        typeParameters: [T],
        P: parseType('Null'),
        Q: scope.parseType('T'),
        leftSchema: true,
        expected: ['Null <: T <: _'],
      );

      _checkMatch(
        typeParameters: [T],
        P: parseType('Null'),
        Q: scope.parseType('FutureOr<T>'),
        leftSchema: true,
        expected: ['Null <: T <: _'],
      );

      void matchNoConstraints(TypeImpl Q) {
        _checkMatch(
          typeParameters: [T],
          P: parseType('Null'),
          Q: Q,
          leftSchema: true,
          expected: ['_ <: T <: _'],
        );
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
        typeParameters: [T],
        P: parseType('num?'),
        Q: parseType('dynamic'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
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
        typeParameters: [U],
        P: parseType('dynamic'),
        Q: U_question,
        leftSchema: false,
        expected: ['Object <: U <: _'],
      );
      _checkMatch(
        typeParameters: [U],
        P: parseType('void'),
        Q: U_question,
        leftSchema: false,
        expected: ['Object <: U <: _'],
      );
    });
  }

  /// If `P` is a type variable `X` in `L`, then the match holds:
  ///   Under constraint `_ <: X <: Q`.
  test_left_typeParameter2() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      void checkMatch(TypeImpl right, String expected) {
        _checkMatch(
          typeParameters: [T],
          P: scope.parseType('T'),
          Q: right,
          leftSchema: false,
          expected: [expected],
        );
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
          typeParameters: [T],
          P: scope.parseType('U'),
          Q: parseType('num'),
          leftSchema: false,
          expected: ['_ <: T <: _'],
        );
      });

      scope.withTypeParameterScope('U', (scope) {
        _checkMatch(
          typeParameters: [T],
          P: scope.parseType('U & int'),
          Q: parseType('num'),
          leftSchema: false,
          expected: ['_ <: T <: _'],
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
        typeParameters: [T],
        P: parseType('UnknownInferredType'),
        Q: parseType('num'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
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
        typeParameters: [T],
        P: scope.parseType('(T,)'),
        Q: parseType('Record'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
      );
    });
  }

  test_recordType_sameShape_named() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('({T f1})'),
        Q: scope.parseType('({int f1})'),
        leftSchema: true,
        expected: ['_ <: T <: int'],
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('({int f1})'),
        Q: scope.parseType('({T f1})'),
        leftSchema: false,
        expected: ['int <: T <: _'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('({int f1})'),
        scope.parseType('({String f1})'),
        false,
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('({int f1, T f2})'),
        Q: scope.parseType('({num f1, String f2})'),
        leftSchema: true,
        expected: ['_ <: T <: String'],
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('({int f1, String f2})'),
        Q: scope.parseType('({num f1, T f2})'),
        leftSchema: false,
        expected: ['String <: T <: _'],
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
        typeParameters: [T],
        P: scope.parseType('(T,)'),
        Q: scope.parseType('(num,)'),
        leftSchema: true,
        expected: ['_ <: T <: num'],
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('(int,)'),
        Q: scope.parseType('(T,)'),
        leftSchema: false,
        expected: ['int <: T <: _'],
      );

      _checkNotMatch(
        [T],
        scope.parseType('(int,)'),
        scope.parseType('(String,)'),
        false,
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('(int, T)'),
        Q: scope.parseType('(num, String)'),
        leftSchema: true,
        expected: ['_ <: T <: String'],
      );

      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('(int, String)'),
        Q: scope.parseType('(num, T)'),
        leftSchema: false,
        expected: ['String <: T <: _'],
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
        typeParameters: [T],
        P: parseFunctionType('void Function()'),
        Q: parseType('Function'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
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
        typeParameters: [T],
        P: scope.parseType('FutureOr<T>'),
        Q: parseType('FutureOr<num>'),
        leftSchema: false,
        expected: ['_ <: T <: num'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('FutureOr<num>'),
        Q: scope.parseType('FutureOr<T>'),
        leftSchema: true,
        expected: ['num <: T <: _'],
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
        typeParameters: [T],
        P: scope.parseType('Future<T>'),
        Q: parseType('FutureOr<num>'),
        leftSchema: false,
        expected: ['_ <: T <: num'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('Future<int>'),
        Q: scope.parseType('FutureOr<T>'),
        leftSchema: true,
        expected: ['int <: T <: _'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('Future<int>'),
        Q: parseType('FutureOr<Object>'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
      );
      _checkNotMatch(
        [T],
        parseType('Future<String>'),
        parseType('FutureOr<int>'),
        true,
      );

      // Or if `P` is a subtype match for `Q0` under constraint set `C`.
      _checkMatch(
        typeParameters: [T],
        P: scope.parseType('List<T>'),
        Q: parseType('FutureOr<List<int>>'),
        leftSchema: false,
        expected: ['_ <: T <: int'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('Never'),
        Q: scope.parseType('FutureOr<T>'),
        leftSchema: true,
        expected: ['Never <: T <: _'],
      );

      // Or if `P` is a subtype match for `Future<Q0>` under empty
      // constraint set `C`.
      _checkMatch(
        typeParameters: [T],
        P: parseType('Future<int>'),
        Q: parseType('FutureOr<num>'),
        leftSchema: false,
        expected: ['_ <: T <: _'],
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
        typeParameters: [T],
        P: parseType('int'),
        Q: parseType('Object'),
        leftSchema: false,
        expected: ['_ <: T <: _'],
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
      _checkMatch(
        typeParameters: [T],
        P: T_question,
        Q: parseType('num?'),
        leftSchema: false,
        expected: ['_ <: T <: num'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('int?'),
        Q: T_question,
        leftSchema: true,
        expected: ['int <: T <: _'],
      );

      // Or if `P` is a subtype match for `Q0` under non-empty
      // constraint set `C`.
      _checkMatch(
        typeParameters: [T],
        P: parseType('int'),
        Q: T_question,
        leftSchema: false,
        expected: ['int <: T <: _'],
      );

      // Or if `P` is a subtype match for `Null` under constraint set `C`.
      _checkMatch(
        typeParameters: [T],
        P: parseType('Null'),
        Q: parseType('int?'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
      );

      // Or if `P` is a subtype match for `Q0` under empty
      // constraint set `C`.
      _checkMatch(
        typeParameters: [T],
        P: parseType('int'),
        Q: parseType('int?'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
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
        typeParameters: [T],
        P: parseType('int'),
        Q: parseType('dynamic'),
        leftSchema: false,
        expected: ['_ <: T <: _'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('int'),
        Q: parseType('Object?'),
        leftSchema: false,
        expected: ['_ <: T <: _'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('int'),
        Q: parseType('void'),
        leftSchema: false,
        expected: ['_ <: T <: _'],
      );
    });
  }

  /// If `Q` is a type variable `X` in `L`, then the match holds:
  ///   Under constraint `P <: X <: _`.
  test_right_typeParameter2() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      void checkMatch(TypeImpl left, String expected) {
        _checkMatch(
          typeParameters: [T],
          P: left,
          Q: scope.parseType('T'),
          leftSchema: true,
          expected: [expected],
        );
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
        typeParameters: [T],
        P: parseType('num'),
        Q: parseType('UnknownInferredType'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
      );
      _checkMatch(
        typeParameters: [T],
        P: parseType('num'),
        Q: parseType('UnknownInferredType'),
        leftSchema: true,
        expected: ['_ <: T <: _'],
      );
    });
  }

  void _checkMatch({
    required List<TypeParameterElementImpl> typeParameters,
    required TypeImpl P,
    required TypeImpl Q,
    required bool leftSchema,
    required List<String> expected,
  }) {
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
