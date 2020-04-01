// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
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
class ConstraintMatchingTest extends AbstractTypeSystemTest {
  TypeParameterType T;

  @override
  void setUp() {
    super.setUp();
    T = typeParameterTypeStar(
      typeParameter('T'),
    );
  }

  void test_function_coreFunction() {
    _checkOrdinarySubtypeMatch(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: stringStar,
      ),
      typeProvider.functionType,
      [T],
      covariant: true,
    );
  }

  void test_function_parameter_types() {
    _checkIsSubtypeMatchOf(
      functionTypeStar(
        parameters: [
          requiredParameter(type: T),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: stringStar),
        ],
        returnType: intStar,
      ),
      [T],
      ['String <: T'],
      covariant: true,
    );
  }

  void test_function_return_types() {
    _checkIsSubtypeMatchOf(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: T,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: stringStar,
      ),
      [T],
      ['T <: String'],
      covariant: true,
    );
  }

  void test_futureOr_futureOr() {
    _checkIsSubtypeMatchOf(
        futureOrStar(T), futureOrStar(stringStar), [T], ['T <: String'],
        covariant: true);
  }

  void test_futureOr_x_fail_future_branch() {
    // FutureOr<List<T>> <: List<String> can't be satisfied because
    // Future<List<T>> <: List<String> can't be satisfied
    _checkIsNotSubtypeMatchOf(
        futureOrStar(listStar(T)), listStar(stringStar), [T],
        covariant: true);
  }

  void test_futureOr_x_fail_nonFuture_branch() {
    // FutureOr<List<T>> <: Future<List<String>> can't be satisfied because
    // List<T> <: Future<List<String>> can't be satisfied
    _checkIsNotSubtypeMatchOf(
        futureOrStar(listStar(T)), futureStar(listStar(stringStar)), [T],
        covariant: true);
  }

  void test_futureOr_x_success() {
    // FutureOr<T> <: Future<T> can be satisfied by T=Null.  At this point in
    // the type inference algorithm all we figure out is that T must be a
    // subtype of both String and Future<String>.
    _checkIsSubtypeMatchOf(futureOrStar(T), futureStar(stringStar), [T],
        ['T <: String', 'T <: Future<String>'],
        covariant: true);
  }

  void test_lhs_null() {
    // Null <: T is trivially satisfied by the constraint Null <: T.
    _checkIsSubtypeMatchOf(nullStar, T, [T], ['Null <: T'], covariant: false);
    // For any other type X, Null <: X is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(nullStar, listStar(T), [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullStar, stringStar, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullStar, voidNone, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullStar, dynamicType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullStar, objectStar, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullStar, nullStar, [T], covariant: false);
    _checkOrdinarySubtypeMatch(
      nullStar,
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: stringStar,
      ),
      [T],
      covariant: false,
    );
  }

  void test_param_on_lhs_contravariant_direct() {
    // When doing a contravariant match, the type parameters we're trying to
    // find types for are on the right hand side.  Is a type parameter also
    // appears on the left hand side, there is a condition in which the
    // constraint can be satisfied without consulting the bound of the LHS type
    // parameter: the condition where both parameters appear at corresponding
    // locations in the type tree.
    //
    // In other words, List<S> <: List<T> is satisfied provided that
    // S <: T.
    var S = typeParameterTypeStar(typeParameter('S'));
    _checkIsSubtypeMatchOf(listStar(S), listStar(T), [T], ['S <: T'],
        covariant: false);
  }

  void test_param_on_lhs_contravariant_via_bound() {
    // When doing a contravariant match, the type parameters we're trying to
    // find types for are on the right hand side.  Is a type parameter also
    // appears on the left hand side, we may have to constrain the RHS type
    // parameter using the bounds of the LHS type parameter.
    //
    // In other words, S <: List<T> is satisfied provided that
    // bound(S) <: List<T>.
    var S = typeParameterTypeStar(typeParameter(
      'S',
      bound: listStar(stringStar),
    ));
    _checkIsSubtypeMatchOf(S, listStar(T), [T], ['String <: T'],
        covariant: false);
  }

  void test_param_on_lhs_covariant() {
    // When doing a covariant match, the type parameters we're trying to find
    // types for are on the left hand side.
    _checkIsSubtypeMatchOf(T, stringStar, [T], ['T <: String'],
        covariant: true);
  }

  void test_param_on_rhs_contravariant() {
    // When doing a contravariant match, the type parameters we're trying to
    // find types for are on the right hand side.
    _checkIsSubtypeMatchOf(stringStar, T, [T], ['String <: T'],
        covariant: false);
  }

  void test_param_on_rhs_covariant_match() {
    // When doing a covariant match, the type parameters we're trying to find
    // types for are on the left hand side.  If a type parameter appears on the
    // right hand side, there is a condition in which the constraint can be
    // satisfied: where both parameters appear at corresponding locations in the
    // type tree.
    //
    // In other words, T <: S can be satisfied trivially by the constraint
    // T <: S.
    var S = typeParameterTypeStar(typeParameter('S'));
    _checkIsSubtypeMatchOf(T, S, [T], ['T <: S'], covariant: true);
  }

  void test_param_on_rhs_covariant_no_match() {
    // When doing a covariant match, the type parameters we're trying to find
    // types for are on the left hand side.  If a type parameter appears on the
    // right hand side, it's probable that the constraint can't be satisfied,
    // because there is no possible type for the LHS (other than bottom)
    // that's guaranteed to satisfy the relation for all possible assignments of
    // the RHS type parameter.
    //
    // In other words, no match can be found for List<T> <: S because regardless
    // of T, we can't guarantee that List<T> <: S for all S.
    var S = typeParameterTypeStar(typeParameter('S'));
    _checkIsNotSubtypeMatchOf(listStar(T), S, [T], covariant: true);
  }

  void test_related_interface_types_failure() {
    _checkIsNotSubtypeMatchOf(iterableStar(T), listStar(stringStar), [T],
        covariant: true);
  }

  void test_related_interface_types_success() {
    _checkIsSubtypeMatchOf(
        listStar(T), iterableStar(stringStar), [T], ['T <: String'],
        covariant: true);
  }

  void test_rhs_dynamic() {
    // T <: dynamic is trivially satisfied by the constraint T <: dynamic.
    _checkIsSubtypeMatchOf(T, dynamicType, [T], ['T <: dynamic'],
        covariant: true);
    // For any other type X, X <: dynamic is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(listStar(T), dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(stringStar, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidNone, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectStar, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullStar, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: stringStar,
      ),
      dynamicType,
      [T],
      covariant: true,
    );
  }

  void test_rhs_object() {
    // T <: Object is trivially satisfied by the constraint T <: Object.
    _checkIsSubtypeMatchOf(T, objectStar, [T], ['T <: Object'],
        covariant: true);
    // For any other type X, X <: Object is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(listStar(T), objectStar, [T], covariant: true);
    _checkOrdinarySubtypeMatch(stringStar, objectStar, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidNone, objectStar, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicType, objectStar, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectStar, objectStar, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullStar, objectStar, [T], covariant: true);
    _checkOrdinarySubtypeMatch(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: stringStar,
      ),
      objectStar,
      [T],
      covariant: true,
    );
  }

  void test_rhs_void() {
    // T <: void is trivially satisfied by the constraint T <: void.
    _checkIsSubtypeMatchOf(T, voidNone, [T], ['T <: void'], covariant: true);
    // For any other type X, X <: void is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(listStar(T), voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(stringStar, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidNone, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicType, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectStar, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullStar, voidNone, [T], covariant: true);
    _checkOrdinarySubtypeMatch(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: stringStar,
      ),
      voidNone,
      [T],
      covariant: true,
    );
  }

  void test_same_interface_types() {
    _checkIsSubtypeMatchOf(
        listStar(T), listStar(stringStar), [T], ['T <: String'],
        covariant: true);
  }

  void test_variance_contravariant() {
    // class A<in T>
    var tContravariant = typeParameter('T', variance: Variance.contravariant);
    var tType = typeParameterType(tContravariant);
    var A = class_(name: 'A', typeParameters: [tContravariant]);

    // A<num>
    // A<T>
    var aNum = interfaceType(A,
        typeArguments: [numStar], nullabilitySuffix: NullabilitySuffix.none);
    var aT = interfaceType(A,
        typeArguments: [tType], nullabilitySuffix: NullabilitySuffix.none);

    _checkIsSubtypeMatchOf(aT, aNum, [tType], ['num <: in T'], covariant: true);
  }

  void test_variance_covariant() {
    // class A<out T>
    var tCovariant = typeParameter('T', variance: Variance.covariant);
    var tType = typeParameterType(tCovariant);
    var A = class_(name: 'A', typeParameters: [tCovariant]);

    // A<num>
    // A<T>
    var aNum = interfaceType(A,
        typeArguments: [numStar], nullabilitySuffix: NullabilitySuffix.none);
    var aT = interfaceType(A,
        typeArguments: [tType], nullabilitySuffix: NullabilitySuffix.none);

    _checkIsSubtypeMatchOf(aT, aNum, [tType], ['out T <: num'],
        covariant: true);
  }

  void test_variance_invariant() {
    // class A<inout T>
    var tInvariant = typeParameter('T', variance: Variance.invariant);
    var tType = typeParameterType(tInvariant);
    var A = class_(name: 'A', typeParameters: [tInvariant]);

    // A<num>
    // A<T>
    var aNum = interfaceType(A,
        typeArguments: [numStar], nullabilitySuffix: NullabilitySuffix.none);
    var aT = interfaceType(A,
        typeArguments: [tType], nullabilitySuffix: NullabilitySuffix.none);

    _checkIsSubtypeMatchOf(
        aT, aNum, [tType], ['inout T <: num', 'num <: inout T'],
        covariant: true);
  }

  void test_x_futureOr_fail_both_branches() {
    // List<T> <: FutureOr<String> can't be satisfied because neither
    // List<T> <: Future<String> nor List<T> <: int can be satisfied
    _checkIsNotSubtypeMatchOf(listStar(T), futureOrStar(stringStar), [T],
        covariant: true);
  }

  void test_x_futureOr_pass_both_branches_constraints_from_both_branches() {
    // Future<String> <: FutureOr<T> can be satisfied because both
    // Future<String> <: Future<T> and Future<String> <: T can be satisfied.
    // Trying to match Future<String> <: Future<T> generates the constraint
    // String <: T, whereas trying to match Future<String> <: T generates the
    // constraint Future<String> <: T.  We keep the constraint based on trying
    // to match Future<String> <: Future<T>, so String <: T.
    _checkIsSubtypeMatchOf(
        futureStar(stringStar), futureOrStar(T), [T], ['String <: T'],
        covariant: false);
  }

  void test_x_futureOr_pass_both_branches_constraints_from_future_branch() {
    // Future<T> <: FutureOr<Object> can be satisfied because both
    // Future<T> <: Future<Object> and Future<T> <: Object can be satisfied.
    // Trying to match Future<T> <: Future<Object> generates the constraint
    // T <: Object, whereas trying to match Future<T> <: Object generates no
    // constraints, so we keep the constraint T <: Object.
    _checkIsSubtypeMatchOf(
        futureStar(T), futureOrStar(objectStar), [T], ['T <: Object'],
        covariant: true);
  }

  void test_x_futureOr_pass_both_branches_constraints_from_nonFuture_branch() {
    // Null <: FutureOr<T> can be satisfied because both
    // Null <: Future<T> and Null <: T can be satisfied.
    // Trying to match Null <: FutureOr<T> generates no constraints, whereas
    // trying to match Null <: T generates the constraint Null <: T,
    // so we keep the constraint Null <: T.
    _checkIsSubtypeMatchOf(nullStar, futureOrStar(T), [T], ['Null <: T'],
        covariant: false);
  }

  void test_x_futureOr_pass_both_branches_no_constraints() {
    // Future<String> <: FutureOr<Object> is satisfied because both
    // Future<String> <: Future<Object> and Future<String> <: Object.
    // No constraints are recorded.
    _checkIsSubtypeMatchOf(
        futureStar(stringStar), futureOrStar(objectStar), [T], [],
        covariant: true);
  }

  void test_x_futureOr_pass_future_branch() {
    // Future<T> <: FutureOr<String> can be satisfied because
    // Future<T> <: Future<String> can be satisfied
    _checkIsSubtypeMatchOf(
        futureStar(T), futureOrStar(stringStar), [T], ['T <: String'],
        covariant: true);
  }

  void test_x_futureOr_pass_nonFuture_branch() {
    // List<T> <: FutureOr<List<String>> can be satisfied because
    // List<T> <: List<String> can be satisfied
    _checkIsSubtypeMatchOf(
        listStar(T), futureOrStar(listStar(stringStar)), [T], ['T <: String'],
        covariant: true);
  }

  void _checkIsNotSubtypeMatchOf(
      DartType t1, DartType t2, Iterable<TypeParameterType> typeFormals,
      {@required bool covariant}) {
    var inferrer = GenericInferrer(
      typeSystem,
      typeFormals.map((t) => t.element),
    );
    var success =
        inferrer.tryMatchSubtypeOf(t1, t2, null, covariant: covariant);
    expect(success, isFalse);
    inferrer.constraints.forEach((typeParameter, constraintsForTypeParameter) {
      expect(constraintsForTypeParameter, isEmpty);
    });
  }

  void _checkIsSubtypeMatchOf(
      DartType t1,
      DartType t2,
      Iterable<TypeParameterType> typeFormals,
      Iterable<String> expectedConstraints,
      {@required bool covariant}) {
    var inferrer = GenericInferrer(
      typeSystem,
      typeFormals.map((t) => t.element),
    );
    var success =
        inferrer.tryMatchSubtypeOf(t1, t2, null, covariant: covariant);
    expect(success, isTrue);
    var formattedConstraints = <String>[];
    inferrer.constraints.forEach((typeParameter, constraintsForTypeParameter) {
      for (var constraint in constraintsForTypeParameter) {
        formattedConstraints.add(
          constraint.format(
            typeParameter.getDisplayString(
              withNullability: typeSystem.isNonNullableByDefault,
            ),
            withNullability: false,
          ),
        );
      }
    });
    expect(formattedConstraints, unorderedEquals(expectedConstraints));
  }

  void _checkOrdinarySubtypeMatch(
      DartType t1, DartType t2, Iterable<TypeParameterType> typeFormals,
      {@required bool covariant}) {
    bool expectSuccess = typeSystem.isSubtypeOf(t1, t2);
    if (expectSuccess) {
      _checkIsSubtypeMatchOf(t1, t2, typeFormals, [], covariant: covariant);
    } else {
      _checkIsNotSubtypeMatchOf(t1, t2, typeFormals, covariant: covariant);
    }
  }
}

