// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests related to the [TypeSystem] class.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart' show astFactory;
import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/token.dart' show KeywordToken;
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart'
    show NonExistingSource, UriKind;
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' show toUri;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'elements_types_mixin.dart';
import 'test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignabilityTest);
    defineReflectiveTests(ConstraintMatchingTest);
    defineReflectiveTests(GenericFunctionInferenceTest);
    defineReflectiveTests(GreatestLowerBoundTest);
    defineReflectiveTests(LeastUpperBoundFunctionsTest);
    defineReflectiveTests(LeastUpperBoundTest);
    defineReflectiveTests(TypeSystemTest);
  });
}

abstract class AbstractTypeSystemTest with ElementsTypesMixin {
  TypeProvider typeProvider;
  Dart2TypeSystem typeSystem;

  InterfaceType get doubleType => typeProvider.doubleType;

  InterfaceType get intType => typeProvider.intType;

  DartType get nullType => typeProvider.nullType;

  InterfaceType get numType => typeProvider.numType;

  InterfaceType get objectType => typeProvider.objectType;

  InterfaceType get stringType => typeProvider.stringType;

  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting();
  }

  DartType get voidType => VoidTypeImpl.instance;

  DartType futureOrType(DartType T) {
    var futureOrElement = typeProvider.futureOrElement;
    return interfaceType(futureOrElement, typeArguments: [T]);
  }

  DartType futureType(DartType T) {
    var futureElement = typeProvider.futureElement;
    return interfaceType(futureElement, typeArguments: [T]);
  }

  DartType iterableType(DartType T) {
    var iterableElement = typeProvider.iterableElement;
    return interfaceType(iterableElement, typeArguments: [T]);
  }

  DartType listType(DartType T) {
    var listElement = typeProvider.listElement;
    return interfaceType(listElement, typeArguments: [T]);
  }

  void setUp() {
    var analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProvider;
    typeSystem = analysisContext.typeSystem;

    typeProvider = typeProvider;
    typeSystem = typeSystem;
  }
}

@reflectiveTest
class AssignabilityTest extends AbstractTypeSystemTest {
  void test_isAssignableTo_bottom_isBottom() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      interfaceType(A),
      neverStar,
    ];

    _checkGroups(neverStar, interassignable: interassignable);
  }

  void test_isAssignableTo_call_method() {
    var B = class_(
      name: 'B',
      methods: [
        method('call', objectType, parameters: [
          requiredParameter(name: '_', type: intType),
        ]),
      ],
    );

    _checkIsStrictAssignableTo(
      interfaceType(B),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intType),
        ],
        returnType: objectType,
      ),
    );
  }

  void test_isAssignableTo_classes() {
    var classTop = class_(name: 'A');
    var classLeft = class_(name: 'B', superType: interfaceType(classTop));
    var classRight = class_(name: 'C', superType: interfaceType(classTop));
    var classBottom = class_(
      name: 'D',
      superType: interfaceType(classLeft),
      interfaces: [interfaceType(classRight)],
    );
    var top = interfaceType(classTop);
    var left = interfaceType(classLeft);
    var right = interfaceType(classRight);
    var bottom = interfaceType(classBottom);

    _checkLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_double() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      doubleType,
      numType,
      neverStar,
    ];
    List<DartType> unrelated = <DartType>[
      intType,
      stringType,
      interfaceType(A),
    ];

    _checkGroups(doubleType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_dynamic_isTop() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      interfaceType(A),
      neverStar,
    ];
    _checkGroups(dynamicType, interassignable: interassignable);
  }

  void test_isAssignableTo_generics() {
    var LT = typeParameter('T');
    var L = class_(name: 'L', typeParameters: [LT]);

    var MT = typeParameter('T');
    var M = class_(
      name: 'M',
      typeParameters: [MT],
      interfaces: [
        interfaceType(
          L,
          typeArguments: [
            typeParameterTypeStar(MT),
          ],
        ),
      ],
    );

    var top = interfaceType(L, typeArguments: [dynamicType]);
    var left = interfaceType(M, typeArguments: [dynamicType]);
    var right = interfaceType(L, typeArguments: [intType]);
    var bottom = interfaceType(M, typeArguments: [intType]);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_int() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      numType,
      neverStar,
    ];
    List<DartType> unrelated = <DartType>[
      doubleType,
      stringType,
      interfaceType(A),
    ];

    _checkGroups(intType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_named_optional() {
    var r = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
      ],
      returnType: intType,
    );
    var o = functionTypeStar(
      parameters: [
        positionalParameter(type: intType),
      ],
      returnType: intType,
    );
    var n = functionTypeStar(
      parameters: [
        namedParameter(name: 'x', type: intType),
      ],
      returnType: intType,
    );

    var rr = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        requiredParameter(type: intType),
      ],
      returnType: intType,
    );
    var ro = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        positionalParameter(type: intType),
      ],
      returnType: intType,
    );
    var rn = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        namedParameter(name: 'x', type: intType),
      ],
      returnType: intType,
    );
    var oo = functionTypeStar(
      parameters: [
        positionalParameter(type: intType),
        positionalParameter(type: intType),
      ],
      returnType: intType,
    );
    var nn = functionTypeStar(
      parameters: [
        namedParameter(name: 'x', type: intType),
        namedParameter(name: 'y', type: intType),
      ],
      returnType: intType,
    );
    var nnn = functionTypeStar(
      parameters: [
        namedParameter(name: 'x', type: intType),
        namedParameter(name: 'y', type: intType),
        namedParameter(name: 'z', type: intType),
      ],
      returnType: intType,
    );

    _checkGroups(r,
        interassignable: [r, o, ro, rn, oo], unrelated: [n, rr, nn, nnn]);
    _checkGroups(o,
        interassignable: [o, oo], unrelated: [n, rr, ro, rn, nn, nnn]);
    _checkGroups(n,
        interassignable: [n, nn, nnn], unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(rr,
        interassignable: [rr, ro, oo], unrelated: [r, o, n, rn, nn, nnn]);
    _checkGroups(ro, interassignable: [ro, oo], unrelated: [o, n, rn, nn, nnn]);
    _checkGroups(rn,
        interassignable: [rn], unrelated: [o, n, rr, ro, oo, nn, nnn]);
    _checkGroups(oo, interassignable: [oo], unrelated: [n, rn, nn, nnn]);
    _checkGroups(nn,
        interassignable: [nn, nnn], unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(nnn,
        interassignable: [nnn], unrelated: [r, o, rr, ro, rn, oo]);
  }

  void test_isAssignableTo_num() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      numType,
      intType,
      doubleType,
      neverStar,
    ];
    List<DartType> unrelated = <DartType>[
      stringType,
      interfaceType(A),
    ];

    _checkGroups(numType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_simple_function() {
    var top = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
      ],
      returnType: objectType,
    );

    var left = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
      ],
      returnType: intType,
    );

    var right = functionTypeStar(
      parameters: [
        requiredParameter(type: objectType),
      ],
      returnType: objectType,
    );

    var bottom = functionTypeStar(
      parameters: [
        requiredParameter(type: objectType),
      ],
      returnType: intType,
    );

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_void_functions() {
    var top = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );

    var bottom = functionTypeStar(
      parameters: [
        requiredParameter(type: objectType),
      ],
      returnType: intType,
    );

    _checkEquivalent(bottom, top);
  }

  void _checkCrossLattice(
      DartType top, DartType left, DartType right, DartType bottom) {
    _checkGroups(top, interassignable: [top, left, right, bottom]);
    _checkGroups(left,
        interassignable: [top, left, bottom], unrelated: [right]);
    _checkGroups(right,
        interassignable: [top, right, bottom], unrelated: [left]);
    _checkGroups(bottom, interassignable: [top, left, right, bottom]);
  }

  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsAssignableTo(type1, type2);
    _checkIsAssignableTo(type2, type1);
  }

  void _checkGroups(DartType t1,
      {List<DartType> interassignable, List<DartType> unrelated}) {
    if (interassignable != null) {
      for (DartType t2 in interassignable) {
        _checkEquivalent(t1, t2);
      }
    }
    if (unrelated != null) {
      for (DartType t2 in unrelated) {
        _checkUnrelated(t1, t2);
      }
    }
  }

  void _checkIsAssignableTo(DartType type1, DartType type2) {
    expect(typeSystem.isAssignableTo(type1, type2), true);
  }

  void _checkIsNotAssignableTo(DartType type1, DartType type2) {
    expect(typeSystem.isAssignableTo(type1, type2), false);
  }

  void _checkIsStrictAssignableTo(DartType type1, DartType type2) {
    _checkIsAssignableTo(type1, type2);
    _checkIsNotAssignableTo(type2, type1);
  }

  void _checkLattice(
      DartType top, DartType left, DartType right, DartType bottom) {
    _checkGroups(top, interassignable: <DartType>[top, left, right, bottom]);
    _checkGroups(left,
        interassignable: <DartType>[top, left, bottom],
        unrelated: <DartType>[right]);
    _checkGroups(right,
        interassignable: <DartType>[top, right, bottom],
        unrelated: <DartType>[left]);
    _checkGroups(bottom, interassignable: <DartType>[top, left, right, bottom]);
  }

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotAssignableTo(type1, type2);
    _checkIsNotAssignableTo(type2, type1);
  }
}

/**
 * Base class for testing LUB and GLB in spec and strong mode.
 */
abstract class BoundTestBase extends AbstractTypeSystemTest {
  void _checkGreatestLowerBound(
      DartType type1, DartType type2, DartType expectedResult) {
    var glb = typeSystem.getGreatestLowerBound(type1, type2);
    expect(glb, expectedResult);

    // Check that the result is a lower bound.
    expect(typeSystem.isSubtypeOf(glb, type1), true);
    expect(typeSystem.isSubtypeOf(glb, type2), true);

    // Check for symmetry while we're at it.
    glb = typeSystem.getGreatestLowerBound(type2, type1);
    expect(glb, expectedResult);
  }

  void _checkLeastUpperBound(
      DartType type1, DartType type2, DartType expectedResult) {
    var lub = typeSystem.getLeastUpperBound(type1, type2);
    expect(lub, expectedResult);

    // Check that the result is an upper bound.
    expect(typeSystem.isSubtypeOf(type1, lub), true);
    expect(typeSystem.isSubtypeOf(type2, lub), true);

    // Check for symmetry while we're at it.
    lub = typeSystem.getLeastUpperBound(type2, type1);
    expect(lub, expectedResult);
  }
}

