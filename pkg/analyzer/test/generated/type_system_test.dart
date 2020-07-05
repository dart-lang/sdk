// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/least_upper_bound.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'elements_types_mixin.dart';
import 'test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignabilityTest);
    defineReflectiveTests(LeastUpperBoundFunctionsTest);
    defineReflectiveTests(LeastUpperBoundTest);
    defineReflectiveTests(TryPromoteToTest);
  });
}

abstract class AbstractTypeSystemNullSafetyTest with ElementsTypesMixin {
  TestAnalysisContext analysisContext;

  @override
  LibraryElementImpl testLibrary;

  @override
  TypeProvider typeProvider;

  TypeSystemImpl typeSystem;

  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting(
      additionalFeatures: [Feature.non_nullable],
    );
  }

  void setUp() {
    analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProviderNonNullableByDefault;
    typeSystem = analysisContext.typeSystemNonNullableByDefault;

    testLibrary = library_(
      uriStr: 'package:test/test.dart',
      analysisSession: analysisContext.analysisSession,
      typeSystem: typeSystem,
    );
  }
}

abstract class AbstractTypeSystemTest with ElementsTypesMixin {
  TestAnalysisContext analysisContext;

  @override
  LibraryElementImpl testLibrary;

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

    testLibrary = library_(
      uriStr: 'package:test/test.dart',
      analysisSession: analysisContext.analysisSession,
      typeSystem: typeSystem,
    );
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
}

/// Base class for testing LUB and GLB in spec and strong mode.
abstract class BoundTestBase extends AbstractTypeSystemTest {
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
