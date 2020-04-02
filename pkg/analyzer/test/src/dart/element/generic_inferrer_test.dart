// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' show toUri;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstraintMatchingTest);
    defineReflectiveTests(GenericFunctionInferenceTest);
  });
}

@reflectiveTest
class ConstraintMatchingTest extends AbstractTypeSystemNullSafetyTest {
  TypeParameterElement T;
  TypeParameterType T_none;

  @override
  void setUp() {
    super.setUp();
    T = typeParameter('T');
    T_none = typeParameterTypeNone(T);
  }

  void test_function_coreFunction() {
    _checkOrdinarySubtypeMatch(
      functionTypeNone(
        returnType: voidNone,
      ),
      typeProvider.functionType,
      [T],
      covariant: true,
    );
  }

  void test_function_parameters_requiredPositional() {
    _checkIsSubtypeMatchOf(
      functionTypeNone(
        parameters: [
          requiredParameter(type: T_none),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: stringNone),
        ],
        returnType: intNone,
      ),
      [T],
      ['String <: T'],
      covariant: true,
    );
  }

  void test_function_returnType() {
    _checkIsSubtypeMatchOf(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: T_none,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: stringNone,
      ),
      [T],
      ['T <: String'],
      covariant: true,
    );
  }

  /// Left FutureOr: if `T0` is `FutureOr<S0>` then:
  /// * `T0 <: T1` iff `Future<S0> <: T1` and `S0 <: T1`
  void test_futureOr_left() {
    _checkIsSubtypeMatchOf(
      futureOrNone(T_none),
      futureOrNone(stringNone),
      [T],
      ['T <: String'],
      covariant: true,
    );

    _checkIsSubtypeMatchOf(
      futureOrNone(T_none),
      futureNone(stringNone),
      [T],
      ['T <: String', 'T <: Future<String>'],
      covariant: true,
    );

    // Future<List<T>> <: List<String> can't be satisfied
    _checkIsNotSubtypeMatchOf(
      futureOrNone(listNone(T_none)),
      listNone(stringNone),
      [T],
      covariant: true,
    );

    // List<T> <: Future<List<String>> can't be satisfied
    _checkIsNotSubtypeMatchOf(
      futureOrNone(listNone(T_none)),
      futureNone(listNone(stringNone)),
      [T],
      covariant: true,
    );
  }

  void test_futureOr_right_both_noConstraints() {
    // `Future<String> <: Future<Object>` can be satisfied:
    //    * no constraints
    //
    // `Future<String> <: Object` can be satisfied:
    //    * no constraints
    _checkIsSubtypeMatchOf(
      futureNone(stringNone),
      futureOrNone(objectNone),
      [T],
      [],
      covariant: true,
    );
  }

  void test_futureOr_right_both_prefer_future() {
    // `Future<String> <: Future<T>` can be satisfied:
    //    * `String <: T`
    //
    // `Future<String> <: T` can be satisfied:
    //    * `Future<String> <: T`
    //
    // We prefer `String <: T`.
    _checkIsSubtypeMatchOf(
      futureNone(stringNone),
      futureOrNone(T_none),
      [T],
      ['String <: T'],
      covariant: false,
    );

    // `Future<T> <: Future<Object>` can be satisfied:
    //   * `T <: Object`
    //
    // `Future<T> <: Object` can be satisfied:
    //   * no constraints
    //
    // We prefer `T <: Object`.
    _checkIsSubtypeMatchOf(
      futureNone(T_none),
      futureOrNone(objectNone),
      [T],
      ['T <: Object'],
      covariant: true,
    );
  }

  /// Right FutureOr: if `T1` is `FutureOr<S1>` then:
  /// `T0 <: T1` iff any of the following hold:
  /// * either `T0 <: Future<S1>`
  /// * or `T0 <: S1`
  void test_futureOr_right_none() {
    // `List<T> <: Future<String>` cannot be satisfied.
    // `List<T> <: int` cannot be satisfied.
    _checkIsNotSubtypeMatchOf(
      listNone(T_none),
      futureOrNone(stringNone),
      [T],
      covariant: true,
    );
  }

  void test_futureOr_right_single_future() {
    // `Future<T> <: Future<String>` can be satisfied:
    //    * `T <: String`
    //
    // `Future<T> <: String` cannot be satisfied.
    _checkIsSubtypeMatchOf(
      futureNone(T_none),
      futureOrNone(stringNone),
      [T],
      ['T <: String'],
      covariant: true,
    );
  }

  void test_futureOr_right_single_nonFuture() {
    // `List<T> <: Future<List<String>>` cannot be satisfied.
    //
    // `List<T> <: List<String>` can be satisfied:
    //    * `T <: String`
    _checkIsSubtypeMatchOf(
      listNone(T_none),
      futureOrNone(listNone(stringNone)),
      [T],
      ['T <: String'],
      covariant: true,
    );
  }

  void test_futureOr_right_single_nonFuture_null() {
    // `Null <: Future<T>` can be satisfied:
    //    * no constraints
    //
    // `Null <: T` can be satisfied:
    //    * `Null <: T`
    //
    // We prefer `Null <: T`.
    _checkIsSubtypeMatchOf(
      nullNone,
      futureOrNone(T_none),
      [T],
      ['Null <: T'],
      covariant: false,
    );
  }

  void test_interfaceType_interface_left() {
    _checkIsNotSubtypeMatchOf(
      iterableNone(T_none),
      listNone(stringNone),
      [T],
      covariant: true,
    );
  }

  void test_interfaceType_interface_right() {
    _checkIsSubtypeMatchOf(
      listNone(T_none),
      iterableNone(stringNone),
      [T],
      ['T <: String'],
      covariant: true,
    );
  }

  void test_interfaceType_sameClass() {
    _checkIsSubtypeMatchOf(
      listNone(T_none),
      listNone(stringNone),
      [T],
      ['T <: String'],
      covariant: true,
    );
  }

  void test_left_null() {
    // Null <: T is trivially satisfied by the constraint Null <: T.
    _checkIsSubtypeMatchOf(nullNone, T_none, [T], ['Null <: T'],
        covariant: false);

    // For any other type X, Null <: X is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(nullNone, listQuestion(T_none), [T],
        covariant: false);
    _checkOrdinarySubtypeMatch(nullNone, stringQuestion, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullNone, voidNone, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullNone, dynamicNone, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullNone, objectQuestion, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullNone, nullNone, [T], covariant: false);
    _checkOrdinarySubtypeMatch(
      nullNone,
      functionTypeQuestion(returnType: voidNone),
      [T],
      covariant: false,
    );
  }

  void test_right_dynamic() {
    // T <: dynamic is trivially satisfied by the constraint T <: dynamic.
    _checkIsSubtypeMatchOf(T_none, dynamicNone, [T], ['T <: dynamic'],
        covariant: true);

    // For any other type X, X <: dynamic is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(listNone(T_none), dynamicNone, [T],
        covariant: true);
    _checkOrdinarySubtypeMatch(stringNone, dynamicNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidNone, dynamicNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicNone, dynamicNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectNone, dynamicNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullNone, dynamicNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: stringNone,
      ),
      dynamicNone,
      [T],
      covariant: true,
    );
  }

  void test_right_object() {
    // T <: Object is trivially satisfied by the constraint T <: Object.
    _checkIsSubtypeMatchOf(T_none, objectNone, [T], ['T <: Object'],
        covariant: true);

    // For any other type X, X <: Object is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(listNone(T_none), objectNone, [T],
        covariant: true);
    _checkOrdinarySubtypeMatch(stringNone, objectNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidNone, objectNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicNone, objectNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectNone, objectNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullNone, objectNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: stringNone,
      ),
      objectNone,
      [T],
      covariant: true,
    );
  }

  void test_right_void() {
    // T <: void is trivially satisfied by the constraint T <: void.
    _checkIsSubtypeMatchOf(T_none, voidNone, [T], ['T <: void'],
        covariant: true);

    // For any other type X, X <: void is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(listNone(T_none), voidNone, [T],
        covariant: true);
    _checkOrdinarySubtypeMatch(stringNone, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidNone, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicNone, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectNone, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullNone, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: stringNone,
      ),
      voidNone,
      [T],
      covariant: true,
    );
  }

  void test_typeParameter_left_covariant() {
    // When doing a covariant match, the type parameters we're trying to find
    // types for are on the left hand side.
    _checkIsSubtypeMatchOf(T_none, stringNone, [T], ['T <: String'],
        covariant: true);
  }

  void test_typeParameter_left_covariant_match() {
    // When doing a covariant match, the type parameters we're trying to find
    // types for are on the left hand side.  If a type parameter appears on the
    // right hand side, there is a condition in which the constraint can be
    // satisfied: where both parameters appear at corresponding locations in the
    // type tree.
    //
    // In other words, T <: S can be satisfied trivially by the constraint
    // T <: S.
    var S = typeParameter('S');
    var S_none = typeParameterTypeNone(S);
    _checkIsSubtypeMatchOf(T_none, S_none, [T], ['T <: S'], covariant: true);
  }

  void test_typeParameter_left_covariant_no_match() {
    // When doing a covariant match, the type parameters we're trying to find
    // types for are on the left hand side.  If a type parameter appears on the
    // right hand side, it's probable that the constraint can't be satisfied,
    // because there is no possible type for the LHS (other than bottom)
    // that's guaranteed to satisfy the relation for all possible assignments of
    // the RHS type parameter.
    //
    // In other words, no match can be found for List<T> <: S because regardless
    // of T, we can't guarantee that List<T> <: S for all S.
    var S = typeParameter('S');
    var S_none = typeParameterTypeNone(S);
    _checkIsNotSubtypeMatchOf(listNone(T_none), S_none, [T], covariant: true);
  }

  void test_typeParameter_right_contravariant() {
    // When doing a contravariant match, the type parameters we're trying to
    // find types for are on the right hand side.
    _checkIsSubtypeMatchOf(stringNone, T_none, [T], ['String <: T'],
        covariant: false);
  }

  void test_typeParameter_right_contravariant_direct() {
    // When doing a contravariant match, the type parameters we're trying to
    // find types for are on the right hand side.  If a type parameter also
    // appears on the left hand side, there is a condition in which the
    // constraint can be satisfied without consulting the bound of the LHS type
    // parameter: the condition where both parameters appear at corresponding
    // locations in the type tree.
    //
    // In other words, List<S> <: List<T> is satisfied provided that
    // S <: T.
    var S = typeParameter('S');
    var S_none = typeParameterTypeNone(S);
    _checkIsSubtypeMatchOf(listNone(S_none), listNone(T_none), [T], ['S <: T'],
        covariant: false);
  }

  void test_typeParameter_right_contravariant_via_bound() {
    // When doing a contravariant match, the type parameters we're trying to
    // find types for are on the right hand side.  If a type parameter also
    // appears on the left hand side, we may have to constrain the RHS type
    // parameter using the bounds of the LHS type parameter.
    //
    // In other words, S <: List<T> is satisfied provided that
    // bound(S) <: List<T>.
    var S = typeParameter('S', bound: listNone(stringNone));
    var S_none = typeParameterTypeNone(S);
    _checkIsSubtypeMatchOf(S_none, listNone(T_none), [T], ['String <: T'],
        covariant: false);
  }

  void test_variance_contravariant() {
    // class A<in T>
    var T = typeParameter('T', variance: Variance.contravariant);
    var T_none = typeParameterTypeNone(T);
    var A = class_(name: 'A', typeParameters: [T]);

    _checkIsSubtypeMatchOf(
      interfaceTypeNone(A, typeArguments: [T_none]),
      interfaceTypeNone(A, typeArguments: [numNone]),
      [T],
      ['num <: in T'],
      covariant: true,
    );
  }

  void test_variance_covariant() {
    // class A<out T>
    var T = typeParameter('T', variance: Variance.covariant);
    var T_none = typeParameterTypeNone(T);
    var A = class_(name: 'A', typeParameters: [T]);

    _checkIsSubtypeMatchOf(
      interfaceTypeNone(A, typeArguments: [T_none]),
      interfaceTypeNone(A, typeArguments: [numNone]),
      [T],
      ['out T <: num'],
      covariant: true,
    );
  }

  void test_variance_invariant() {
    // class A<inout T>
    var T = typeParameter('T', variance: Variance.invariant);
    var T_none = typeParameterTypeNone(T);
    var A = class_(name: 'A', typeParameters: [T]);

    _checkIsSubtypeMatchOf(
      interfaceTypeNone(A, typeArguments: [T_none]),
      interfaceTypeNone(A, typeArguments: [numNone]),
      [T],
      ['inout T <: num', 'num <: inout T'],
      covariant: true,
    );
  }

  void _checkIsNotSubtypeMatchOf(
    DartType subtype,
    DartType supertype,
    List<TypeParameterElement> typeFormals, {
    @required bool covariant,
  }) {
    var inferrer = GenericInferrer(typeSystem, typeFormals);

    var success = inferrer.tryMatchSubtypeOf(subtype, supertype, null,
        covariant: covariant);
    expect(success, isFalse);

    inferrer.constraints.forEach((typeParameter, constraints) {
      expect(constraints, isEmpty);
    });
  }

  void _checkIsSubtypeMatchOf(
    DartType subtype,
    DartType supertype,
    List<TypeParameterElement> typeFormals,
    Iterable<String> expectedConstraints, {
    @required bool covariant,
  }) {
    var inferrer = GenericInferrer(typeSystem, typeFormals);

    var success = inferrer.tryMatchSubtypeOf(subtype, supertype, null,
        covariant: covariant);
    expect(success, isTrue);

    var formattedConstraints = <String>[];
    inferrer.constraints.forEach((typeParameter, constraints) {
      for (var constraint in constraints) {
        formattedConstraints.add(
          constraint.format(
            typeParameter.getDisplayString(withNullability: true),
            withNullability: true,
          ),
        );
      }
    });
    expect(formattedConstraints, unorderedEquals(expectedConstraints));
  }

  void _checkOrdinarySubtypeMatch(
    DartType subtype,
    DartType supertype,
    List<TypeParameterElement> typeFormals, {
    @required bool covariant,
  }) {
    var expectSuccess = typeSystem.isSubtypeOf(subtype, supertype);
    if (expectSuccess) {
      _checkIsSubtypeMatchOf(subtype, supertype, typeFormals, [],
          covariant: covariant);
    } else {
      _checkIsNotSubtypeMatchOf(subtype, supertype, typeFormals,
          covariant: covariant);
    }
  }
}