@reflectiveTest
class ConstraintMatchingTest extends AbstractTypeSystemTest {
  TypeParameterType T;

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
          requiredParameter(type: intType),
        ],
        returnType: stringType,
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
        returnType: intType,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: stringType),
        ],
        returnType: intType,
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
          requiredParameter(type: intType),
        ],
        returnType: T,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intType),
        ],
        returnType: stringType,
      ),
      [T],
      ['T <: String'],
      covariant: true,
    );
  }

  void test_futureOr_futureOr() {
    _checkIsSubtypeMatchOf(
        futureOrType(T), futureOrType(stringType), [T], ['T <: String'],
        covariant: true);
  }

  void test_futureOr_x_fail_future_branch() {
    // FutureOr<List<T>> <: List<String> can't be satisfied because
    // Future<List<T>> <: List<String> can't be satisfied
    _checkIsNotSubtypeMatchOf(
        futureOrType(listType(T)), listType(stringType), [T],
        covariant: true);
  }

  void test_futureOr_x_fail_nonFuture_branch() {
    // FutureOr<List<T>> <: Future<List<String>> can't be satisfied because
    // List<T> <: Future<List<String>> can't be satisfied
    _checkIsNotSubtypeMatchOf(
        futureOrType(listType(T)), futureType(listType(stringType)), [T],
        covariant: true);
  }

  void test_futureOr_x_success() {
    // FutureOr<T> <: Future<T> can be satisfied by T=Null.  At this point in
    // the type inference algorithm all we figure out is that T must be a
    // subtype of both String and Future<String>.
    _checkIsSubtypeMatchOf(futureOrType(T), futureType(stringType), [T],
        ['T <: String', 'T <: Future<String>'],
        covariant: true);
  }

  void test_lhs_null() {
    // Null <: T is trivially satisfied by the constraint Null <: T.
    _checkIsSubtypeMatchOf(nullType, T, [T], ['Null <: T'], covariant: false);
    // For any other type X, Null <: X is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(nullType, listType(T), [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, stringType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, voidType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, dynamicType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, objectType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, nullType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(
      nullType,
      functionTypeStar(
        parameters: [
          requiredParameter(type: intType),
        ],
        returnType: stringType,
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
    _checkIsSubtypeMatchOf(listType(S), listType(T), [T], ['S <: T'],
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
      bound: listType(stringType),
    ));
    _checkIsSubtypeMatchOf(S, listType(T), [T], ['String <: T'],
        covariant: false);
  }

  void test_param_on_lhs_covariant() {
    // When doing a covariant match, the type parameters we're trying to find
    // types for are on the left hand side.
    _checkIsSubtypeMatchOf(T, stringType, [T], ['T <: String'],
        covariant: true);
  }

  void test_param_on_rhs_contravariant() {
    // When doing a contravariant match, the type parameters we're trying to
    // find types for are on the right hand side.
    _checkIsSubtypeMatchOf(stringType, T, [T], ['String <: T'],
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
    _checkIsNotSubtypeMatchOf(listType(T), S, [T], covariant: true);
  }

  void test_related_interface_types_failure() {
    _checkIsNotSubtypeMatchOf(iterableType(T), listType(stringType), [T],
        covariant: true);
  }

  void test_related_interface_types_success() {
    _checkIsSubtypeMatchOf(
        listType(T), iterableType(stringType), [T], ['T <: String'],
        covariant: true);
  }

  void test_rhs_dynamic() {
    // T <: dynamic is trivially satisfied by the constraint T <: dynamic.
    _checkIsSubtypeMatchOf(T, dynamicType, [T], ['T <: dynamic'],
        covariant: true);
    // For any other type X, X <: dynamic is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(listType(T), dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(stringType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intType),
        ],
        returnType: stringType,
      ),
      dynamicType,
      [T],
      covariant: true,
    );
  }

  void test_rhs_object() {
    // T <: Object is trivially satisfied by the constraint T <: Object.
    _checkIsSubtypeMatchOf(T, objectType, [T], ['T <: Object'],
        covariant: true);
    // For any other type X, X <: Object is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(listType(T), objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(stringType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intType),
        ],
        returnType: stringType,
      ),
      objectType,
      [T],
      covariant: true,
    );
  }

  void test_rhs_void() {
    // T <: void is trivially satisfied by the constraint T <: void.
    _checkIsSubtypeMatchOf(T, voidType, [T], ['T <: void'], covariant: true);
    // For any other type X, X <: void is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(listType(T), voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(stringType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intType),
        ],
        returnType: stringType,
      ),
      voidType,
      [T],
      covariant: true,
    );
  }

  void test_same_interface_types() {
    _checkIsSubtypeMatchOf(
        listType(T), listType(stringType), [T], ['T <: String'],
        covariant: true);
  }

  void test_x_futureOr_fail_both_branches() {
    // List<T> <: FutureOr<String> can't be satisfied because neither
    // List<T> <: Future<String> nor List<T> <: int can be satisfied
    _checkIsNotSubtypeMatchOf(listType(T), futureOrType(stringType), [T],
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
        futureType(stringType), futureOrType(T), [T], ['String <: T'],
        covariant: false);
  }

  void test_x_futureOr_pass_both_branches_constraints_from_future_branch() {
    // Future<T> <: FutureOr<Object> can be satisfied because both
    // Future<T> <: Future<Object> and Future<T> <: Object can be satisfied.
    // Trying to match Future<T> <: Future<Object> generates the constraint
    // T <: Object, whereas trying to match Future<T> <: Object generates no
    // constraints, so we keep the constraint T <: Object.
    _checkIsSubtypeMatchOf(
        futureType(T), futureOrType(objectType), [T], ['T <: Object'],
        covariant: true);
  }

  void test_x_futureOr_pass_both_branches_constraints_from_nonFuture_branch() {
    // Null <: FutureOr<T> can be satisfied because both
    // Null <: Future<T> and Null <: T can be satisfied.
    // Trying to match Null <: FutureOr<T> generates no constraints, whereas
    // trying to match Null <: T generates the constraint Null <: T,
    // so we keep the constraint Null <: T.
    _checkIsSubtypeMatchOf(nullType, futureOrType(T), [T], ['Null <: T'],
        covariant: false);
  }

  void test_x_futureOr_pass_both_branches_no_constraints() {
    // Future<String> <: FutureOr<Object> is satisfied because both
    // Future<String> <: Future<Object> and Future<String> <: Object.
    // No constraints are recorded.
    _checkIsSubtypeMatchOf(
        futureType(stringType), futureOrType(objectType), [T], [],
        covariant: true);
  }

  void test_x_futureOr_pass_future_branch() {
    // Future<T> <: FutureOr<String> can be satisfied because
    // Future<T> <: Future<String> can be satisfied
    _checkIsSubtypeMatchOf(
        futureType(T), futureOrType(stringType), [T], ['T <: String'],
        covariant: true);
  }

  void test_x_futureOr_pass_nonFuture_branch() {
    // List<T> <: FutureOr<List<String>> can be satisfied because
    // List<T> <: List<String> can be satisfied
    _checkIsSubtypeMatchOf(
        listType(T), futureOrType(listType(stringType)), [T], ['T <: String'],
        covariant: true);
  }

  void _checkIsNotSubtypeMatchOf(
      DartType t1, DartType t2, Iterable<TypeParameterType> typeFormals,
      {bool covariant}) {
    var inferrer = new GenericInferrer(
        typeProvider, typeSystem, typeFormals.map((t) => t.element));
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
      {bool covariant}) {
    var inferrer = new GenericInferrer(
        typeProvider, typeSystem, typeFormals.map((t) => t.element));
    var success =
        inferrer.tryMatchSubtypeOf(t1, t2, null, covariant: covariant);
    expect(success, isTrue);
    var formattedConstraints = <String>[];
    inferrer.constraints.forEach((typeParameter, constraintsForTypeParameter) {
      for (var constraint in constraintsForTypeParameter) {
        formattedConstraints.add(constraint.format(typeParameter.toString()));
      }
    });
    expect(formattedConstraints, unorderedEquals(expectedConstraints));
  }

  void _checkOrdinarySubtypeMatch(
      DartType t1, DartType t2, Iterable<TypeParameterType> typeFormals,
      {bool covariant}) {
    bool expectSuccess = typeSystem.isSubtypeOf(t1, t2);
    if (expectSuccess) {
      _checkIsSubtypeMatchOf(t1, t2, typeFormals, [], covariant: covariant);
    } else {
      _checkIsNotSubtypeMatchOf(t1, t2, typeFormals);
    }
  }
}