@reflectiveTest
class GenericFunctionInferenceTest extends AbstractTypeSystemTest {
  void test_boundedByAnotherTypeParameter() {
    // <TFrom, TTo extends Iterable<TFrom>>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo =
        typeParameter('TTo', bound: iterableStar(typeParameterTypeStar(tFrom)));
    var cast = functionTypeStar(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeStar(tFrom),
        ),
      ],
      returnType: typeParameterTypeStar(tTo),
    );
    expect(_inferCall(cast, [stringStar]),
        [stringStar, (iterableStar(stringStar))]);
  }

  void test_boundedByOuterClass() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var A = class_(name: 'A', superType: objectStar);
    var typeA = interfaceTypeStar(A);

    // class B extends A {}
    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeStar(B);

    // class C<T extends A> {
    var CT = typeParameter('T', bound: typeA);
    var C = class_(
      name: 'C',
      superType: objectStar,
      typeParameters: [CT],
    );
    //   S m<S extends T>(S);
    var S = typeParameter('S', bound: typeParameterTypeStar(CT));
    var m = method(
      'm',
      typeParameterTypeStar(S),
      typeFormals: [S],
      parameters: [
        requiredParameter(
          name: '_',
          type: typeParameterTypeStar(S),
        ),
      ],
    );
    C.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = interfaceTypeStar(C, typeArguments: [objectStar]);
    // C<A> cOfA;
    var cOfA = interfaceTypeStar(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = interfaceTypeStar(C, typeArguments: [typeB]);
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
    var A = class_(name: 'A', superType: objectStar);
    var typeA = interfaceTypeStar(A);

    // class B extends A {}
    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeStar(B);

    // class C<T extends A> {
    var CT = typeParameter('T', bound: typeA);
    var C = class_(
      name: 'C',
      superType: objectStar,
      typeParameters: [CT],
    );
    //   S m<S extends Iterable<T>>(S);
    var iterableOfT = iterableStar(typeParameterTypeStar(CT));
    var S = typeParameter('S', bound: iterableOfT);
    var m = method(
      'm',
      typeParameterTypeStar(S),
      typeFormals: [S],
      parameters: [
        requiredParameter(
          name: '_',
          type: typeParameterTypeStar(S),
        ),
      ],
    );
    C.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = interfaceTypeStar(C, typeArguments: [objectStar]);
    // C<A> cOfA;
    var cOfA = interfaceTypeStar(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = interfaceTypeStar(C, typeArguments: [typeB]);
    // List<B> b;
    var listOfB = listStar(typeB);
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
      superType: objectStar,
      typeParameters: [T],
    );
    T.bound = interfaceTypeStar(
      A,
      typeArguments: [typeParameterTypeStar(T)],
    );

    // class B extends A<B> {}
    var B = class_(name: 'B', superType: null);
    B.supertype = interfaceTypeStar(A, typeArguments: [interfaceTypeStar(B)]);
    var typeB = interfaceTypeStar(B);

    // <S extends A<S>>
    var S = typeParameter('S');
    var typeS = typeParameterTypeStar(S);
    S.bound = interfaceTypeStar(A, typeArguments: [typeS]);

    // (S, S) -> S
    var clone = functionTypeStar(
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
      _inferCall(clone, [stringStar, numStar], expectError: true),
      [objectStar],
    );
  }

  void test_genericCastFunction() {
    // <TFrom, TTo>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo = typeParameter('TTo');
    var cast = functionTypeStar(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeStar(tFrom),
        ),
      ],
      returnType: typeParameterTypeStar(tTo),
    );
    expect(_inferCall(cast, [intStar]), [intStar, dynamicType]);
  }

  void test_genericCastFunctionWithUpperBound() {
    // <TFrom, TTo extends TFrom>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo = typeParameter(
      'TTo',
      bound: typeParameterTypeStar(tFrom),
    );
    var cast = functionTypeStar(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeStar(tFrom),
        ),
      ],
      returnType: typeParameterTypeStar(tTo),
    );
    expect(_inferCall(cast, [intStar]), [intStar, intStar]);
  }

  void test_parameter_contravariantUseUpperBound() {
    // <T>(T x, void Function(T) y) -> T
    // Generates constraints int <: T <: num.
    // Since T is contravariant, choose num.
    var T = typeParameter('T', variance: Variance.contravariant);
    var tFunction = functionTypeStar(
        parameters: [requiredParameter(type: typeParameterTypeStar(T))],
        returnType: voidNone);
    var numFunction = functionTypeStar(
        parameters: [requiredParameter(type: numStar)], returnType: voidNone);
    var function = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeStar(T)),
        requiredParameter(type: tFunction)
      ],
      returnType: typeParameterTypeStar(T),
    );

    expect(_inferCall(function, [intStar, numFunction]), [numStar]);
  }

  void test_parameter_covariantUseLowerBound() {
    // <T>(T x, void Function(T) y) -> T
    // Generates constraints int <: T <: num.
    // Since T is covariant, choose int.
    var T = typeParameter('T', variance: Variance.covariant);
    var tFunction = functionTypeStar(
        parameters: [requiredParameter(type: typeParameterTypeStar(T))],
        returnType: voidNone);
    var numFunction = functionTypeStar(
        parameters: [requiredParameter(type: numStar)], returnType: voidNone);
    var function = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeStar(T)),
        requiredParameter(type: tFunction)
      ],
      returnType: typeParameterTypeStar(T),
    );

    expect(_inferCall(function, [intStar, numFunction]), [intStar]);
  }

  void test_parametersToFunctionParam() {
    // <T>(f(T t)) -> T
    var T = typeParameter('T');
    var cast = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(
                type: typeParameterTypeStar(T),
              ),
            ],
            returnType: dynamicType,
          ),
        ),
      ],
      returnType: typeParameterTypeStar(T),
    );
    expect(
      _inferCall(cast, [
        functionTypeStar(
          parameters: [
            requiredParameter(type: numStar),
          ],
          returnType: dynamicType,
        )
      ]),
      [numStar],
    );
  }

  void test_parametersUseLeastUpperBound() {
    // <T>(T x, T y) -> T
    var T = typeParameter('T');
    var cast = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeStar(T)),
        requiredParameter(type: typeParameterTypeStar(T)),
      ],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(cast, [intStar, doubleStar]), [numStar]);
  }

  void test_parameterTypeUsesUpperBound() {
    // <T extends num>(T) -> dynamic
    var T = typeParameter('T', bound: numStar);
    var f = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeStar(T)),
      ],
      returnType: dynamicType,
    );
    expect(_inferCall(f, [intStar]), [intStar]);
  }

  void test_returnFunctionWithGenericParameter() {
    // <T>(T -> T) -> (T -> void)
    var T = typeParameter('T');
    var f = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: typeParameterTypeStar(T)),
            ],
            returnType: typeParameterTypeStar(T),
          ),
        ),
      ],
      returnType: functionTypeStar(
        parameters: [
          requiredParameter(type: typeParameterTypeStar(T)),
        ],
        returnType: voidNone,
      ),
    );
    expect(
      _inferCall(f, [
        functionTypeStar(
          parameters: [
            requiredParameter(type: numStar),
          ],
          returnType: intStar,
        ),
      ]),
      [intStar],
    );
  }

  void test_returnFunctionWithGenericParameterAndContext() {
    // <T>(T -> T) -> (T -> Null)
    var T = typeParameter('T');
    var f = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: typeParameterTypeStar(T)),
            ],
            returnType: typeParameterTypeStar(T),
          ),
        ),
      ],
      returnType: functionTypeStar(
        parameters: [
          requiredParameter(type: typeParameterTypeStar(T)),
        ],
        returnType: nullStar,
      ),
    );
    expect(
      _inferCall(
        f,
        [],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: numStar),
          ],
          returnType: intStar,
        ),
      ),
      [numStar],
    );
  }

  void test_returnFunctionWithGenericParameterAndReturn() {
    // <T>(T -> T) -> (T -> T)
    var T = typeParameter('T');
    var f = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: typeParameterTypeStar(T)),
            ],
            returnType: typeParameterTypeStar(T),
          ),
        ),
      ],
      returnType: functionTypeStar(
        parameters: [
          requiredParameter(type: typeParameterTypeStar(T)),
        ],
        returnType: typeParameterTypeStar(T),
      ),
    );
    expect(
      _inferCall(f, [
        functionTypeStar(
          parameters: [
            requiredParameter(type: numStar),
          ],
          returnType: intStar,
        )
      ]),
      [intStar],
    );
  }

  void test_returnFunctionWithGenericReturn() {
    // <T>(T -> T) -> (() -> T)
    var T = typeParameter('T');
    var f = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: typeParameterTypeStar(T)),
            ],
            returnType: typeParameterTypeStar(T),
          ),
        ),
      ],
      returnType: functionTypeStar(
        returnType: typeParameterTypeStar(T),
      ),
    );
    expect(
      _inferCall(f, [
        functionTypeStar(
          parameters: [
            requiredParameter(type: numStar),
          ],
          returnType: intStar,
        )
      ]),
      [intStar],
    );
  }

  void test_returnTypeFromContext() {
    // <T>() -> T
    var T = typeParameter('T');
    var f = functionTypeStar(
      typeFormals: [T],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(f, [], returnType: stringStar), [stringStar]);
  }

  void test_returnTypeWithBoundFromContext() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numStar);
    var f = functionTypeStar(
      typeFormals: [T],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(f, [], returnType: doubleStar), [doubleStar]);
  }

  void test_returnTypeWithBoundFromInvalidContext() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numStar);
    var f = functionTypeStar(
      typeFormals: [T],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(f, [], returnType: stringStar), [nullStar]);
  }

  void test_unifyParametersToFunctionParam() {
    // <T>(f(T t), g(T t)) -> T
    var T = typeParameter('T');
    var cast = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(
                type: typeParameterTypeStar(T),
              ),
            ],
            returnType: dynamicType,
          ),
        ),
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(
                type: typeParameterTypeStar(T),
              ),
            ],
            returnType: dynamicType,
          ),
        ),
      ],
      returnType: typeParameterTypeStar(T),
    );
    expect(
      _inferCall(cast, [
        functionTypeStar(
          parameters: [
            requiredParameter(type: intStar),
          ],
          returnType: dynamicType,
        ),
        functionTypeStar(
          parameters: [
            requiredParameter(type: doubleStar),
          ],
          returnType: dynamicType,
        )
      ]),
      [nullStar],
    );
  }

  void test_unusedReturnTypeIsDynamic() {
    // <T>() -> T
    var T = typeParameter('T');
    var f = functionTypeStar(
      typeFormals: [T],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(f, []), [dynamicType]);
  }

  void test_unusedReturnTypeWithUpperBound() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numStar);
    var f = functionTypeStar(
      typeFormals: [T],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(f, []), [numStar]);
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