@reflectiveTest
class GenericFunctionInferenceTest extends AbstractTypeSystemNullSafetyTest {
  void test_boundedByAnotherTypeParameter() {
    // <TFrom, TTo extends Iterable<TFrom>>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo =
        typeParameter('TTo', bound: iterableNone(typeParameterTypeNone(tFrom)));
    var cast = functionTypeNone(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeNone(tFrom),
        ),
      ],
      returnType: typeParameterTypeNone(tTo),
    );
    expect(_inferCall(cast, [stringNone]),
        [stringNone, (iterableNone(stringNone))]);
  }

  void test_boundedByOuterClass() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var A = class_(name: 'A', superType: objectNone);
    var typeA = interfaceTypeNone(A);

    // class B extends A {}
    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeNone(B);

    // class C<T extends A> {
    var CT = typeParameter('T', bound: typeA);
    var C = class_(
      name: 'C',
      superType: objectNone,
      typeParameters: [CT],
    );
    //   S m<S extends T>(S);
    var S = typeParameter('S', bound: typeParameterTypeNone(CT));
    var m = method(
      'm',
      typeParameterTypeNone(S),
      typeFormals: [S],
      parameters: [
        requiredParameter(
          name: '_',
          type: typeParameterTypeNone(S),
        ),
      ],
    );
    C.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = interfaceTypeNone(C, typeArguments: [objectNone]);
    // C<A> cOfA;
    var cOfA = interfaceTypeNone(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = interfaceTypeNone(C, typeArguments: [typeB]);
    // B b;
    // cOfB.m(b); // infer <B>
    _assertType(
        _inferCall2(cOfB.getMethod('m').type, [typeB]), 'B Function(B)');
    // cOfA.m(b); // infer <B>
    _assertType(
        _inferCall2(cOfA.getMethod('m').type, [typeB]), 'B Function(B)');
    // cOfObject.m(b); // infer <B>
    _assertType(
        _inferCall2(cOfObject.getMethod('m').type, [typeB]), 'B Function(B)');
  }

  void test_boundedByOuterClassSubstituted() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var A = class_(name: 'A', superType: objectNone);
    var typeA = interfaceTypeNone(A);

    // class B extends A {}
    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeNone(B);

    // class C<T extends A> {
    var CT = typeParameter('T', bound: typeA);
    var C = class_(
      name: 'C',
      superType: objectNone,
      typeParameters: [CT],
    );
    //   S m<S extends Iterable<T>>(S);
    var iterableOfT = iterableNone(typeParameterTypeNone(CT));
    var S = typeParameter('S', bound: iterableOfT);
    var m = method(
      'm',
      typeParameterTypeNone(S),
      typeFormals: [S],
      parameters: [
        requiredParameter(
          name: '_',
          type: typeParameterTypeNone(S),
        ),
      ],
    );
    C.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = interfaceTypeNone(C, typeArguments: [objectNone]);
    // C<A> cOfA;
    var cOfA = interfaceTypeNone(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = interfaceTypeNone(C, typeArguments: [typeB]);
    // List<B> b;
    var listOfB = listNone(typeB);
    // cOfB.m(b); // infer <B>
    _assertType(_inferCall2(cOfB.getMethod('m').type, [listOfB]),
        'List<B> Function(List<B>)');
    // cOfA.m(b); // infer <B>
    _assertType(_inferCall2(cOfA.getMethod('m').type, [listOfB]),
        'List<B> Function(List<B>)');
    // cOfObject.m(b); // infer <B>
    _assertType(_inferCall2(cOfObject.getMethod('m').type, [listOfB]),
        'List<B> Function(List<B>)');
  }

  void test_boundedRecursively() {
    // class A<T extends A<T>>
    var T = typeParameter('T');
    var A = class_(
      name: 'Cloneable',
      superType: objectNone,
      typeParameters: [T],
    );
    T.bound = interfaceTypeNone(
      A,
      typeArguments: [typeParameterTypeNone(T)],
    );

    // class B extends A<B> {}
    var B = class_(name: 'B', superType: null);
    B.supertype = interfaceTypeNone(A, typeArguments: [interfaceTypeNone(B)]);
    var typeB = interfaceTypeNone(B);

    // <S extends A<S>>
    var S = typeParameter('S');
    var typeS = typeParameterTypeNone(S);
    S.bound = interfaceTypeNone(A, typeArguments: [typeS]);

    // (S, S) -> S
    var clone = functionTypeNone(
      typeFormals: [S],
      parameters: [
        requiredParameter(type: typeS),
        requiredParameter(type: typeS),
      ],
      returnType: typeS,
    );
    expect(_inferCall(clone, [typeB, typeB]), [typeB]);

    // Something invalid...
    expect(
      _inferCall(clone, [stringNone, numNone], expectError: true),
      [objectNone],
    );
  }

  void test_genericCastFunction() {
    // <TFrom, TTo>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo = typeParameter('TTo');
    var cast = functionTypeNone(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeNone(tFrom),
        ),
      ],
      returnType: typeParameterTypeNone(tTo),
    );
    expect(_inferCall(cast, [intNone]), [intNone, dynamicNone]);
  }

  void test_genericCastFunctionWithUpperBound() {
    // <TFrom, TTo extends TFrom>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo = typeParameter(
      'TTo',
      bound: typeParameterTypeNone(tFrom),
    );
    var cast = functionTypeNone(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeNone(tFrom),
        ),
      ],
      returnType: typeParameterTypeNone(tTo),
    );
    expect(_inferCall(cast, [intNone]), [intNone, intNone]);
  }

  void test_parameter_contravariantUseUpperBound() {
    // <T>(T x, void Function(T) y) -> T
    // Generates constraints int <: T <: num.
    // Since T is contravariant, choose num.
    var T = typeParameter('T', variance: Variance.contravariant);
    var tFunction = functionTypeNone(
        parameters: [requiredParameter(type: typeParameterTypeNone(T))],
        returnType: voidNone);
    var numFunction = functionTypeNone(
        parameters: [requiredParameter(type: numNone)], returnType: voidNone);
    var function = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
        requiredParameter(type: tFunction)
      ],
      returnType: typeParameterTypeNone(T),
    );

    expect(_inferCall(function, [intNone, numFunction]), [numNone]);
  }

  void test_parameter_covariantUseLowerBound() {
    // <T>(T x, void Function(T) y) -> T
    // Generates constraints int <: T <: num.
    // Since T is covariant, choose int.
    var T = typeParameter('T', variance: Variance.covariant);
    var tFunction = functionTypeNone(
        parameters: [requiredParameter(type: typeParameterTypeNone(T))],
        returnType: voidNone);
    var numFunction = functionTypeNone(
        parameters: [requiredParameter(type: numNone)], returnType: voidNone);
    var function = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
        requiredParameter(type: tFunction)
      ],
      returnType: typeParameterTypeNone(T),
    );

    expect(_inferCall(function, [intNone, numFunction]), [intNone]);
  }

  void test_parametersToFunctionParam() {
    // <T>(f(T t)) -> T
    var T = typeParameter('T');
    var cast = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(
                type: typeParameterTypeNone(T),
              ),
            ],
            returnType: dynamicNone,
          ),
        ),
      ],
      returnType: typeParameterTypeNone(T),
    );
    expect(
      _inferCall(cast, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: dynamicNone,
        )
      ]),
      [numNone],
    );
  }

  void test_parametersUseLeastUpperBound() {
    // <T>(T x, T y) -> T
    var T = typeParameter('T');
    var cast = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
        requiredParameter(type: typeParameterTypeNone(T)),
      ],
      returnType: typeParameterTypeNone(T),
    );
    expect(_inferCall(cast, [intNone, doubleNone]), [numNone]);
  }

  void test_parameterTypeUsesUpperBound() {
    // <T extends num>(T) -> dynamic
    var T = typeParameter('T', bound: numNone);
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
      ],
      returnType: dynamicNone,
    );
    expect(_inferCall(f, [intNone]), [intNone]);
  }

  void test_returnFunctionWithGenericParameter() {
    // <T>(T -> T) -> (T -> void)
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: typeParameterTypeNone(T)),
            ],
            returnType: typeParameterTypeNone(T),
          ),
        ),
      ],
      returnType: functionTypeNone(
        parameters: [
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
        returnType: voidNone,
      ),
    );
    expect(
      _inferCall(f, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: intNone,
        ),
      ]),
      [intNone],
    );
  }

  void test_returnFunctionWithGenericParameterAndContext() {
    // <T>(T -> T) -> (T -> Null)
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: typeParameterTypeNone(T)),
            ],
            returnType: typeParameterTypeNone(T),
          ),
        ),
      ],
      returnType: functionTypeNone(
        parameters: [
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
        returnType: nullNone,
      ),
    );
    expect(
      _inferCall(
        f,
        [],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: intNone,
        ),
      ),
      [numNone],
    );
  }

  void test_returnFunctionWithGenericParameterAndReturn() {
    // <T>(T -> T) -> (T -> T)
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: typeParameterTypeNone(T)),
            ],
            returnType: typeParameterTypeNone(T),
          ),
        ),
      ],
      returnType: functionTypeNone(
        parameters: [
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
        returnType: typeParameterTypeNone(T),
      ),
    );
    expect(
      _inferCall(f, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: intNone,
        )
      ]),
      [intNone],
    );
  }

  void test_returnFunctionWithGenericReturn() {
    // <T>(T -> T) -> (() -> T)
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: typeParameterTypeNone(T)),
            ],
            returnType: typeParameterTypeNone(T),
          ),
        ),
      ],
      returnType: functionTypeNone(
        returnType: typeParameterTypeNone(T),
      ),
    );
    expect(
      _inferCall(f, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: intNone,
        )
      ]),
      [intNone],
    );
  }

  void test_returnTypeFromContext() {
    // <T>() -> T
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    expect(_inferCall(f, [], returnType: stringNone), [stringNone]);
  }

  void test_returnTypeWithBoundFromContext() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numNone);
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    expect(_inferCall(f, [], returnType: doubleNone), [doubleNone]);
  }

  void test_returnTypeWithBoundFromInvalidContext() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numNone);
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    expect(_inferCall(f, [], returnType: stringNone), [neverNone]);
  }

  void test_unifyParametersToFunctionParam() {
    // <T>(f(T t), g(T t)) -> T
    var T = typeParameter('T');
    var cast = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(
                type: typeParameterTypeNone(T),
              ),
            ],
            returnType: dynamicNone,
          ),
        ),
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(
                type: typeParameterTypeNone(T),
              ),
            ],
            returnType: dynamicNone,
          ),
        ),
      ],
      returnType: typeParameterTypeNone(T),
    );
    expect(
      _inferCall(cast, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: intNone),
          ],
          returnType: dynamicNone,
        ),
        functionTypeNone(
          parameters: [
            requiredParameter(type: doubleNone),
          ],
          returnType: dynamicNone,
        )
      ]),
      [neverNone],
    );
  }

  void test_unusedReturnTypeIsDynamic() {
    // <T>() -> T
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    expect(_inferCall(f, []), [dynamicNone]);
  }

  void test_unusedReturnTypeWithUpperBound() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numNone);
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    expect(_inferCall(f, []), [numNone]);
  }

  void _assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString(withNullability: false);
    expect(typeStr, expected);
  }

  List<DartType> _inferCall(FunctionTypeImpl ft, List<DartType> arguments,
      {DartType returnType, bool expectError = false}) {
    var listener = RecordingErrorListener();

    var reporter = ErrorReporter(
      listener,
      NonExistingSource('/test.dart', toUri('/test.dart'), UriKind.FILE_URI),
      isNonNullableByDefault: false,
    );

    var typeArguments = typeSystem.inferGenericFunctionOrType(
      typeParameters: ft.typeFormals,
      parameters: ft.parameters,
      declaredReturnType: ft.returnType,
      argumentTypes: arguments,
      contextReturnType: returnType,
      errorReporter: reporter,
      errorNode: astFactory.nullLiteral(KeywordToken(Keyword.NULL, 0)),
    );

    if (expectError) {
      expect(listener.errors.map((e) => e.errorCode).toList(),
          [StrongModeCode.COULD_NOT_INFER],
          reason: 'expected exactly 1 could not infer error.');
    } else {
      expect(listener.errors, isEmpty, reason: 'did not expect any errors.');
    }
    return typeArguments;
  }

  FunctionType _inferCall2(FunctionTypeImpl ft, List<DartType> arguments,
      {DartType returnType, bool expectError = false}) {
    var typeArguments = _inferCall(
      ft,
      arguments,
      returnType: returnType,
      expectError: expectError,
    );
    return ft.instantiate(typeArguments);
  }
}