@reflectiveTest
class GenericFunctionInferenceTest extends AbstractTypeSystemTest {
  void test_boundedByAnotherTypeParameter() {
    // <TFrom, TTo extends Iterable<TFrom>>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo =
        typeParameter('TTo', bound: iterableType(typeParameterTypeStar(tFrom)));
    var cast = functionTypeStar(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeStar(tFrom),
        ),
      ],
      returnType: typeParameterTypeStar(tTo),
    );
    expect(
        _inferCall(cast, [stringType]), [stringType, iterableType(stringType)]);
  }

  void test_boundedByOuterClass() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var A = class_(name: 'A', superType: objectType);
    var typeA = interfaceType(A);

    // class B extends A {}
    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceType(B);

    // class C<T extends A> {
    var CT = typeParameter('T', bound: typeA);
    var C = class_(
      name: 'C',
      superType: objectType,
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
    var cOfObject = interfaceType(C, typeArguments: [objectType]);
    // C<A> cOfA;
    var cOfA = interfaceType(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = interfaceType(C, typeArguments: [typeB]);
    // B b;
    // cOfB.m(b); // infer <B>
    expect(_inferCall2(cOfB.getMethod('m').type, [typeB]).toString(),
        'B Function(B)');
    // cOfA.m(b); // infer <B>
    expect(_inferCall2(cOfA.getMethod('m').type, [typeB]).toString(),
        'B Function(B)');
    // cOfObject.m(b); // infer <B>
    expect(_inferCall2(cOfObject.getMethod('m').type, [typeB]).toString(),
        'B Function(B)');
  }

  void test_boundedByOuterClassSubstituted() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var A = class_(name: 'A', superType: objectType);
    var typeA = interfaceType(A);

    // class B extends A {}
    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceType(B);

    // class C<T extends A> {
    var CT = typeParameter('T', bound: typeA);
    var C = class_(
      name: 'C',
      superType: objectType,
      typeParameters: [CT],
    );
    //   S m<S extends Iterable<T>>(S);
    var iterableOfT = iterableType(typeParameterTypeStar(CT));
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
    var cOfObject = interfaceType(C, typeArguments: [objectType]);
    // C<A> cOfA;
    var cOfA = interfaceType(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = interfaceType(C, typeArguments: [typeB]);
    // List<B> b;
    var listOfB = listType(typeB);
    // cOfB.m(b); // infer <B>
    expect(_inferCall2(cOfB.getMethod('m').type, [listOfB]).toString(),
        'List<B> Function(List<B>)');
    // cOfA.m(b); // infer <B>
    expect(_inferCall2(cOfA.getMethod('m').type, [listOfB]).toString(),
        'List<B> Function(List<B>)');
    // cOfObject.m(b); // infer <B>
    expect(_inferCall2(cOfObject.getMethod('m').type, [listOfB]).toString(),
        'List<B> Function(List<B>)');
  }

  void test_boundedRecursively() {
    // class A<T extends A<T>>
    var T = typeParameter('T');
    var A = class_(
      name: 'Cloneable',
      superType: objectType,
      typeParameters: [T],
    );
    T.bound = interfaceType(
      A,
      typeArguments: [typeParameterTypeStar(T)],
    );

    // class B extends A<B> {}
    var B = class_(name: 'B', superType: null);
    B.supertype = interfaceType(A, typeArguments: [interfaceType(B)]);
    var typeB = interfaceType(B);

    // <S extends A<S>>
    var S = typeParameter('S');
    var typeS = typeParameterTypeStar(S);
    S.bound = interfaceType(A, typeArguments: [typeS]);

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
      _inferCall(clone, [stringType, numType], expectError: true),
      [objectType],
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
    expect(_inferCall(cast, [intType]), [intType, dynamicType]);
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
    expect(_inferCall(cast, [intType]), [intType, intType]);
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
            requiredParameter(type: numType),
          ],
          returnType: dynamicType,
        )
      ]),
      [numType],
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
    expect(_inferCall(cast, [intType, doubleType]), [numType]);
  }

  void test_parameterTypeUsesUpperBound() {
    // <T extends num>(T) -> dynamic
    var T = typeParameter('T', bound: numType);
    var f = functionTypeStar(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeStar(T)),
      ],
      returnType: dynamicType,
    );
    expect(_inferCall(f, [intType]), [intType]);
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
        returnType: voidType,
      ),
    );
    expect(
      _inferCall(f, [
        functionTypeStar(
          parameters: [
            requiredParameter(type: numType),
          ],
          returnType: intType,
        ),
      ]),
      [intType],
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
        returnType: nullType,
      ),
    );
    expect(
      _inferCall(
        f,
        [],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: numType),
          ],
          returnType: intType,
        ),
      ),
      [numType],
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
            requiredParameter(type: numType),
          ],
          returnType: intType,
        )
      ]),
      [intType],
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
            requiredParameter(type: numType),
          ],
          returnType: intType,
        )
      ]),
      [intType],
    );
  }

  void test_returnTypeFromContext() {
    // <T>() -> T
    var T = typeParameter('T');
    var f = functionTypeStar(
      typeFormals: [T],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(f, [], returnType: stringType), [stringType]);
  }

  void test_returnTypeWithBoundFromContext() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numType);
    var f = functionTypeStar(
      typeFormals: [T],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(f, [], returnType: doubleType), [doubleType]);
  }

  void test_returnTypeWithBoundFromInvalidContext() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numType);
    var f = functionTypeStar(
      typeFormals: [T],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(f, [], returnType: stringType), [nullType]);
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
            requiredParameter(type: intType),
          ],
          returnType: dynamicType,
        ),
        functionTypeStar(
          parameters: [
            requiredParameter(type: doubleType),
          ],
          returnType: dynamicType,
        )
      ]),
      [nullType],
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
    var T = typeParameter('T', bound: numType);
    var f = functionTypeStar(
      typeFormals: [T],
      returnType: typeParameterTypeStar(T),
    );
    expect(_inferCall(f, []), [numType]);
  }

  List<DartType> _inferCall(FunctionTypeImpl ft, List<DartType> arguments,
      {DartType returnType, bool expectError: false}) {
    var listener = new RecordingErrorListener();

    var reporter = new ErrorReporter(
        listener,
        new NonExistingSource(
            '/test.dart', toUri('/test.dart'), UriKind.FILE_URI));

    var typeArguments = typeSystem.inferGenericFunctionOrType(
      typeParameters: ft.typeFormals,
      parameters: ft.parameters,
      declaredReturnType: ft.returnType,
      argumentTypes: arguments,
      contextReturnType: returnType,
      errorReporter: reporter,
      errorNode: astFactory.nullLiteral(new KeywordToken(Keyword.NULL, 0)),
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
      {DartType returnType, bool expectError: false}) {
    var typeArguments = _inferCall(
      ft,
      arguments,
      returnType: returnType,
      expectError: expectError,
    );
    return ft.instantiate(typeArguments);
  }
}

@reflectiveTest
class GreatestLowerBoundTest extends BoundTestBase {
  void test_bottom_function() {
    _checkGreatestLowerBound(
        neverStar, functionTypeStar(returnType: voidType), neverStar);
  }

  void test_bottom_interface() {
    var A = class_(name: 'A');
    _checkGreatestLowerBound(neverStar, interfaceType(A), neverStar);
  }

  void test_bottom_typeParam() {
    var T = typeParameter('T');
    _checkGreatestLowerBound(neverStar, typeParameterTypeStar(T), neverStar);
  }

  void test_bounds_of_top_types_complete() {
    // Test every combination of a subset of Tops programatically.
    var futureOrDynamicType = futureOrType(dynamicType);
    var futureOrObjectType = futureOrType(objectType);
    var futureOrVoidType = futureOrType(voidType);
    final futureOrFutureOrDynamicType = futureOrType(futureOrDynamicType);
    final futureOrFutureOrObjectType = futureOrType(futureOrObjectType);
    final futureOrFutureOrVoidType = futureOrType(futureOrVoidType);

    var orderedTops = [
      // Lower index, so lower Top
      voidType,
      dynamicType,
      objectType,
      futureOrVoidType,
      futureOrDynamicType,
      futureOrObjectType,
      futureOrFutureOrVoidType,
      futureOrFutureOrDynamicType,
      futureOrFutureOrObjectType,
      // Higher index, higher Top
    ];

    // We could sort and check the sort result is correct in O(n log n), but a
    // good sorting algorithm would only run n tests here (that each value is
    // correct relative to its nearest neighbors). But O(n^2) for n=6 is stupid
    // fast, in this case, so just do the brute force check because we can.
    for (var i = 0; i < orderedTops.length; ++i) {
      for (var lower = 0; lower <= i; ++lower) {
        _checkGreatestLowerBound(
            orderedTops[i], orderedTops[lower], orderedTops[i]);
        _checkLeastUpperBound(
            orderedTops[i], orderedTops[lower], orderedTops[lower]);
      }
      for (var greater = i; greater < orderedTops.length; ++greater) {
        _checkGreatestLowerBound(
            orderedTops[i], orderedTops[greater], orderedTops[greater]);
        _checkLeastUpperBound(
            orderedTops[i], orderedTops[greater], orderedTops[i]);
      }
    }
  }

  void test_bounds_of_top_types_sanity() {
    var futureOrDynamicType = futureOrType(dynamicType);
    final futureOrFutureOrDynamicType = futureOrType(futureOrDynamicType);

    // Sanity check specific cases of top for GLB/LUB.
    _checkLeastUpperBound(objectType, dynamicType, dynamicType);
    _checkGreatestLowerBound(objectType, dynamicType, objectType);
    _checkLeastUpperBound(objectType, voidType, voidType);
    _checkLeastUpperBound(futureOrDynamicType, dynamicType, dynamicType);
    _checkGreatestLowerBound(
        futureOrDynamicType, objectType, futureOrDynamicType);
    _checkGreatestLowerBound(futureOrDynamicType, futureOrFutureOrDynamicType,
        futureOrFutureOrDynamicType);
  }

  void test_classAndSuperclass() {
    // class A
    // class B extends A
    // class C extends B
    var A = class_(name: 'A');
    var B = class_(name: 'B', superType: interfaceType(A));
    var C = class_(name: 'C', superType: interfaceType(B));
    _checkGreatestLowerBound(
      interfaceType(A),
      interfaceType(C),
      interfaceType(C),
    );
  }

  void test_classAndSuperinterface() {
    // class A
    // class B implements A
    // class C implements B
    var A = class_(name: 'A');
    var B = class_(name: 'B', interfaces: [interfaceType(A)]);
    var C = class_(name: 'C', interfaces: [interfaceType(B)]);
    _checkGreatestLowerBound(
      interfaceType(A),
      interfaceType(C),
      interfaceType(C),
    );
  }

  void test_dynamic_bottom() {
    _checkGreatestLowerBound(dynamicType, neverStar, neverStar);
  }

  void test_dynamic_function() {
    _checkGreatestLowerBound(
        dynamicType,
        functionTypeStar(returnType: voidType),
        functionTypeStar(returnType: voidType));
  }

