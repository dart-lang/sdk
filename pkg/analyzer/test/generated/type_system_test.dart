// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart' show astFactory;
import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/token.dart' show KeywordToken;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/least_upper_bound.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart'
    show NonExistingSource, Source, UriKind;
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
    defineReflectiveTests(TryPromoteToTest);
  });
}

abstract class AbstractTypeSystemTest with ElementsTypesMixin {
  TestAnalysisContext analysisContext;

  @override
  TypeProvider typeProvider;

  TypeSystemImpl typeSystem;

  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting();
  }

  void setUp() {
    analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProviderLegacy;
    typeSystem = analysisContext.typeSystemLegacy;
  }

  String _typeString(TypeImpl type) {
    return type.getDisplayString(withNullability: true);
  }
}

@reflectiveTest
class AssignabilityTest extends AbstractTypeSystemTest {
  void test_isAssignableTo_bottom_isBottom() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectStar,
      intStar,
      doubleStar,
      numStar,
      stringStar,
      interfaceTypeStar(A),
      neverStar,
    ];

    _checkGroups(neverStar, interassignable: interassignable);
  }

  void test_isAssignableTo_call_method() {
    var B = class_(
      name: 'B',
      methods: [
        method('call', objectStar, parameters: [
          requiredParameter(name: '_', type: intStar),
        ]),
      ],
    );

    var testLibrary = _testLibrary();
    B.enclosingElement = testLibrary.definingCompilationUnit;

    _checkIsStrictAssignableTo(
      interfaceTypeStar(B),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: objectStar,
      ),
    );
  }

  void test_isAssignableTo_classes() {
    var classTop = class_(name: 'A');
    var classLeft = class_(name: 'B', superType: interfaceTypeStar(classTop));
    var classRight = class_(name: 'C', superType: interfaceTypeStar(classTop));
    var classBottom = class_(
      name: 'D',
      superType: interfaceTypeStar(classLeft),
      interfaces: [interfaceTypeStar(classRight)],
    );
    var top = interfaceTypeStar(classTop);
    var left = interfaceTypeStar(classLeft);
    var right = interfaceTypeStar(classRight);
    var bottom = interfaceTypeStar(classBottom);

    _checkLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_double() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectStar,
      doubleStar,
      numStar,
      neverStar,
    ];
    List<DartType> unrelated = <DartType>[
      intStar,
      stringStar,
      interfaceTypeStar(A),
    ];

    _checkGroups(doubleStar,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_dynamic_isTop() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectStar,
      intStar,
      doubleStar,
      numStar,
      stringStar,
      interfaceTypeStar(A),
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
        interfaceTypeStar(
          L,
          typeArguments: [
            typeParameterTypeStar(MT),
          ],
        ),
      ],
    );

    var top = interfaceTypeStar(L, typeArguments: [dynamicType]);
    var left = interfaceTypeStar(M, typeArguments: [dynamicType]);
    var right = interfaceTypeStar(L, typeArguments: [intStar]);
    var bottom = interfaceTypeStar(M, typeArguments: [intStar]);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_int() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectStar,
      intStar,
      numStar,
      neverStar,
    ];
    List<DartType> unrelated = <DartType>[
      doubleStar,
      stringStar,
      interfaceTypeStar(A),
    ];

    _checkGroups(intStar,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_named_optional() {
    var r = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var o = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var n = functionTypeStar(
      parameters: [
        namedParameter(name: 'x', type: intStar),
      ],
      returnType: intStar,
    );

    var rr = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var ro = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        positionalParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var rn = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        namedParameter(name: 'x', type: intStar),
      ],
      returnType: intStar,
    );
    var oo = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var nn = functionTypeStar(
      parameters: [
        namedParameter(name: 'x', type: intStar),
        namedParameter(name: 'y', type: intStar),
      ],
      returnType: intStar,
    );
    var nnn = functionTypeStar(
      parameters: [
        namedParameter(name: 'x', type: intStar),
        namedParameter(name: 'y', type: intStar),
        namedParameter(name: 'z', type: intStar),
      ],
      returnType: intStar,
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
      objectStar,
      numStar,
      intStar,
      doubleStar,
      neverStar,
    ];
    List<DartType> unrelated = <DartType>[
      stringStar,
      interfaceTypeStar(A),
    ];

    _checkGroups(numStar,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_simple_function() {
    var top = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: objectStar,
    );

    var left = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: intStar,
    );

    var right = functionTypeStar(
      parameters: [
        requiredParameter(type: objectStar),
      ],
      returnType: objectStar,
    );

    var bottom = functionTypeStar(
      parameters: [
        requiredParameter(type: objectStar),
      ],
      returnType: intStar,
    );

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_void_functions() {
    var top = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );

    var bottom = functionTypeStar(
      parameters: [
        requiredParameter(type: objectStar),
      ],
      returnType: intStar,
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
    expect(typeSystem.isAssignableTo2(type1, type2), true);
  }

  void _checkIsNotAssignableTo(DartType type1, DartType type2) {
    expect(typeSystem.isAssignableTo2(type1, type2), false);
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

  /// Return a test library, in `/test.dart` file.
  LibraryElementImpl _testLibrary() {
    var source = _MockSource(toUri('/test.dart'));

    var definingUnit = CompilationUnitElementImpl();
    definingUnit.source = definingUnit.librarySource = source;

    var testLibrary = LibraryElementImpl(
        analysisContext, AnalysisSessionImpl(null), '', -1, 0, false);
    testLibrary.definingCompilationUnit = definingUnit;
    return testLibrary;
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

  void _checkLeastUpperBound(DartType T1, DartType T2, DartType expected) {
    var expectedStr = _typeString(expected);

    var result = typeSystem.getLeastUpperBound(T1, T2);
    var resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');

    // Check that the result is an upper bound.
    expect(typeSystem.isSubtypeOf(T1, result), true);
    expect(typeSystem.isSubtypeOf(T2, result), true);

    // Check for symmetry.
    result = typeSystem.getLeastUpperBound(T2, T1);
    resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');
  }
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

@reflectiveTest
class GreatestLowerBoundTest extends BoundTestBase {
  void test_bottom_function() {
    _checkGreatestLowerBound(
        neverStar, functionTypeStar(returnType: voidNone), neverStar);
  }

  void test_bottom_interface() {
    var A = class_(name: 'A');
    _checkGreatestLowerBound(neverStar, interfaceTypeStar(A), neverStar);
  }

  void test_bottom_typeParam() {
    var T = typeParameter('T');
    _checkGreatestLowerBound(neverStar, typeParameterTypeStar(T), neverStar);
  }

  void test_bounds_of_top_types_complete() {
    // Test every combination of a subset of Tops programatically.
    var futureOrDynamicType = futureOrStar(dynamicType);
    var futureOrObjectType = futureOrStar(objectStar);
    var futureOrVoidType = futureOrStar(voidNone);
    final futureOrFutureOrDynamicType = futureOrStar(futureOrDynamicType);
    final futureOrFutureOrObjectType = futureOrStar(futureOrObjectType);
    final futureOrFutureOrVoidType = futureOrStar(futureOrVoidType);

    var orderedTops = [
      // Lower index, so lower Top
      voidNone,
      dynamicType,
      objectStar,
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
    var futureOrDynamicType = futureOrStar(dynamicType);
    final futureOrFutureOrDynamicType = futureOrStar(futureOrDynamicType);

    // Sanity check specific cases of top for GLB/LUB.
    _checkLeastUpperBound(objectStar, dynamicType, dynamicType);
    _checkGreatestLowerBound(objectStar, dynamicType, objectStar);
    _checkLeastUpperBound(objectStar, voidNone, voidNone);
    _checkLeastUpperBound(futureOrDynamicType, dynamicType, dynamicType);
    _checkGreatestLowerBound(
        futureOrDynamicType, objectStar, futureOrDynamicType);
    _checkGreatestLowerBound(futureOrDynamicType, futureOrFutureOrDynamicType,
        futureOrFutureOrDynamicType);
  }

  void test_classAndSuperclass() {
    // class A
    // class B extends A
    // class C extends B
    var A = class_(name: 'A');
    var B = class_(name: 'B', superType: interfaceTypeStar(A));
    var C = class_(name: 'C', superType: interfaceTypeStar(B));
    _checkGreatestLowerBound(
      interfaceTypeStar(A),
      interfaceTypeStar(C),
      interfaceTypeStar(C),
    );
  }

  void test_classAndSuperinterface() {
    // class A
    // class B implements A
    // class C implements B
    var A = class_(name: 'A');
    var B = class_(name: 'B', interfaces: [interfaceTypeStar(A)]);
    var C = class_(name: 'C', interfaces: [interfaceTypeStar(B)]);
    _checkGreatestLowerBound(
      interfaceTypeStar(A),
      interfaceTypeStar(C),
      interfaceTypeStar(C),
    );
  }

  void test_dynamic_bottom() {
    _checkGreatestLowerBound(dynamicType, neverStar, neverStar);
  }

  void test_dynamic_function() {
    _checkGreatestLowerBound(
        dynamicType,
        functionTypeStar(returnType: voidNone),
        functionTypeStar(returnType: voidNone));
  }

  void test_dynamic_interface() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);
    _checkGreatestLowerBound(dynamicType, typeA, typeA);
  }

  void test_dynamic_typeParam() {
    var T = typeParameter('T');
    var typeT = typeParameterTypeStar(T);
    _checkGreatestLowerBound(dynamicType, typeT, typeT);
  }

  void test_dynamic_void() {
    // Note: _checkGreatestLowerBound tests `GLB(x, y)` as well as `GLB(y, x)`
    _checkGreatestLowerBound(dynamicType, voidNone, dynamicType);
  }

  void test_functionsDifferentNamedTakeUnion() {
    var type1 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intStar),
        namedParameter(name: 'b', type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'b', type: doubleStar),
        namedParameter(name: 'c', type: stringStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intStar),
        namedParameter(name: 'b', type: numStar),
        namedParameter(name: 'c', type: stringStar),
      ],
      returnType: voidNone,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsDifferentOptionalArityTakeMax() {
    var type1 = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        positionalParameter(type: doubleStar),
        positionalParameter(type: stringStar),
        positionalParameter(type: objectStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        positionalParameter(type: numStar),
        positionalParameter(type: stringStar),
        positionalParameter(type: objectStar),
      ],
      returnType: voidNone,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsDifferentRequiredArityBecomeOptional() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsFromDynamic() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: dynamicType),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: dynamicType),
      ],
      returnType: voidNone,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsGlbReturnType() {
    var type1 = functionTypeStar(
      returnType: intStar,
    );
    var type2 = functionTypeStar(
      returnType: numStar,
    );
    var expected = functionTypeStar(
      returnType: intStar,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubNamedParams() {
    var type1 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: stringStar),
        namedParameter(name: 'b', type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intStar),
        namedParameter(name: 'b', type: numStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: objectStar),
        namedParameter(name: 'b', type: numStar),
      ],
      returnType: voidNone,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubPositionalParams() {
    var type1 = functionTypeStar(
      parameters: [
        positionalParameter(type: stringStar),
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
        positionalParameter(type: numStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        positionalParameter(type: objectStar),
        positionalParameter(type: numStar),
      ],
      returnType: voidNone,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubRequiredParams() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        requiredParameter(type: doubleStar),
        requiredParameter(type: numStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: objectStar),
        requiredParameter(type: numStar),
        requiredParameter(type: numStar),
      ],
      returnType: voidNone,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsMixedOptionalAndRequiredBecomeOptional() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsReturnBottomIfMixOptionalAndNamed() {
    // Dart doesn't allow a function to have both optional and named parameters,
    // so if we would have synthethized that, pick bottom instead.
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        namedParameter(name: 'a', type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intStar),
      ],
      returnType: voidNone,
    );
    _checkGreatestLowerBound(type1, type2, neverStar);
  }

  void test_functionsSameType_withNamed() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        namedParameter(name: 'n', type: numStar),
      ],
      returnType: intStar,
    );

    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        namedParameter(name: 'n', type: numStar),
      ],
      returnType: intStar,
    );

    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        namedParameter(name: 'n', type: numStar),
      ],
      returnType: intStar,
    );

    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsSameType_withOptional() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        positionalParameter(type: doubleStar),
      ],
      returnType: intStar,
    );

    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        positionalParameter(type: doubleStar),
      ],
      returnType: intStar,
    );

    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        positionalParameter(type: doubleStar),
      ],
      returnType: intStar,
    );

    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_interface_function() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);
    _checkGreatestLowerBound(
      typeA,
      functionTypeStar(returnType: voidNone),
      neverStar,
    );
  }

  void test_mixin() {
    // class A
    // class B
    // class C
    // class D extends A with B, C
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B');
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C');
    var typeC = interfaceTypeStar(C);

    var D = class_(
      name: 'D',
      superType: interfaceTypeStar(A),
      mixins: [typeB, typeC],
    );
    var typeD = interfaceTypeStar(D);

    _checkGreatestLowerBound(typeA, typeD, typeD);
    _checkGreatestLowerBound(typeB, typeD, typeD);
    _checkGreatestLowerBound(typeC, typeD, typeD);
  }

  void test_self() {
    var T = typeParameter('T');
    var A = class_(name: 'A');

    List<DartType> types = [
      dynamicType,
      voidNone,
      neverStar,
      typeParameterTypeStar(T),
      interfaceTypeStar(A),
      functionTypeStar(returnType: voidNone),
    ];

    for (DartType type in types) {
      _checkGreatestLowerBound(type, type, type);
    }
  }

  void test_typeParam_function_noBound() {
    var T = typeParameter('T');
    _checkGreatestLowerBound(
      typeParameterTypeStar(T),
      functionTypeStar(returnType: voidNone),
      neverStar,
    );
  }

  void test_typeParam_interface_bounded() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', superType: typeB);
    var typeC = interfaceTypeStar(C);

    var T = typeParameter('T', bound: typeB);
    _checkGreatestLowerBound(typeParameterTypeStar(T), typeC, neverStar);
  }

  void test_typeParam_interface_noBound() {
    // GLB(T, A) = ⊥
    var T = typeParameter('T');
    var A = class_(name: 'A');
    _checkGreatestLowerBound(
      typeParameterTypeStar(T),
      interfaceTypeStar(A),
      neverStar,
    );
  }

  void test_typeParameters_different() {
    // GLB(List<int>, List<double>) = ⊥
    var listOfIntType = listStar(intStar);
    var listOfDoubleType = listStar(doubleStar);
    // TODO(rnystrom): Can we do something better here?
    _checkGreatestLowerBound(listOfIntType, listOfDoubleType, neverStar);
  }

  void test_typeParameters_same() {
    // GLB(List<int>, List<int>) = List<int>
    var listOfIntType = listStar(intStar);
    _checkGreatestLowerBound(listOfIntType, listOfIntType, listOfIntType);
  }

  void test_unrelatedClasses() {
    // class A
    // class B
    // class C
    var A = class_(name: 'A');
    var B = class_(name: 'B');
    _checkGreatestLowerBound(
        interfaceTypeStar(A), interfaceTypeStar(B), neverStar);
  }

  void test_void() {
    var A = class_(name: 'A');
    var T = typeParameter('T');
    List<DartType> types = [
      neverStar,
      functionTypeStar(returnType: voidNone),
      interfaceTypeStar(A),
      typeParameterTypeStar(T),
    ];
    for (DartType type in types) {
      _checkGreatestLowerBound(
        functionTypeStar(returnType: voidNone),
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
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    _checkLeastUpperBound(type1, type2, typeProvider.functionType);
  }

  void test_fuzzyArrows() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: dynamicType),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_glbNamedParams() {
    var type1 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: stringStar),
        namedParameter(name: 'b', type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intStar),
        namedParameter(name: 'b', type: numStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: neverStar),
        namedParameter(name: 'b', type: intStar),
      ],
      returnType: voidNone,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_glbPositionalParams() {
    var type1 = functionTypeStar(
      parameters: [
        positionalParameter(type: stringStar),
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
        positionalParameter(type: numStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        positionalParameter(type: neverStar),
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_glbRequiredParams() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        requiredParameter(type: doubleStar),
        requiredParameter(type: numStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: neverStar),
        requiredParameter(type: neverStar),
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_ignoreExtraNamedParams() {
    var type1 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intStar),
        namedParameter(name: 'b', type: intStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intStar),
        namedParameter(name: 'c', type: intStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        namedParameter(name: 'a', type: intStar),
      ],
      returnType: voidNone,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_ignoreExtraPositionalParams() {
    var type1 = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
        positionalParameter(type: stringStar),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
      ],
      returnType: voidNone,
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_lubReturnType() {
    var type1 = functionTypeStar(returnType: intStar);
    var type2 = functionTypeStar(returnType: doubleStar);
    var expected = functionTypeStar(returnType: numStar);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_sameType_withNamed() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        namedParameter(name: 'n', type: numStar),
      ],
      returnType: intStar,
    );

    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        namedParameter(name: 'n', type: numStar),
      ],
      returnType: intStar,
    );

    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        namedParameter(name: 'n', type: numStar),
      ],
      returnType: intStar,
    );

    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_sameType_withOptional() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        positionalParameter(type: doubleStar),
      ],
      returnType: intStar,
    );

    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        positionalParameter(type: doubleStar),
      ],
      returnType: intStar,
    );

    var expected = functionTypeStar(
      parameters: [
        requiredParameter(type: stringStar),
        requiredParameter(type: intStar),
        requiredParameter(type: numStar),
        positionalParameter(type: doubleStar),
      ],
      returnType: intStar,
    );

    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_typeFormals_differentBounds() {
    var T1 = typeParameter('T1', bound: intStar);
    var type1 = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    var T2 = typeParameter('T2', bound: doubleStar);
    var type2 = functionTypeStar(
      typeFormals: [T2],
      returnType: typeParameterTypeStar(T2),
    );

    _checkLeastUpperBound(type1, type2, typeProvider.functionType);
  }

  void test_typeFormals_differentNumber() {
    var T1 = typeParameter('T1', bound: numStar);
    var type1 = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    var type2 = functionTypeStar(returnType: intStar);

    _checkLeastUpperBound(type1, type2, typeProvider.functionType);
  }

  void test_typeFormals_sameBounds() {
    var T1 = typeParameter('T1', bound: numStar);
    var type1 = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    var T2 = typeParameter('T2', bound: numStar);
    var type2 = functionTypeStar(
      typeFormals: [T2],
      returnType: typeParameterTypeStar(T2),
    );

    var TE = typeParameter('T', bound: numStar);
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
    _checkLeastUpperBound(neverStar, functionTypeStar(returnType: voidNone),
        functionTypeStar(returnType: voidNone));
  }

  void test_bottom_interface() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);
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
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', interfaces: [typeA]);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', interfaces: [typeB]);
    var typeC = interfaceTypeStar(C);

    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_directSubclassCase() {
    // class A
    // class B extends A
    // class C extends B

    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', superType: typeB);
    var typeC = interfaceTypeStar(C);

    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_directSuperclass_nullability() {
    var aElement = class_(name: 'A');
    var aQuestion = interfaceTypeQuestion(aElement);
    var aStar = interfaceTypeStar(aElement);
    var aNone = interfaceTypeNone(aElement);

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
        dynamicType, functionTypeStar(returnType: voidNone), dynamicType);
  }

  void test_dynamic_interface() {
    var A = class_(name: 'A');
    _checkLeastUpperBound(dynamicType, interfaceTypeStar(A), dynamicType);
  }

  void test_dynamic_typeParam() {
    var T = typeParameter('T');
    _checkLeastUpperBound(dynamicType, typeParameterTypeStar(T), dynamicType);
  }

  void test_dynamic_void() {
    // Note: _checkLeastUpperBound tests `LUB(x, y)` as well as `LUB(y, x)`
    _checkLeastUpperBound(dynamicType, voidNone, voidNone);
  }

  void test_interface_function() {
    var A = class_(name: 'A');
    _checkLeastUpperBound(interfaceTypeStar(A),
        functionTypeStar(returnType: voidNone), objectStar);
  }

  void test_interface_sameElement_nullability() {
    var aElement = class_(name: 'A');

    var aQuestion = interfaceTypeQuestion(aElement);
    var aStar = interfaceTypeStar(aElement);
    var aNone = interfaceTypeNone(aElement);

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

    var mixinM = mixin_(
      name: 'M',
      constraints: [instA.withNullabilitySuffixNone],
    );

    _checkLeastUpperBound(
      interfaceTypeStar(classB),
      interfaceTypeStar(mixinM),
      instA.withNullability(NullabilitySuffix.star),
    );
  }

  void test_mixinAndClass_object() {
    var classA = class_(name: 'A');
    var mixinM = mixin_(name: 'M');

    _checkLeastUpperBound(
      interfaceTypeStar(classA),
      interfaceTypeStar(mixinM),
      objectStar,
    );
  }

  void test_mixinAndClass_sharedInterface() {
    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, []);

    var classB = class_(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );

    var mixinM = mixin_(
      name: 'M',
      interfaces: [instA.withNullabilitySuffixNone],
    );

    _checkLeastUpperBound(
      interfaceTypeStar(classB),
      interfaceTypeStar(mixinM),
      instA.withNullability(NullabilitySuffix.star),
    );
  }

  void test_mixinCase() {
    // class A
    // class B extends A
    // class C extends A
    // class D extends B with M, N, O, P

    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', superType: typeA);
    var typeC = interfaceTypeStar(C);

    var D = class_(
      name: 'D',
      superType: typeB,
      mixins: [
        interfaceTypeStar(class_(name: 'M')),
        interfaceTypeStar(class_(name: 'N')),
        interfaceTypeStar(class_(name: 'O')),
        interfaceTypeStar(class_(name: 'P')),
      ],
    );
    var typeD = interfaceTypeStar(D);

    _checkLeastUpperBound(typeD, typeC, typeA);
  }

  void test_nestedFunctionsLubInnerParamTypes() {
    var type1 = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: stringStar),
              requiredParameter(type: intStar),
              requiredParameter(type: intStar),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    var type2 = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: intStar),
              requiredParameter(type: doubleStar),
              requiredParameter(type: numStar),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    var expected = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: objectStar),
              requiredParameter(type: numStar),
              requiredParameter(type: numStar),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
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
                    requiredParameter(type: stringStar),
                    requiredParameter(type: intStar),
                    requiredParameter(type: intStar)
                  ],
                  returnType: voidNone,
                ),
              ),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    expect(
      _typeString(type1),
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
                    requiredParameter(type: intStar),
                    requiredParameter(type: doubleStar),
                    requiredParameter(type: numStar)
                  ],
                  returnType: voidNone,
                ),
              ),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    expect(
      _typeString(type2),
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
                    requiredParameter(type: intStar)
                  ],
                  returnType: voidNone,
                ),
              ),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    expect(
      _typeString(expected),
      'void Function(void Function(void Function(Never*, Never*, int*)*)*)*',
    );

    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_object() {
    var A = class_(name: 'A');
    var B = class_(name: 'B');
    var typeA = interfaceTypeStar(A);
    var typeB = interfaceTypeStar(B);
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
      voidNone,
      neverStar,
      typeParameterTypeStar(T),
      interfaceTypeStar(A),
      functionTypeStar(returnType: voidNone)
    ];

    for (DartType type in types) {
      _checkLeastUpperBound(type, type, type);
    }
  }

  void test_sharedSuperclass1() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', superType: typeA);
    var typeC = interfaceTypeStar(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperclass1_nullability() {
    var aElement = class_(name: 'A');
    var aQuestion = interfaceTypeQuestion(aElement);
    var aStar = interfaceTypeStar(aElement);
    var aNone = interfaceTypeNone(aElement);

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
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', superType: typeA);
    var typeC = interfaceTypeStar(C);

    var D = class_(name: 'D', superType: typeC);
    var typeD = interfaceTypeStar(D);

    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperclass3() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', superType: typeB);
    var typeC = interfaceTypeStar(C);

    var D = class_(name: 'D', superType: typeB);
    var typeD = interfaceTypeStar(D);

    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperclass4() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var A2 = class_(name: 'A2');
    var typeA2 = interfaceTypeStar(A2);

    var A3 = class_(name: 'A3');
    var typeA3 = interfaceTypeStar(A3);

    var B = class_(name: 'B', superType: typeA, interfaces: [typeA2]);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', superType: typeA, interfaces: [typeA3]);
    var typeC = interfaceTypeStar(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface1() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', interfaces: [typeA]);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', interfaces: [typeA]);
    var typeC = interfaceTypeStar(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface2() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', interfaces: [typeA]);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', interfaces: [typeA]);
    var typeC = interfaceTypeStar(C);

    var D = class_(name: 'D', interfaces: [typeC]);
    var typeD = interfaceTypeStar(D);

    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperinterface3() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', interfaces: [typeA]);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', interfaces: [typeB]);
    var typeC = interfaceTypeStar(C);

    var D = class_(name: 'D', interfaces: [typeB]);
    var typeD = interfaceTypeStar(D);

    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperinterface4() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var A2 = class_(name: 'A2');
    var typeA2 = interfaceTypeStar(A2);

    var A3 = class_(name: 'A3');
    var typeA3 = interfaceTypeStar(A3);

    var B = class_(name: 'B', interfaces: [typeA, typeA2]);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', interfaces: [typeA, typeA3]);
    var typeC = interfaceTypeStar(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_twoComparables() {
    _checkLeastUpperBound(stringStar, numStar, objectStar);
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
    var T = typeParameter('T', bound: interfaceTypeStar(A));
    _checkLeastUpperBound(typeParameterTypeStar(T),
        functionTypeStar(returnType: voidNone), objectStar);
  }

  void test_typeParam_fBounded() {
    var T = typeParameter('Q');
    var A = class_(name: 'A', typeParameters: [T]);

    var S = typeParameter('S');
    var typeS = typeParameterTypeStar(S);
    S.bound = interfaceTypeStar(A, typeArguments: [typeS]);

    var U = typeParameter('U');
    var typeU = typeParameterTypeStar(U);
    U.bound = interfaceTypeStar(A, typeArguments: [typeU]);

    _checkLeastUpperBound(
      typeS,
      typeParameterTypeStar(U),
      interfaceTypeStar(A, typeArguments: [objectStar]),
    );
  }

  void test_typeParam_function_bounded() {
    var T = typeParameter('T', bound: typeProvider.functionType);
    _checkLeastUpperBound(
      typeParameterTypeStar(T),
      functionTypeStar(returnType: voidNone),
      typeProvider.functionType,
    );
  }

  void test_typeParam_function_noBound() {
    var T = typeParameter('T');
    _checkLeastUpperBound(
      typeParameterTypeStar(T),
      functionTypeStar(returnType: voidNone),
      objectStar,
    );
  }

  void test_typeParam_interface_bounded() {
    var A = class_(name: 'A');
    var typeA = interfaceTypeStar(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeStar(B);

    var C = class_(name: 'C', superType: typeA);
    var typeC = interfaceTypeStar(C);

    var T = typeParameter('T', bound: typeB);
    var typeT = typeParameterTypeStar(T);

    _checkLeastUpperBound(typeT, typeC, typeA);
  }

  void test_typeParam_interface_noBound() {
    var T = typeParameter('T');
    var A = class_(name: 'A');
    _checkLeastUpperBound(
      typeParameterTypeStar(T),
      interfaceTypeStar(A),
      objectStar,
    );
  }

  void test_typeParameters_contravariant_different() {
    // class A<in T>
    var T = typeParameter('T', variance: Variance.contravariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    // A<int>
    var aNum = interfaceTypeStar(A, typeArguments: [numStar]);
    var aInt = interfaceTypeStar(A, typeArguments: [intStar]);

    _checkLeastUpperBound(aInt, aNum, aInt);
  }

  void test_typeParameters_contravariant_same() {
    // class A<in T>
    var T = typeParameter('T', variance: Variance.contravariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    var aNum = interfaceTypeStar(A, typeArguments: [numStar]);

    _checkLeastUpperBound(aNum, aNum, aNum);
  }

  void test_typeParameters_covariant_different() {
    // class A<out T>
    var T = typeParameter('T', variance: Variance.covariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    // A<int>
    var aNum = interfaceTypeStar(A, typeArguments: [numStar]);
    var aInt = interfaceTypeStar(A, typeArguments: [intStar]);

    _checkLeastUpperBound(aInt, aNum, aNum);
  }

  void test_typeParameters_covariant_same() {
    // class A<out T>
    var T = typeParameter('T', variance: Variance.covariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    var aNum = interfaceTypeStar(A, typeArguments: [numStar]);

    _checkLeastUpperBound(aNum, aNum, aNum);
  }

  /// Check least upper bound of the same class with different type parameters.
  void test_typeParameters_different() {
    // class List<int>
    // class List<double>
    var listOfIntType = listStar(intStar);
    var listOfDoubleType = listStar(doubleStar);
    var listOfNum = listStar(numStar);
    _checkLeastUpperBound(listOfIntType, listOfDoubleType, listOfNum);
  }

  void test_typeParameters_invariant_object() {
    // class A<inout T>
    var T = typeParameter('T', variance: Variance.invariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    // A<int>
    var aNum = interfaceTypeStar(A, typeArguments: [numStar]);
    var aInt = interfaceTypeStar(A, typeArguments: [intStar]);

    _checkLeastUpperBound(aNum, aInt, objectStar);
  }

  void test_typeParameters_invariant_same() {
    // class A<inout T>
    var T = typeParameter('T', variance: Variance.invariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    var aNum = interfaceTypeStar(A, typeArguments: [numStar]);

    _checkLeastUpperBound(aNum, aNum, aNum);
  }

  void test_typeParameters_multi_basic() {
    // class Multi<out T, inout U, in V>
    var T = typeParameter('T', variance: Variance.covariant);
    var U = typeParameter('T', variance: Variance.invariant);
    var V = typeParameter('T', variance: Variance.contravariant);
    var Multi = class_(name: 'A', typeParameters: [T, U, V]);

    // Multi<num, num, num>
    // Multi<int, num, int>
    var multiNumNumNum =
        interfaceTypeStar(Multi, typeArguments: [numStar, numStar, numStar]);
    var multiIntNumInt =
        interfaceTypeStar(Multi, typeArguments: [intStar, numStar, intStar]);

    // We expect Multi<num, num, int>
    var multiNumNumInt =
        interfaceTypeStar(Multi, typeArguments: [numStar, numStar, intStar]);

    _checkLeastUpperBound(multiNumNumNum, multiIntNumInt, multiNumNumInt);
  }

  void test_typeParameters_multi_objectInterface() {
    // class Multi<out T, inout U, in V>
    var T = typeParameter('T', variance: Variance.covariant);
    var U = typeParameter('T', variance: Variance.invariant);
    var V = typeParameter('T', variance: Variance.contravariant);
    var Multi = class_(name: 'A', typeParameters: [T, U, V]);

    // Multi<num, String, num>
    // Multi<int, num, int>
    var multiNumStringNum =
        interfaceTypeStar(Multi, typeArguments: [numStar, stringStar, numStar]);
    var multiIntNumInt =
        interfaceTypeStar(Multi, typeArguments: [intStar, numStar, intStar]);

    _checkLeastUpperBound(multiNumStringNum, multiIntNumInt, objectStar);
  }

  void test_typeParameters_multi_objectType() {
    // class Multi<out T, inout U, in V>
    var T = typeParameter('T', variance: Variance.covariant);
    var U = typeParameter('T', variance: Variance.invariant);
    var V = typeParameter('T', variance: Variance.contravariant);
    var Multi = class_(name: 'A', typeParameters: [T, U, V]);

    // Multi<String, num, num>
    // Multi<int, num, int>
    var multiStringNumNum =
        interfaceTypeStar(Multi, typeArguments: [stringStar, numStar, numStar]);
    var multiIntNumInt =
        interfaceTypeStar(Multi, typeArguments: [intStar, numStar, intStar]);

    // We expect Multi<Object, num, int>
    var multiObjectNumInt =
        interfaceTypeStar(Multi, typeArguments: [objectStar, numStar, intStar]);

    _checkLeastUpperBound(multiStringNumNum, multiIntNumInt, multiObjectNumInt);
  }

  void test_typeParameters_same() {
    // List<int>
    // List<int>
    var listOfIntType = listStar(intStar);
    _checkLeastUpperBound(listOfIntType, listOfIntType, listOfIntType);
  }

  /// Check least upper bound of two related classes with different
  /// type parameters.
  void test_typeParametersAndClass_different() {
    // class List<int>
    // class Iterable<double>
    var listOfIntType = listStar(intStar);
    var iterableOfDoubleType = iterableStar(doubleStar);
    // TODO(leafp): this should be iterableOfNumType
    _checkLeastUpperBound(listOfIntType, iterableOfDoubleType, objectStar);
  }

  void test_void() {
    var T = typeParameter('T');
    var A = class_(name: 'A');
    List<DartType> types = [
      neverStar,
      functionTypeStar(returnType: voidNone),
      interfaceTypeStar(A),
      typeParameterTypeStar(T),
    ];
    for (DartType type in types) {
      _checkLeastUpperBound(
        functionTypeStar(returnType: voidNone),
        functionTypeStar(returnType: type),
        functionTypeStar(returnType: voidNone),
      );
    }
  }
}

@reflectiveTest
class TryPromoteToTest extends AbstractTypeSystemTest {
  @override
  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting(
      additionalFeatures: [Feature.non_nullable],
    );
  }

  void notPromotes(DartType from, DartType to) {
    var result = typeSystem.tryPromoteToType(to, from);
    expect(result, isNull);
  }

  void promotes(DartType from, DartType to) {
    var result = typeSystem.tryPromoteToType(to, from);
    expect(result, to);
  }

  test_interface() {
    promotes(intNone, intNone);
    promotes(intQuestion, intNone);
    promotes(intStar, intNone);

    promotes(numNone, intNone);
    promotes(numQuestion, intNone);
    promotes(numStar, intNone);

    notPromotes(intNone, doubleNone);
    notPromotes(intNone, intQuestion);
  }

  test_typeParameter() {
    void check(
      TypeParameterTypeImpl type,
      TypeParameterElement expectedElement,
      DartType expectedBound,
    ) {
      expect(type.element, expectedElement);
      expect(type.promotedBound, expectedBound);
    }

    var T = typeParameter('T');
    var T0 = typeParameterTypeNone(T);

    var T1 = typeSystem.tryPromoteToType(numNone, T0);
    check(T1, T, numNone);

    var T2 = typeSystem.tryPromoteToType(intNone, T1);
    check(T2, T, intNone);
  }
}

class _MockSource implements Source {
  @override
  final Uri uri;

  _MockSource(this.uri);

  @override
  String get encoding => '$uri';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