  void test_dynamic_interface() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);
    _checkGreatestLowerBound(dynamicType, typeA, typeA);
  }

  void test_dynamic_typeParam() {
    var T = typeParameter('T');
    var typeT = typeParameterTypeStar(T);
    _checkGreatestLowerBound(dynamicType, typeT, typeT);
  }

  void test_dynamic_void() {
    // Note: _checkGreatestLowerBound tests `GLB(x, y)` as well as `GLB(y, x)`
    _checkGreatestLowerBound(dynamicType, voidType, dynamicType);
  }

  void test_functionsDifferentNamedTakeUnion() {
    var type1 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intType),
        namedParameter(name: 'b', type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'b', type: doubleType),
        namedParameter(name: 'c', type: stringType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intType),
        namedParameter(name: 'b', type: numType),
        namedParameter(name: 'c', type: stringType),
      ],
      returnType: voidType,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsDifferentOptionalArityTakeMax() {
    var type1 = functionTypeStar(
      parameters: [
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        positionalParameter(type: doubleType),
        positionalParameter(type: stringType),
        positionalParameter(type: objectType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        positionalParameter(type: numType),
        positionalParameter(type: stringType),
        positionalParameter(type: objectType),
      ],
      returnType: voidType,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsDifferentRequiredArityBecomeOptional() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        requiredParameter(type: intType),
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        positionalParameter(type: intType),
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsFromDynamic() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: dynamicType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: dynamicType),
      ],
      returnType: voidType,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsGlbReturnType() {
    var type1 = functionTypeStar(
      returnType: intType,
    );
    var type2 = functionTypeStar(
      returnType: numType,
    );
    var expected = functionTypeStar(
      returnType: intType,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubNamedParams() {
    var type1 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: stringType),
        namedParameter(name: 'b', type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intType),
        namedParameter(name: 'b', type: numType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: objectType),
        namedParameter(name: 'b', type: numType),
      ],
      returnType: voidType,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubPositionalParams() {
    var type1 = functionTypeStar(
      parameters: [
        positionalParameter(type: stringType),
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        positionalParameter(type: intType),
        positionalParameter(type: numType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        positionalParameter(type: objectType),
        positionalParameter(type: numType),
      ],
      returnType: voidType,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubRequiredParams() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        requiredParameter(type: doubleType),
        requiredParameter(type: numType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: objectType),
        requiredParameter(type: numType),
        requiredParameter(type: numType),
      ],
      returnType: voidType,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsMixedOptionalAndRequiredBecomeOptional() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        requiredParameter(type: intType),
        positionalParameter(type: intType),
        positionalParameter(type: intType),
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        positionalParameter(type: intType),
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        positionalParameter(type: intType),
        positionalParameter(type: intType),
        positionalParameter(type: intType),
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsReturnBottomIfMixOptionalAndNamed() {
    // Dart doesn't allow a function to have both optional and named parameters,
    // so if we would have synthethized that, pick bottom instead.
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        namedParameter(name: 'a', type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intType),
      ],
      returnType: voidType,
    );
    _checkGreatestLowerBound(type1, type2, neverStar);
  }

  void test_functionsSameType_withNamed() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        namedParameter(name: 'n', type: numType),
      ],
      returnType: intType,
    );

    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        namedParameter(name: 'n', type: numType),
      ],
      returnType: intType,
    );

    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        namedParameter(name: 'n', type: numType),
      ],
      returnType: intType,
    );

    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsSameType_withOptional() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        positionalParameter(type: doubleType),
      ],
      returnType: intType,
    );

    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        positionalParameter(type: doubleType),
      ],
      returnType: intType,
    );

    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        positionalParameter(type: doubleType),
      ],
      returnType: intType,
    );

    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_interface_function() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);
    _checkGreatestLowerBound(
      typeA,
      functionTypeStar(returnType: voidType),
      neverStar,
    );
  }

  void test_mixin() {
    // class A
    // class B
    // class C
    // class D extends A with B, C
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B');
    var typeB = interfaceType(B);

    var C = class_(name: 'C');
    var typeC = interfaceType(C);

    var D = class_(
      name: 'D',
      superType: interfaceType(A),
      mixins: [typeB, typeC],
    );
    var typeD = interfaceType(D);

    _checkGreatestLowerBound(typeA, typeD, typeD);
    _checkGreatestLowerBound(typeB, typeD, typeD);
    _checkGreatestLowerBound(typeC, typeD, typeD);
  }

  void test_self() {
    var T = typeParameter('T');
    var A = class_(name: 'A');

    List<DartType> types = [
      dynamicType,
      voidType,
      neverStar,
      typeParameterTypeStar(T),
      interfaceType(A),
      functionTypeStar(returnType: voidType),
    ];

    for (DartType type in types) {
      _checkGreatestLowerBound(type, type, type);
    }
  }

  void test_typeParam_function_noBound() {
    var T = typeParameter('T');
    _checkGreatestLowerBound(
      typeParameterTypeStar(T),
      functionTypeStar(returnType: voidType),
      neverStar,
    );
  }

  void test_typeParam_interface_bounded() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', superType: typeB);
    var typeC = interfaceType(C);

    var T = typeParameter('T', bound: typeB);
    _checkGreatestLowerBound(typeParameterTypeStar(T), typeC, neverStar);
  }

  void test_typeParam_interface_noBound() {
    // GLB(T, A) = ⊥
    var T = typeParameter('T');
    var A = class_(name: 'A');
    _checkGreatestLowerBound(
      typeParameterTypeStar(T),
      interfaceType(A),
      neverStar,
    );
  }

  void test_typeParameters_different() {
    // GLB(List<int>, List<double>) = ⊥
    var listOfIntType = listType(intType);
    var listOfDoubleType = listType(doubleType);
    // TODO(rnystrom): Can we do something better here?
    _checkGreatestLowerBound(listOfIntType, listOfDoubleType, neverStar);
  }

  void test_typeParameters_same() {
    // GLB(List<int>, List<int>) = List<int>
    var listOfIntType = listType(intType);
    _checkGreatestLowerBound(listOfIntType, listOfIntType, listOfIntType);
  }

  void test_unrelatedClasses() {
    // class A
    // class B
    // class C
    var A = class_(name: 'A');
    var B = class_(name: 'B');
    _checkGreatestLowerBound(interfaceType(A), interfaceType(B), neverStar);
  }

  void test_void() {
    var A = class_(name: 'A');
    var T = typeParameter('T');
    List<DartType> types = [
      neverStar,
      functionTypeStar(returnType: voidType),
      interfaceType(A),
      typeParameterTypeStar(T),
    ];
    for (DartType type in types) {
      _checkGreatestLowerBound(
        functionTypeStar(returnType: voidType),
        functionTypeStar(returnType: type),
        functionTypeStar(returnType: type),
      );
    }
  }
}

@reflectiveTest
class LeastUpperBoundFunctionsTest extends BoundTestBase {
  void test_differentRequiredArity() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        requiredParameter(type: intType),
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    _checkLeastUpperBound(type1, type2, typeProvider.functionType);
  }

  void test_fuzzyArrows() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: dynamicType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_glbNamedParams() {
    var type1 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: stringType),
        namedParameter(name: 'b', type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intType),
        namedParameter(name: 'b', type: numType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: neverStar),
        namedParameter(name: 'b', type: intType),
      ],
      returnType: voidType,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_glbPositionalParams() {
    var type1 = functionTypeStar(
      parameters: [
        positionalParameter(type: stringType),
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        positionalParameter(type: intType),
        positionalParameter(type: numType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        positionalParameter(type: neverStar),
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_glbRequiredParams() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
        requiredParameter(type: doubleType),
        requiredParameter(type: numType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: neverStar),
        requiredParameter(type: neverStar),
        requiredParameter(type: intType),
      ],
      returnType: voidType,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_ignoreExtraNamedParams() {
    var type1 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intType),
        namedParameter(name: 'b', type: intType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intType),
        namedParameter(name: 'c', type: intType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intType),
      ],
      returnType: voidType,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_ignoreExtraPositionalParams() {
    var type1 = functionTypeStar(
      parameters: [
        positionalParameter(type: intType),
        positionalParameter(type: intType),
        positionalParameter(type: stringType),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        positionalParameter(type: intType),
      ],
      returnType: voidType,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_lubReturnType() {
    var type1 = functionTypeStar(returnType: intType);
    var type2 = functionTypeStar(returnType: doubleType);
    var expected = functionTypeStar(returnType: numType);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_sameType_withNamed() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        namedParameter(name: 'n', type: numType),
      ],
      returnType: intType,
    );

    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        namedParameter(name: 'n', type: numType),
      ],
      returnType: intType,
    );

    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        namedParameter(name: 'n', type: numType),
      ],
      returnType: intType,
    );

    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_sameType_withOptional() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        positionalParameter(type: doubleType),
      ],
      returnType: intType,
    );

    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        positionalParameter(type: doubleType),
      ],
      returnType: intType,
    );

    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: stringType),
        requiredParameter(type: intType),
        requiredParameter(type: numType),
        positionalParameter(type: doubleType),
      ],
      returnType: intType,
    );

    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_typeFormals_differentBounds() {
    var T1 = typeParameter('T1', bound: intType);
    var type1 = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    var T2 = typeParameter('T2', bound: doubleType);
    var type2 = functionTypeStar(
      typeFormals: [T2],
      returnType: typeParameterTypeStar(T2),
    );

    _checkLeastUpperBound(type1, type2, typeProvider.functionType);
  }

  void test_typeFormals_differentNumber() {
    var T1 = typeParameter('T1', bound: numType);
    var type1 = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    var type2 = functionTypeStar(returnType: intType);

    _checkLeastUpperBound(type1, type2, typeProvider.functionType);
  }

  void test_typeFormals_sameBounds() {
    var T1 = typeParameter('T1', bound: numType);
    var type1 = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    var T2 = typeParameter('T2', bound: numType);
    var type2 = functionTypeStar(
      typeFormals: [T2],
      returnType: typeParameterTypeStar(T2),
    );

    var TE = typeParameter('T', bound: numType);
    var expected = functionTypeStar(
      typeFormals: [TE],
      returnType: typeParameterTypeStar(TE),
    );

    _checkLeastUpperBound(type1, type2, expected);
  }
}

@reflectiveTest
class LeastUpperBoundTest extends BoundTestBase {
  void test_bottom_function() {
    _checkLeastUpperBound(neverStar, functionTypeStar(returnType: voidType),
        functionTypeStar(returnType: voidType));
  }

  void test_bottom_interface() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);
    _checkLeastUpperBound(neverStar, typeA, typeA);
  }

  void test_bottom_typeParam() {
    var T = typeParameter('T');
    var typeT = typeParameterTypeStar(T);
    _checkLeastUpperBound(neverStar, typeT, typeT);
  }

  void test_directInterfaceCase() {
    // class A
    // class B implements A
    // class C implements B

    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', interfaces: [typeA]);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', interfaces: [typeB]);
    var typeC = interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_directSubclassCase() {
    // class A
    // class B extends A
    // class C extends B

    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', superType: typeB);
    var typeC = interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_directSuperclass_nullability() {
    var aElement = class_(name: 'A');
    var aQuestion = interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.question,
    );
    var aStar = interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    var aNone = interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var bElementStar = class_(name: 'B', superType: aStar);
    var bElementNone = class_(name: 'B', superType: aNone);

    InterfaceTypeImpl _bTypeStarElement(NullabilitySuffix nullability) {
      return interfaceType(
        bElementStar,
        nullabilitySuffix: nullability,
      );
    }

    InterfaceTypeImpl _bTypeNoneElement(NullabilitySuffix nullability) {
      return interfaceType(
        bElementNone,
        nullabilitySuffix: nullability,
      );
    }

    var bStarQuestion = _bTypeStarElement(NullabilitySuffix.question);
    var bStarStar = _bTypeStarElement(NullabilitySuffix.star);
    var bStarNone = _bTypeStarElement(NullabilitySuffix.none);

    var bNoneQuestion = _bTypeNoneElement(NullabilitySuffix.question);
    var bNoneStar = _bTypeNoneElement(NullabilitySuffix.star);
    var bNoneNone = _bTypeNoneElement(NullabilitySuffix.none);

    void assertLUB(DartType type1, DartType type2, DartType expected) {
      expect(typeSystem.getLeastUpperBound(type1, type2), expected);
      expect(typeSystem.getLeastUpperBound(type2, type1), expected);
    }

    assertLUB(bStarQuestion, aQuestion, aQuestion);
    assertLUB(bStarQuestion, aStar, aQuestion);
    assertLUB(bStarQuestion, aNone, aQuestion);

    assertLUB(bStarStar, aQuestion, aQuestion);
    assertLUB(bStarStar, aStar, aStar);
    assertLUB(bStarStar, aNone, aStar);

    assertLUB(bStarNone, aQuestion, aQuestion);
    assertLUB(bStarNone, aStar, aStar);
    assertLUB(bStarNone, aNone, aNone);

    assertLUB(bNoneQuestion, aQuestion, aQuestion);
    assertLUB(bNoneQuestion, aStar, aQuestion);
    assertLUB(bNoneQuestion, aNone, aQuestion);

    assertLUB(bNoneStar, aQuestion, aQuestion);
    assertLUB(bNoneStar, aStar, aStar);
    assertLUB(bNoneStar, aNone, aStar);

    assertLUB(bNoneNone, aQuestion, aQuestion);
    assertLUB(bNoneNone, aStar, aStar);
    assertLUB(bNoneNone, aNone, aNone);
  }

  void test_dynamic_bottom() {
    _checkLeastUpperBound(dynamicType, neverStar, dynamicType);
  }

  void test_dynamic_function() {
    _checkLeastUpperBound(
        dynamicType, functionTypeStar(returnType: voidType), dynamicType);
  }

  void test_dynamic_interface() {
    var A = class_(name: 'A');
    _checkLeastUpperBound(dynamicType, interfaceType(A), dynamicType);
  }

  void test_dynamic_typeParam() {
    var T = typeParameter('T');
    _checkLeastUpperBound(dynamicType, typeParameterTypeStar(T), dynamicType);
  }

  void test_dynamic_void() {
    // Note: _checkLeastUpperBound tests `LUB(x, y)` as well as `LUB(y, x)`
    _checkLeastUpperBound(dynamicType, voidType, voidType);
  }

  void test_interface_function() {
    var A = class_(name: 'A');
    _checkLeastUpperBound(
        interfaceType(A), functionTypeStar(returnType: voidType), objectType);
  }

  void test_interface_sameElement_nullability() {
    var aElement = class_(name: 'A');

    var aQuestion = interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.question,
    );
    var aStar = interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    var aNone = interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.none,
    );

    void assertLUB(DartType type1, DartType type2, DartType expected) {
      expect(typeSystem.getLeastUpperBound(type1, type2), expected);
      expect(typeSystem.getLeastUpperBound(type2, type1), expected);
    }

    assertLUB(aQuestion, aQuestion, aQuestion);
    assertLUB(aQuestion, aStar, aQuestion);
    assertLUB(aQuestion, aNone, aQuestion);

    assertLUB(aStar, aQuestion, aQuestion);
    assertLUB(aStar, aStar, aStar);
    assertLUB(aStar, aNone, aStar);

    assertLUB(aNone, aQuestion, aQuestion);
    assertLUB(aNone, aStar, aStar);
    assertLUB(aNone, aNone, aNone);
  }

  void test_mixinAndClass_constraintAndInterface() {
    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, []);

    var classB = class_(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );

    var mixinM = ElementFactory.mixinElement(
      name: 'M',
      constraints: [instA.withNullabilitySuffixNone],
    );

    _checkLeastUpperBound(
      interfaceType(
        classB,
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      interfaceType(
        mixinM,
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      instA.withNullability(NullabilitySuffix.star),
    );
  }

  void test_mixinAndClass_object() {
    var classA = class_(name: 'A');
    var mixinM = ElementFactory.mixinElement(name: 'M');

    _checkLeastUpperBound(
      interfaceType(classA),
      interfaceType(mixinM),
      objectType,
    );
  }

  void test_mixinAndClass_sharedInterface() {
    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, []);

    var classB = class_(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );

    var mixinM = ElementFactory.mixinElement(
      name: 'M',
      interfaces: [instA.withNullabilitySuffixNone],
    );

    _checkLeastUpperBound(
      interfaceType(
        classB,
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      interfaceType(
        mixinM,
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      instA.withNullability(NullabilitySuffix.star),
    );
  }

  void test_mixinCase() {
    // class A
    // class B extends A
    // class C extends A
    // class D extends B with M, N, O, P

    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', superType: typeA);
    var typeC = interfaceType(C);

    var D = class_(
      name: 'D',
      superType: typeB,
      mixins: [
        interfaceType(class_(name: 'M')),
        interfaceType(class_(name: 'N')),
        interfaceType(class_(name: 'O')),
        interfaceType(class_(name: 'P')),
      ],
    );
    var typeD = interfaceType(D);

    _checkLeastUpperBound(typeD, typeC, typeA);
  }

  void test_nestedFunctionsLubInnerParamTypes() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: stringType),
              requiredParameter(type: intType),
              requiredParameter(type: intType),
            ],
            returnType: voidType,
          ),
        ),
      ],
      returnType: voidType,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: intType),
              requiredParameter(type: doubleType),
              requiredParameter(type: numType),
            ],
            returnType: voidType,
          ),
        ),
      ],
      returnType: voidType,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: objectType),
              requiredParameter(type: numType),
              requiredParameter(type: numType),
            ],
            returnType: voidType,
          ),
        ),
      ],
      returnType: voidType,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_nestedNestedFunctionsGlbInnermostParamTypes() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(
                type: functionTypeStar(
                  parameters: [
                    requiredParameter(type: stringType),
                    requiredParameter(type: intType),
                    requiredParameter(type: intType)
                  ],
                  returnType: voidType,
                ),
              ),
            ],
            returnType: voidType,
          ),
        ),
      ],
      returnType: voidType,
    );
    expect(
      type1.toString(withNullability: true),
      'void Function(void Function(void Function(String*, int*, int*)*)*)*',
    );

    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(
                type: functionTypeStar(
                  parameters: [
                    requiredParameter(type: intType),
                    requiredParameter(type: doubleType),
                    requiredParameter(type: numType)
                  ],
                  returnType: voidType,
                ),
              ),
            ],
            returnType: voidType,
          ),
        ),
      ],
      returnType: voidType,
    );
    expect(
      type2.toString(withNullability: true),
      'void Function(void Function(void Function(int*, double*, num*)*)*)*',
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(
                type: functionTypeStar(
                  parameters: [
                    requiredParameter(type: neverStar),
                    requiredParameter(type: neverStar),
                    requiredParameter(type: intType)
                  ],
                  returnType: voidType,
                ),
              ),
            ],
            returnType: voidType,
          ),
        ),
      ],
      returnType: voidType,
    );
    expect(
      expected.toString(withNullability: true),
      'void Function(void Function(void Function(Never*, Never*, int*)*)*)*',
    );

    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_object() {
    var A = class_(name: 'A');
    var B = class_(name: 'B');
    var typeA = interfaceType(A);
    var typeB = interfaceType(B);
    var typeObject = typeA.element.supertype;
    // assert that object does not have a super type
    expect(typeObject.element.supertype, isNull);
    // assert that both A and B have the same super type of Object
    expect(typeB.element.supertype, typeObject);
    // finally, assert that the only least upper bound of A and B is Object
    _checkLeastUpperBound(typeA, typeB, typeObject);
  }

  void test_self() {
    var T = typeParameter('T');
    var A = class_(name: 'A');

    List<DartType> types = [
      dynamicType,
      voidType,
      neverStar,
      typeParameterTypeStar(T),
      interfaceType(A),
      functionTypeStar(returnType: voidType)
    ];

    for (DartType type in types) {
      _checkLeastUpperBound(type, type, type);
    }
  }

  void test_sharedSuperclass1() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', superType: typeA);
    var typeC = interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperclass1_nullability() {
    var aElement = class_(name: 'A');
    var aQuestion = interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.question,
    );
    var aStar = interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    var aNone = interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var bElementNone = class_(name: 'B', superType: aNone);
    var bElementStar = class_(name: 'B', superType: aStar);

    var cElementNone = class_(name: 'C', superType: aNone);
    var cElementStar = class_(name: 'C', superType: aStar);

    InterfaceTypeImpl bTypeElementNone(NullabilitySuffix nullability) {
      return interfaceType(
        bElementNone,
        nullabilitySuffix: nullability,
      );
    }

    InterfaceTypeImpl bTypeElementStar(NullabilitySuffix nullability) {
      return interfaceType(
        bElementStar,
        nullabilitySuffix: nullability,
      );
    }

    var bNoneQuestion = bTypeElementNone(NullabilitySuffix.question);
    var bNoneStar = bTypeElementNone(NullabilitySuffix.star);
    var bNoneNone = bTypeElementNone(NullabilitySuffix.none);

    var bStarQuestion = bTypeElementStar(NullabilitySuffix.question);
    var bStarStar = bTypeElementStar(NullabilitySuffix.star);
    var bStarNone = bTypeElementStar(NullabilitySuffix.none);

    InterfaceTypeImpl cTypeElementNone(NullabilitySuffix nullability) {
      return interfaceType(
        cElementNone,
        nullabilitySuffix: nullability,
      );
    }

    InterfaceTypeImpl cTypeElementStar(NullabilitySuffix nullability) {
      return interfaceType(
        cElementStar,
        nullabilitySuffix: nullability,
      );
    }

    var cNoneQuestion = cTypeElementNone(NullabilitySuffix.question);
    var cNoneStar = cTypeElementNone(NullabilitySuffix.star);
    var cNoneNone = cTypeElementNone(NullabilitySuffix.none);

    var cStarQuestion = cTypeElementStar(NullabilitySuffix.question);
    var cStarStar = cTypeElementStar(NullabilitySuffix.star);
    var cStarNone = cTypeElementStar(NullabilitySuffix.none);

    void assertLUB(DartType type1, DartType type2, DartType expected) {
      expect(typeSystem.getLeastUpperBound(type1, type2), expected);
      expect(typeSystem.getLeastUpperBound(type2, type1), expected);
    }

    assertLUB(bNoneQuestion, cNoneQuestion, aQuestion);
    assertLUB(bNoneQuestion, cNoneStar, aQuestion);
    assertLUB(bNoneQuestion, cNoneNone, aQuestion);
    assertLUB(bNoneQuestion, cStarQuestion, aQuestion);
    assertLUB(bNoneQuestion, cStarStar, aQuestion);
    assertLUB(bNoneQuestion, cStarNone, aQuestion);

    assertLUB(bNoneStar, cNoneQuestion, aQuestion);
    assertLUB(bNoneStar, cNoneStar, aStar);
    assertLUB(bNoneStar, cNoneNone, aStar);
    assertLUB(bNoneStar, cStarQuestion, aQuestion);
    assertLUB(bNoneStar, cStarStar, aStar);
    assertLUB(bNoneStar, cStarNone, aStar);

    assertLUB(bNoneNone, cNoneQuestion, aQuestion);
    assertLUB(bNoneNone, cNoneStar, aStar);
    assertLUB(bNoneNone, cNoneNone, aNone);
    assertLUB(bNoneNone, cStarQuestion, aQuestion);
    assertLUB(bNoneNone, cStarStar, aStar);
    assertLUB(bNoneNone, cStarNone, aNone);

    assertLUB(bStarQuestion, cNoneQuestion, aQuestion);
    assertLUB(bStarQuestion, cNoneStar, aQuestion);
    assertLUB(bStarQuestion, cNoneNone, aQuestion);
    assertLUB(bStarQuestion, cStarQuestion, aQuestion);
    assertLUB(bStarQuestion, cStarStar, aQuestion);
    assertLUB(bStarQuestion, cStarNone, aQuestion);

    assertLUB(bStarStar, cNoneQuestion, aQuestion);
    assertLUB(bStarStar, cNoneStar, aStar);
    assertLUB(bStarStar, cNoneNone, aStar);
    assertLUB(bStarStar, cStarQuestion, aQuestion);
    assertLUB(bStarStar, cStarStar, aStar);
    assertLUB(bStarStar, cStarNone, aStar);

    assertLUB(bStarNone, cNoneQuestion, aQuestion);
    assertLUB(bStarNone, cNoneStar, aStar);
    assertLUB(bStarNone, cNoneNone, aNone);
    assertLUB(bStarNone, cStarQuestion, aQuestion);
    assertLUB(bStarNone, cStarStar, aStar);
    assertLUB(bStarNone, cStarNone, aNone);
  }

  void test_sharedSuperclass2() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', superType: typeA);
    var typeC = interfaceType(C);

    var D = class_(name: 'D', superType: typeC);
    var typeD = interfaceType(D);

    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperclass3() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', superType: typeB);
    var typeC = interfaceType(C);

    var D = class_(name: 'D', superType: typeB);
    var typeD = interfaceType(D);

    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperclass4() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var A2 = class_(name: 'A2');
    var typeA2 = interfaceType(A2);

    var A3 = class_(name: 'A3');
    var typeA3 = interfaceType(A3);

    var B = class_(name: 'B', superType: typeA, interfaces: [typeA2]);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', superType: typeA, interfaces: [typeA3]);
    var typeC = interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface1() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', interfaces: [typeA]);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', interfaces: [typeA]);
    var typeC = interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface2() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', interfaces: [typeA]);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', interfaces: [typeA]);
    var typeC = interfaceType(C);

    var D = class_(name: 'D', interfaces: [typeC]);
    var typeD = interfaceType(D);

    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperinterface3() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', interfaces: [typeA]);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', interfaces: [typeB]);
    var typeC = interfaceType(C);

    var D = class_(name: 'D', interfaces: [typeB]);
    var typeD = interfaceType(D);

    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperinterface4() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var A2 = class_(name: 'A2');
    var typeA2 = interfaceType(A2);

    var A3 = class_(name: 'A3');
    var typeA3 = interfaceType(A3);

    var B = class_(name: 'B', interfaces: [typeA, typeA2]);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', interfaces: [typeA, typeA3]);
    var typeC = interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_twoComparables() {
    _checkLeastUpperBound(stringType, numType, objectType);
  }

  void test_typeParam_boundedByParam() {
    var S = typeParameter('S');
    var typeS = typeParameterTypeStar(S);

    var T = typeParameter('T', bound: typeS);
    var typeT = typeParameterTypeStar(T);

    _checkLeastUpperBound(typeT, typeS, typeS);
  }

  void test_typeParam_class_implements_Function_ignored() {
    var A = class_(name: 'A', superType: typeProvider.functionType);
    var T = typeParameter('T', bound: interfaceType(A));
    _checkLeastUpperBound(typeParameterTypeStar(T),
        functionTypeStar(returnType: voidType), objectType);
  }

  void test_typeParam_fBounded() {
    var T = typeParameter('Q');
    var A = class_(name: 'A', typeParameters: [T]);

    var S = typeParameter('S');
    var typeS = typeParameterTypeStar(S);
    S.bound = interfaceType(A, typeArguments: [typeS]);

    var U = typeParameter('U');
    var typeU = typeParameterTypeStar(U);
    U.bound = interfaceType(A, typeArguments: [typeU]);

    _checkLeastUpperBound(
      typeS,
      typeParameterTypeStar(U),
      interfaceType(A, typeArguments: [objectType]),
    );
  }

  void test_typeParam_function_bounded() {
    var T = typeParameter('T', bound: typeProvider.functionType);
    _checkLeastUpperBound(
      typeParameterTypeStar(T),
      functionTypeStar(returnType: voidType),
      typeProvider.functionType,
    );
  }

  void test_typeParam_function_noBound() {
    var T = typeParameter('T');
    _checkLeastUpperBound(
      typeParameterTypeStar(T),
      functionTypeStar(returnType: voidType),
      objectType,
    );
  }

  void test_typeParam_interface_bounded() {
    var A = class_(name: 'A');
    var typeA = interfaceType(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceType(B);

    var C = class_(name: 'C', superType: typeA);
    var typeC = interfaceType(C);

    var T = typeParameter('T', bound: typeB);
    var typeT = typeParameterTypeStar(T);

    _checkLeastUpperBound(typeT, typeC, typeA);
  }

  void test_typeParam_interface_noBound() {
    var T = typeParameter('T');
    var A = class_(name: 'A');
    _checkLeastUpperBound(
      typeParameterTypeStar(T),
      interfaceType(A),
      objectType,
    );
  }

  /// Check least upper bound of the same class with different type parameters.
  void test_typeParameters_different() {
    // class List<int>
    // class List<double>
    var listOfIntType = listType(intType);
    var listOfDoubleType = listType(doubleType);
    var listOfNum = listType(numType);
    _checkLeastUpperBound(listOfIntType, listOfDoubleType, listOfNum);
  }

  void test_typeParameters_same() {
    // List<int>
    // List<int>
    var listOfIntType = listType(intType);
    _checkLeastUpperBound(listOfIntType, listOfIntType, listOfIntType);
  }

  /// Check least upper bound of two related classes with different
  /// type parameters.
  void test_typeParametersAndClass_different() {
    // class List<int>
    // class Iterable<double>
    var listOfIntType = listType(intType);
    var iterableOfDoubleType = iterableType(doubleType);
    // TODO(leafp): this should be iterableOfNumType
    _checkLeastUpperBound(listOfIntType, iterableOfDoubleType, objectType);
  }

  void test_void() {
    var T = typeParameter('T');
    var A = class_(name: 'A');
    List<DartType> types = [
      neverStar,
      functionTypeStar(returnType: voidType),
      interfaceType(A),
      typeParameterTypeStar(T),
    ];
    for (DartType type in types) {
      _checkLeastUpperBound(
        functionTypeStar(returnType: voidType),
        functionTypeStar(returnType: type),
        functionTypeStar(returnType: voidType),
      );
    }
  }
}

//class Mix with ElementsTypesMixin {
//  TypeProvider typeProvider;
//  Dart2TypeSystem typeSystem;
//
//  FeatureSet get testFeatureSet {
//    return FeatureSet.forTesting();
//  }
//
//  void setUp() {
//    var analysisContext = TestAnalysisContext(
//      featureSet: testFeatureSet,
//    );
//    typeProvider = analysisContext.typeProvider;
//    typeSystem = analysisContext.typeSystem;
//  }
//}

class SubtypingTestBase extends AbstractTypeSystemTest {
  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsSubtypeOf(type2, type1);
  }

  void _checkGroups(DartType t1,
      {List<DartType> equivalents,
      List<DartType> unrelated,
      List<DartType> subtypes,
      List<DartType> supertypes}) {
    if (equivalents != null) {
      for (DartType t2 in equivalents) {
        _checkEquivalent(t1, t2);
      }
    }
    if (unrelated != null) {
      for (DartType t2 in unrelated) {
        _checkUnrelated(t1, t2);
      }
    }
    if (subtypes != null) {
      for (DartType t2 in subtypes) {
        _checkIsStrictSubtypeOf(t2, t1);
      }
    }
    if (supertypes != null) {
      for (DartType t2 in supertypes) {
        _checkIsStrictSubtypeOf(t1, t2);
      }
    }
  }

  void _checkIsNotSubtypeOf(DartType type1, DartType type2) {
    var strType1 = _toStringWithNullability(type1);
    var strType2 = _toStringWithNullability(type2);
    expect(typeSystem.isSubtypeOf(type1, type2), false,
        reason: '$strType1 was not supposed to be a subtype of $strType2');
  }

  void _checkIsStrictSubtypeOf(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  void _checkIsSubtypeOf(DartType type1, DartType type2) {
    expect(typeSystem.isSubtypeOf(type1, type2), true,
        reason: '$type1 is not a subtype of $type2');
  }

  void _checkLattice(
      DartType top, DartType left, DartType right, DartType bottom) {
    _checkGroups(top,
        equivalents: <DartType>[top],
        subtypes: <DartType>[left, right, bottom]);
    _checkGroups(left,
        equivalents: <DartType>[left],
        subtypes: <DartType>[bottom],
        unrelated: <DartType>[right],
        supertypes: <DartType>[top]);
    _checkGroups(right,
        equivalents: <DartType>[right],
        subtypes: <DartType>[bottom],
        unrelated: <DartType>[left],
        supertypes: <DartType>[top]);
    _checkGroups(bottom,
        equivalents: <DartType>[bottom],
        supertypes: <DartType>[top, left, right]);
  }

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  static String _toStringWithNullability(DartType type) {
    return (type as TypeImpl).toString(withNullability: true);
  }
}

@reflectiveTest
class TypeSystemTest extends AbstractTypeSystemTest {
  InterfaceTypeImpl get functionClassTypeNone {
    return interfaceType(
      typeProvider.functionType.element,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get functionClassTypeQuestion {
    return interfaceType(
      typeProvider.functionType.element,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl get functionClassTypeStar {
    return interfaceType(
      typeProvider.functionType.element,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  DartType get noneType => (typeProvider.stringType as TypeImpl)
      .withNullability(NullabilitySuffix.none);

  FunctionTypeImpl get nothingToVoidFunctionTypeNone {
    return functionTypeNone(
      returnType: voidType,
    );
  }

  FunctionTypeImpl get nothingToVoidFunctionTypeQuestion {
    return functionTypeQuestion(
      returnType: voidType,
    );
  }

  FunctionTypeImpl get nothingToVoidFunctionTypeStar {
    return functionTypeStar(
      returnType: voidType,
    );
  }

  DartType get objectClassTypeNone => (typeProvider.objectType as TypeImpl)
      .withNullability(NullabilitySuffix.none);

  DartType get objectClassTypeQuestion => (typeProvider.objectType as TypeImpl)
      .withNullability(NullabilitySuffix.question);

  DartType get objectClassTypeStar => (typeProvider.objectType as TypeImpl)
      .withNullability(NullabilitySuffix.star);

  DartType get questionType => (typeProvider.stringType as TypeImpl)
      .withNullability(NullabilitySuffix.question);

  DartType get starType => (typeProvider.stringType as TypeImpl)
      .withNullability(NullabilitySuffix.star);

  InterfaceTypeImpl get stringClassTypeNone {
    return interfaceType(
      typeProvider.stringType.element,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get stringClassTypeQuestion {
    return interfaceType(
      typeProvider.stringType.element,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl get stringClassTypeStar {
    return interfaceType(
      typeProvider.stringType.element,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceTypeImpl futureOrTypeNone({@required DartType argument}) {
    var element = typeProvider.futureOrElement;
    return interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrTypeQuestion({@required DartType argument}) {
    var element = typeProvider.futureOrElement;
    return interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureOrTypeStar({@required DartType argument}) {
    var element = typeProvider.futureOrElement;
    return interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceTypeImpl listClassTypeNone(DartType argument) {
    var element = typeProvider.listElement;
    return interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl listClassTypeQuestion(DartType argument) {
    var element = typeProvider.listElement;
    return interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl listClassTypeStar(DartType argument) {
    var element = typeProvider.listElement;
    return interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  test_isNonNullable_dynamic() {
    expect(typeSystem.isNonNullable(dynamicType), false);
  }

  test_isNonNullable_function_none() {
    expect(typeSystem.isNonNullable(nothingToVoidFunctionTypeNone), true);
  }

  test_isNonNullable_function_question() {
    expect(typeSystem.isNonNullable(nothingToVoidFunctionTypeQuestion), false);
  }

  test_isNonNullable_function_star() {
    expect(typeSystem.isNonNullable(nothingToVoidFunctionTypeStar), true);
  }

  test_isNonNullable_functionClass_none() {
    expect(typeSystem.isNonNullable(functionClassTypeNone), true);
  }

  test_isNonNullable_functionClass_question() {
    expect(typeSystem.isNonNullable(functionClassTypeQuestion), false);
  }

  test_isNonNullable_functionClass_star() {
    expect(typeSystem.isNonNullable(functionClassTypeStar), true);
  }

  test_isNonNullable_futureOr_noneArgument_none() {
    expect(
      typeSystem.isNonNullable(
        futureOrTypeNone(argument: noneType),
      ),
      true,
    );
  }

  test_isNonNullable_futureOr_noneArgument_question() {
    expect(
      typeSystem.isNonNullable(
        futureOrTypeQuestion(argument: noneType),
      ),
      false,
    );
  }

  test_isNonNullable_futureOr_noneArgument_star() {
    expect(
      typeSystem.isNonNullable(
        futureOrTypeStar(argument: noneType),
      ),
      true,
    );
  }

  test_isNonNullable_futureOr_questionArgument_none() {
    expect(
      typeSystem.isNonNullable(
        futureOrTypeNone(argument: questionType),
      ),
      false,
    );
  }

  test_isNonNullable_futureOr_questionArgument_question() {
    expect(
      typeSystem.isNonNullable(
        futureOrTypeQuestion(argument: questionType),
      ),
      false,
    );
  }

  test_isNonNullable_futureOr_questionArgument_star() {
    expect(
      typeSystem.isNonNullable(
        futureOrTypeStar(argument: questionType),
      ),
      false,
    );
  }

  test_isNonNullable_futureOr_starArgument_none() {
    expect(
      typeSystem.isNonNullable(
        futureOrTypeNone(argument: starType),
      ),
      true,
    );
  }

  test_isNonNullable_futureOr_starArgument_question() {
    expect(
      typeSystem.isNonNullable(
        futureOrTypeStar(argument: questionType),
      ),
      false,
    );
  }

  test_isNonNullable_futureOr_starArgument_star() {
    expect(
      typeSystem.isNonNullable(
        futureOrTypeStar(argument: starType),
      ),
      true,
    );
  }

  test_isNonNullable_interface_none() {
    expect(typeSystem.isNonNullable(noneType), true);
  }

  test_isNonNullable_interface_question() {
    expect(typeSystem.isNonNullable(questionType), false);
  }

  test_isNonNullable_interface_star() {
    expect(typeSystem.isNonNullable(starType), true);
  }

  test_isNonNullable_never() {
    expect(typeSystem.isNonNullable(neverNone), true);
  }

  test_isNonNullable_null() {
    expect(typeSystem.isNonNullable(nullType), false);
  }

  test_isNonNullable_typeParameter_noneBound_none() {
    expect(
      typeSystem.isNonNullable(
        _typeParameterTypeNone(bound: noneType),
      ),
      true,
    );
  }

  test_isNonNullable_typeParameter_noneBound_question() {
    expect(
      typeSystem.isNonNullable(
        _typeParameterTypeQuestion(bound: noneType),
      ),
      false,
    );
  }

  test_isNonNullable_typeParameter_questionBound_none() {
    expect(
      typeSystem.isNonNullable(
        _typeParameterTypeNone(bound: questionType),
      ),
      false,
    );
  }

  test_isNonNullable_typeParameter_questionBound_question() {
    expect(
      typeSystem.isNonNullable(
        _typeParameterTypeQuestion(bound: questionType),
      ),
      false,
    );
  }

  test_isNonNullable_typeParameter_starBound_star() {
    expect(
      typeSystem.isNonNullable(
        _typeParameterTypeStar(bound: starType),
      ),
      true,
    );
  }

  test_isNonNullable_void() {
    expect(typeSystem.isNonNullable(voidType), false);
  }

  test_isNullable_dynamic() {
    expect(typeSystem.isNullable(dynamicType), true);
  }

  test_isNullable_function_none() {
    expect(typeSystem.isNullable(nothingToVoidFunctionTypeNone), false);
  }

  test_isNullable_function_question() {
    expect(typeSystem.isNullable(nothingToVoidFunctionTypeQuestion), true);
  }

  test_isNullable_function_star() {
    expect(typeSystem.isNullable(nothingToVoidFunctionTypeStar), false);
  }

  test_isNullable_functionClass_none() {
    expect(typeSystem.isNullable(functionClassTypeNone), false);
  }

  test_isNullable_functionClass_question() {
    expect(typeSystem.isNullable(functionClassTypeQuestion), true);
  }

  test_isNullable_functionClass_star() {
    expect(typeSystem.isNullable(functionClassTypeStar), false);
  }

  test_isNullable_futureOr_noneArgument_none() {
    expect(
      typeSystem.isNullable(
        futureOrTypeNone(argument: noneType),
      ),
      false,
    );
  }

  test_isNullable_futureOr_noneArgument_question() {
    expect(
      typeSystem.isNullable(
        futureOrTypeQuestion(argument: noneType),
      ),
      true,
    );
  }

  test_isNullable_futureOr_noneArgument_star() {
    expect(
      typeSystem.isNullable(
        futureOrTypeStar(argument: noneType),
      ),
      false,
    );
  }

  test_isNullable_futureOr_questionArgument_none() {
    expect(
      typeSystem.isNullable(
        futureOrTypeNone(argument: questionType),
      ),
      true,
    );
  }

  test_isNullable_futureOr_questionArgument_question() {
    expect(
      typeSystem.isNullable(
        futureOrTypeQuestion(argument: questionType),
      ),
      true,
    );
  }

  test_isNullable_futureOr_questionArgument_star() {
    expect(
      typeSystem.isNullable(
        futureOrTypeStar(argument: questionType),
      ),
      true,
    );
  }

  test_isNullable_futureOr_starArgument_none() {
    expect(
      typeSystem.isNullable(
        futureOrTypeNone(argument: starType),
      ),
      false,
    );
  }

  test_isNullable_futureOr_starArgument_question() {
    expect(
      typeSystem.isNullable(
        futureOrTypeQuestion(argument: starType),
      ),
      true,
    );
  }

  test_isNullable_futureOr_starArgument_star() {
    expect(
      typeSystem.isNullable(
        futureOrTypeStar(argument: starType),
      ),
      false,
    );
  }

  test_isNullable_interface_none() {
    expect(typeSystem.isNullable(noneType), false);
  }

  test_isNullable_interface_question() {
    expect(typeSystem.isNullable(questionType), true);
  }

  test_isNullable_interface_star() {
    expect(typeSystem.isNullable(starType), false);
  }

  test_isNullable_Never() {
    expect(typeSystem.isNullable(neverNone), false);
  }

  test_isNullable_never() {
    expect(typeSystem.isNullable(neverNone), false);
  }

  test_isNullable_null() {
    expect(typeSystem.isNullable(nullType), true);
  }

  test_isNullable_typeParameter_noneBound_none() {
    expect(
      typeSystem.isNullable(
        _typeParameterTypeNone(bound: noneType),
      ),
      false,
    );
  }

  test_isNullable_typeParameter_noneBound_question() {
    expect(
      typeSystem.isNullable(
        _typeParameterTypeQuestion(bound: noneType),
      ),
      true,
    );
  }

  test_isNullable_typeParameter_questionBound_none() {
    expect(
      typeSystem.isNullable(
        _typeParameterTypeNone(bound: questionType),
      ),
      false,
    );
  }

  test_isNullable_typeParameter_questionBound_question() {
    expect(
      typeSystem.isNullable(
        _typeParameterTypeQuestion(bound: questionType),
      ),
      true,
    );
  }

  test_isNullable_typeParameter_starBound_star() {
    expect(
      typeSystem.isNullable(
        _typeParameterTypeStar(bound: starType),
      ),
      false,
    );
  }

  test_isNullable_void() {
    expect(typeSystem.isNullable(voidType), true);
  }

  test_isPotentiallyNonNullable_dynamic() {
    expect(typeSystem.isPotentiallyNonNullable(dynamicType), false);
  }

  test_isPotentiallyNonNullable_futureOr_noneArgument_none() {
    expect(
      typeSystem.isPotentiallyNonNullable(
        futureOrTypeNone(argument: noneType),
      ),
      true,
    );
  }

  test_isPotentiallyNonNullable_futureOr_questionArgument_none() {
    expect(
      typeSystem.isPotentiallyNonNullable(
        futureOrTypeNone(argument: questionType),
      ),
      false,
    );
  }

  test_isPotentiallyNonNullable_futureOr_starArgument_none() {
    expect(
      typeSystem.isPotentiallyNonNullable(
        futureOrTypeNone(argument: starType),
      ),
      true,
    );
  }

  test_isPotentiallyNonNullable_never() {
    expect(typeSystem.isPotentiallyNonNullable(neverNone), true);
  }

  test_isPotentiallyNonNullable_none() {
    expect(typeSystem.isPotentiallyNonNullable(noneType), true);
  }

  test_isPotentiallyNonNullable_null() {
    expect(typeSystem.isPotentiallyNonNullable(nullType), false);
  }

  test_isPotentiallyNonNullable_question() {
    expect(typeSystem.isPotentiallyNonNullable(questionType), false);
  }

  test_isPotentiallyNonNullable_star() {
    expect(typeSystem.isPotentiallyNonNullable(starType), true);
  }

  test_isPotentiallyNonNullable_void() {
    expect(typeSystem.isPotentiallyNonNullable(voidType), false);
  }

  test_isPotentiallyNullable_dynamic() {
    expect(typeSystem.isPotentiallyNullable(dynamicType), true);
  }

  test_isPotentiallyNullable_futureOr_noneArgument_none() {
    expect(
      typeSystem.isPotentiallyNullable(
        futureOrTypeNone(argument: noneType),
      ),
      false,
    );
  }

  test_isPotentiallyNullable_futureOr_questionArgument_none() {
    expect(
      typeSystem.isPotentiallyNullable(
        futureOrTypeNone(argument: questionType),
      ),
      true,
    );
  }

  test_isPotentiallyNullable_futureOr_starArgument_none() {
    expect(
      typeSystem.isPotentiallyNullable(
        futureOrTypeNone(argument: starType),
      ),
      false,
    );
  }

  test_isPotentiallyNullable_never() {
    expect(typeSystem.isPotentiallyNullable(neverNone), false);
  }

  test_isPotentiallyNullable_none() {
    expect(typeSystem.isPotentiallyNullable(noneType), false);
  }

  test_isPotentiallyNullable_null() {
    expect(typeSystem.isPotentiallyNullable(nullType), true);
  }

  test_isPotentiallyNullable_question() {
    expect(typeSystem.isPotentiallyNullable(questionType), true);
  }

  test_isPotentiallyNullable_star() {
    expect(typeSystem.isPotentiallyNullable(starType), false);
  }

  test_isPotentiallyNullable_void() {
    expect(typeSystem.isPotentiallyNullable(voidType), true);
  }

  test_promoteToNonNull_dynamic() {
    expect(
      typeSystem.promoteToNonNull(dynamicType),
      dynamicType,
    );
  }

  test_promoteToNonNull_functionType() {
    // NonNull(T0 Function(...)) = T0 Function(...)
    expect(
      typeSystem.promoteToNonNull(nothingToVoidFunctionTypeQuestion),
      nothingToVoidFunctionTypeNone,
    );
  }

  test_promoteToNonNull_futureOr_question() {
    // NonNull(FutureOr<T>) = FutureOr<T>
    expect(
      typeSystem.promoteToNonNull(
        futureOrTypeQuestion(argument: stringClassTypeQuestion),
      ),
      futureOrTypeNone(argument: stringClassTypeQuestion),
    );
  }

  test_promoteToNonNull_interfaceType_function_none() {
    expect(
      typeSystem.promoteToNonNull(functionClassTypeQuestion),
      functionClassTypeNone,
    );
  }

  test_promoteToNonNull_interfaceType_none() {
    expect(
      typeSystem.promoteToNonNull(stringClassTypeNone),
      stringClassTypeNone,
    );
  }

  test_promoteToNonNull_interfaceType_question() {
    expect(
      typeSystem.promoteToNonNull(stringClassTypeQuestion),
      stringClassTypeNone,
    );
  }

  test_promoteToNonNull_interfaceType_question_withTypeArguments() {
    // NonNull(C<T1, ... , Tn>) = C<T1, ... , Tn>
    // NonNull(List<String?>?) = List<String?>
    expect(
      typeSystem.promoteToNonNull(
        listClassTypeQuestion(stringClassTypeQuestion),
      ),
      listClassTypeNone(stringClassTypeQuestion),
    );
  }

  test_promoteToNonNull_interfaceType_star() {
    expect(
      typeSystem.promoteToNonNull(stringClassTypeStar),
      stringClassTypeNone,
    );
  }

  test_promoteToNonNull_never() {
    expect(typeSystem.promoteToNonNull(neverNone), neverNone);
  }

  test_promoteToNonNull_null() {
    expect(typeSystem.promoteToNonNull(nullType), neverNone);
  }

  test_promoteToNonNull_typeParameter_noneBound_none() {
    var element = typeParameter('T', bound: noneType);
    var type = typeParameterTypeNone(element);
    expect(typeSystem.promoteToNonNull(type), same(type));
  }

  test_promoteToNonNull_typeParameter_noneBound_question() {
    var element = typeParameter('T', bound: stringClassTypeNone);
    var type = typeParameterTypeQuestion(element);
    _assertPromotedTypeParameterType(
      typeSystem.promoteToNonNull(type),
      baseElement: element,
      expectedNullabilitySuffix: NullabilitySuffix.none,
    );
  }

  test_promoteToNonNull_typeParameter_nullBound_none() {
    var element = typeParameter('T', bound: null);
    var type = typeParameterTypeNone(element);
    _assertPromotedTypeParameterType(
      typeSystem.promoteToNonNull(type),
      baseElement: element,
      expectedBound: objectClassTypeNone,
      expectedNullabilitySuffix: NullabilitySuffix.none,
    );
  }

  test_promoteToNonNull_typeParameter_questionBound_none() {
    var element = typeParameter('T', bound: stringClassTypeQuestion);
    var type = typeParameterTypeNone(element);
    _assertPromotedTypeParameterType(
      typeSystem.promoteToNonNull(type),
      baseElement: element,
      expectedBound: stringClassTypeNone,
      expectedNullabilitySuffix: NullabilitySuffix.none,
    );
  }

  test_promoteToNonNull_typeParameter_questionBound_question() {
    var element = typeParameter('T', bound: stringClassTypeQuestion);
    var type = typeParameterTypeQuestion(element);
    _assertPromotedTypeParameterType(
      typeSystem.promoteToNonNull(type),
      baseElement: element,
      expectedBound: stringClassTypeNone,
      expectedNullabilitySuffix: NullabilitySuffix.none,
    );
  }

  test_promoteToNonNull_typeParameter_questionBound_star() {
    var element = typeParameter('T', bound: stringClassTypeQuestion);
    var type = typeParameterTypeStar(element);
    _assertPromotedTypeParameterType(
      typeSystem.promoteToNonNull(type),
      baseElement: element,
      expectedBound: stringClassTypeNone,
      expectedNullabilitySuffix: NullabilitySuffix.none,
    );
  }

  test_promoteToNonNull_typeParameter_starBound_none() {
    var element = typeParameter('T', bound: stringClassTypeStar);
    var type = typeParameterTypeNone(element);
    _assertPromotedTypeParameterType(
      typeSystem.promoteToNonNull(type),
      baseElement: element,
      expectedBound: stringClassTypeNone,
      expectedNullabilitySuffix: NullabilitySuffix.none,
    );
  }

  test_promoteToNonNull_void() {
    expect(
      typeSystem.promoteToNonNull(voidType),
      voidType,
    );
  }

  /// If [expectedBound] is `null`, the element of [actual] must be the same
  /// as the [baseElement].  Otherwise the element of [actual] must be a
  /// [TypeParameterMember] with the [baseElement] and the [expectedBound].
  void _assertPromotedTypeParameterType(
    TypeParameterTypeImpl actual, {
    @required TypeParameterElement baseElement,
    TypeImpl expectedBound,
    @required NullabilitySuffix expectedNullabilitySuffix,
  }) {
    if (expectedBound != null) {
      var actualMember = actual.element as TypeParameterMember;
      expect(actualMember.baseElement, same(baseElement));
      expect(actualMember.bound, expectedBound);
    } else {
      expect(actual.element, same(baseElement));
    }
    expect(actual.nullabilitySuffix, expectedNullabilitySuffix);
  }

  DartType _typeParameterTypeNone({@required DartType bound}) {
    var element = typeParameter('T', bound: bound);
    return typeParameterTypeNone(element);
  }

  DartType _typeParameterTypeQuestion({@required DartType bound}) {
    var element = typeParameter('T', bound: bound);
    return typeParameterTypeQuestion(element);
  }

  DartType _typeParameterTypeStar({@required DartType bound}) {
    var element = typeParameter('T', bound: bound);
    return typeParameterTypeStar(element);
  }
}
