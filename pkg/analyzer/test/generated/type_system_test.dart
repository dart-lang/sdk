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
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart'
    show NonExistingSource, UriKind;
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' show toUri;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignabilityTest);
    defineReflectiveTests(ConstraintMatchingTest);
    defineReflectiveTests(GenericFunctionInferenceTest);
    defineReflectiveTests(GreatestLowerBoundTest);
    defineReflectiveTests(LeastUpperBoundFunctionsTest);
    defineReflectiveTests(LeastUpperBoundTest);
    defineReflectiveTests(NonNullableSubtypingTest);
    defineReflectiveTests(SubtypingTest);
    defineReflectiveTests(TypeSystemTest);
  });
}

abstract class AbstractTypeSystemTest {
  TypeProvider typeProvider;
  Dart2TypeSystem typeSystem;

  DartType get bottomType => typeProvider.bottomType;

  InterfaceType get doubleType => typeProvider.doubleType;

  DartType get dynamicType => typeProvider.dynamicType;

  InterfaceType get functionType => typeProvider.functionType;

  InterfaceType get intType => typeProvider.intType;

  DartType get neverType => typeProvider.neverType;

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
    return _interfaceType(futureOrElement, typeArguments: [T]);
  }

  DartType futureType(DartType T) {
    var futureElement = typeProvider.futureElement;
    return _interfaceType(futureElement, typeArguments: [T]);
  }

  DartType iterableType(DartType T) {
    var iterableElement = typeProvider.iterableElement;
    return _interfaceType(iterableElement, typeArguments: [T]);
  }

  DartType listType(DartType T) {
    var listElement = typeProvider.listElement;
    return _interfaceType(listElement, typeArguments: [T]);
  }

  void setUp() {
    var analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProvider;
    typeSystem = analysisContext.typeSystem;
  }

  ClassElementImpl _class({
    @required String name,
    bool isAbstract = false,
    InterfaceType superType,
    List<TypeParameterElement> typeParameters = const [],
    List<InterfaceType> interfaces = const [],
    List<InterfaceType> mixins = const [],
    List<MethodElement> methods = const [],
  }) {
    var element = ClassElementImpl(name, 0);
    element.typeParameters = typeParameters;
    element.supertype = superType ?? objectType;
    element.interfaces = interfaces;
    element.mixins = mixins;
    element.methods = methods;
    return element;
  }

  /**
   * Creates a function type with the given parameter and return types.
   *
   * The return type defaults to `void` if omitted.
   */
  FunctionType _functionType({
    List<TypeParameterElement> typeFormals,
    List<DartType> required,
    List<DartType> optional,
    Map<String, DartType> named,
    DartType returns,
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star,
  }) {
    if (optional != null && named != null) {
      throw ArgumentError(
        'Cannot have both optional positional and named parameters.',
      );
    }

    var parameters = <ParameterElement>[];
    if (required != null) {
      for (var i = 0; i < required.length; ++i) {
        parameters.add(
          ParameterElementImpl.synthetic(
            'r$i',
            required[i],
            ParameterKind.REQUIRED,
          ),
        );
      }
    }
    if (optional != null) {
      for (var i = 0; i < optional.length; ++i) {
        parameters.add(
          ParameterElementImpl.synthetic(
            'p$i',
            optional[i],
            ParameterKind.POSITIONAL,
          ),
        );
      }
    }
    if (named != null) {
      for (var namedEntry in named.entries) {
        parameters.add(
          ParameterElementImpl.synthetic(
            namedEntry.key,
            namedEntry.value,
            ParameterKind.NAMED,
          ),
        );
      }
    }

    return FunctionTypeImpl.synthetic(
      returns ?? voidType,
      typeFormals ?? const <TypeParameterElement>[],
      parameters,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  InterfaceType _interfaceType(
    ClassElement element, {
    List<DartType> typeArguments = const [],
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star,
  }) {
    return InterfaceTypeImpl.explicit(
      element,
      typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  MethodElementImpl _method(
    String name,
    DartType returnType, {
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    var element = MethodElementImpl(name, 0)
      ..parameters = parameters
      ..returnType = returnType
      ..typeParameters = typeFormals;
    element.type = _typeOfExecutableElement(element);
    return element;
  }

  ParameterElement _requiredParameter(String name, DartType type) {
    var parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.REQUIRED;
    parameter.type = type;
    return parameter;
  }

  /// TODO(scheglov) We should do the opposite - build type in the element.
  /// But build a similar synthetic / structured type.
  FunctionType _typeOfExecutableElement(ExecutableElement element) {
    return FunctionTypeImpl.synthetic(
      element.returnType,
      element.typeParameters,
      element.parameters,
    );
  }

  TypeParameterElementImpl _typeParameter(String name, {DartType bound}) {
    var element = TypeParameterElementImpl.synthetic(name);
    element.bound = bound;
    return element;
  }

  TypeParameterTypeImpl _typeParameterType(
    TypeParameterElement element, {
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star,
  }) {
    return TypeParameterTypeImpl(
      element,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

@reflectiveTest
class AssignabilityTest extends AbstractTypeSystemTest {
  void test_isAssignableTo_bottom_isBottom() {
    var A = _class(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      _interfaceType(A),
      bottomType,
    ];

    _checkGroups(bottomType, interassignable: interassignable);
  }

  void test_isAssignableTo_call_method() {
    var B = _class(
      name: 'B',
      methods: [
        _method('call', objectType, parameters: [
          _requiredParameter('_', intType),
        ]),
      ],
    );

    _checkIsStrictAssignableTo(
      _interfaceType(B),
      _functionType(required: [intType], returns: objectType),
    );
  }

  void test_isAssignableTo_classes() {
    var classTop = _class(name: 'A');
    var classLeft = _class(name: 'B', superType: _interfaceType(classTop));
    var classRight = _class(name: 'C', superType: _interfaceType(classTop));
    var classBottom = _class(
      name: 'D',
      superType: _interfaceType(classLeft),
      interfaces: [_interfaceType(classRight)],
    );
    var top = _interfaceType(classTop);
    var left = _interfaceType(classLeft);
    var right = _interfaceType(classRight);
    var bottom = _interfaceType(classBottom);

    _checkLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_double() {
    var A = _class(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      doubleType,
      numType,
      bottomType,
    ];
    List<DartType> unrelated = <DartType>[
      intType,
      stringType,
      _interfaceType(A),
    ];

    _checkGroups(doubleType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_dynamic_isTop() {
    var A = _class(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      _interfaceType(A),
      bottomType,
    ];
    _checkGroups(dynamicType, interassignable: interassignable);
  }

  void test_isAssignableTo_generics() {
    var LT = _typeParameter('T');
    var L = _class(name: 'L', typeParameters: [LT]);

    var MT = _typeParameter('T');
    var M = _class(
      name: 'M',
      typeParameters: [MT],
      interfaces: [
        _interfaceType(
          L,
          typeArguments: [_typeParameterType(MT)],
        ),
      ],
    );

    var top = _interfaceType(L, typeArguments: [dynamicType]);
    var left = _interfaceType(M, typeArguments: [dynamicType]);
    var right = _interfaceType(L, typeArguments: [intType]);
    var bottom = _interfaceType(M, typeArguments: [intType]);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_int() {
    var A = _class(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      numType,
      bottomType,
    ];
    List<DartType> unrelated = <DartType>[
      doubleType,
      stringType,
      _interfaceType(A),
    ];

    _checkGroups(intType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_named_optional() {
    var r = _functionType(required: [intType], returns: intType);
    var o = _functionType(optional: [intType], returns: intType);
    var n = _functionType(named: {'x': intType}, returns: intType);

    var rr = _functionType(
      required: [intType, intType],
      returns: intType,
    );
    var ro = _functionType(
      required: [intType],
      optional: [intType],
      returns: intType,
    );
    var rn = _functionType(
      required: [intType],
      named: {'x': intType},
      returns: intType,
    );
    var oo = _functionType(
      optional: [intType, intType],
      returns: intType,
    );
    var nn = _functionType(
      named: {'x': intType, 'y': intType},
      returns: intType,
    );
    var nnn = _functionType(
      named: {'x': intType, 'y': intType, 'z': intType},
      returns: intType,
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
    var A = _class(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      numType,
      intType,
      doubleType,
      bottomType,
    ];
    List<DartType> unrelated = <DartType>[
      stringType,
      _interfaceType(A),
    ];

    _checkGroups(numType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_simple_function() {
    var top = _functionType(required: [intType], returns: objectType);
    var left = _functionType(required: [intType], returns: intType);
    var right = _functionType(required: [objectType], returns: objectType);
    var bottom = _functionType(required: [objectType], returns: intType);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_void_functions() {
    var top = _functionType(required: [intType], returns: voidType);
    var bottom = _functionType(required: [objectType], returns: intType);

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
    // Check for symmetry while we're at it.  Unfortunately,
    // for function types, the current version of equality
    // does not respect re-ordering of named parameters, so
    // for function types we just check if they are mutual subtypes.
    // https://github.com/dart-lang/sdk/issues/26126
    // TODO(leafp): Fix this.
    glb = typeSystem.getGreatestLowerBound(type2, type1);
    if (glb is FunctionTypeImpl) {
      expect(typeSystem.isSubtypeOf(glb, expectedResult), true);
      expect(typeSystem.isSubtypeOf(expectedResult, glb), true);
    } else {
      expect(glb, expectedResult);
    }
  }

  void _checkLeastUpperBound(
      DartType type1, DartType type2, DartType expectedResult) {
    var lub = typeSystem.getLeastUpperBound(type1, type2);
    expect(lub, expectedResult);
    // Check that the result is an upper bound.
    expect(typeSystem.isSubtypeOf(type1, lub), true);
    expect(typeSystem.isSubtypeOf(type2, lub), true);

    // Check for symmetry while we're at it.  Unfortunately,
    // for function types, the current version of equality
    // does not respect re-ordering of named parameters, so
    // for function types we just check if they are mutual subtypes.
    // https://github.com/dart-lang/sdk/issues/26126
    // TODO(leafp): Fix this.
    lub = typeSystem.getLeastUpperBound(type2, type1);
    if (lub is FunctionTypeImpl) {
      expect(typeSystem.isSubtypeOf(lub, expectedResult), true);
      expect(typeSystem.isSubtypeOf(expectedResult, lub), true);
    } else {
      expect(lub, expectedResult);
    }
  }
}

@reflectiveTest
class ConstraintMatchingTest extends AbstractTypeSystemTest {
  TypeParameterType T;

  void setUp() {
    super.setUp();
    T = _typeParameterType(
      _typeParameter('T'),
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  void test_function_coreFunction() {
    _checkOrdinarySubtypeMatch(
      _functionType(required: [intType], returns: stringType),
      functionType,
      [T],
      covariant: true,
    );
  }

  void test_function_parameter_types() {
    _checkIsSubtypeMatchOf(
      _functionType(required: [T], returns: intType),
      _functionType(required: [stringType], returns: intType),
      [T],
      ['String <: T'],
      covariant: true,
    );
  }

  void test_function_return_types() {
    _checkIsSubtypeMatchOf(
      _functionType(required: [intType], returns: T),
      _functionType(required: [intType], returns: stringType),
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
      _functionType(required: [intType], returns: stringType),
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
    var S = _typeParameterType(
      _typeParameter('S'),
    );
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
    var S = _typeParameterType(
      _typeParameter(
        'S',
        bound: listType(stringType),
      ),
    );
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
    var S = _typeParameterType(
      _typeParameter('S'),
    );
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
    var S = _typeParameterType(
      _typeParameter('S'),
    );
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
      _functionType(required: [intType], returns: stringType),
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
      _functionType(required: [intType], returns: stringType),
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
      _functionType(required: [intType], returns: stringType),
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
    var tFrom = _typeParameter('TFrom');
    var tTo =
        _typeParameter('TTo', bound: iterableType(_typeParameterType(tFrom)));
    var cast = _functionType(
      typeFormals: [tFrom, tTo],
      required: [_typeParameterType(tFrom)],
      returns: _typeParameterType(tTo),
    );
    expect(
        _inferCall(cast, [stringType]), [stringType, iterableType(stringType)]);
  }

  void test_boundedByOuterClass() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var A = _class(name: 'A', superType: objectType);
    var typeA = _interfaceType(A);

    // class B extends A {}
    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    // class C<T extends A> {
    var CT = _typeParameter('T', bound: typeA);
    var C = _class(
      name: 'C',
      superType: objectType,
      typeParameters: [CT],
    );
    //   S m<S extends T>(S);
    var S = _typeParameter('S', bound: _typeParameterType(CT));
    var m = _method(
      'm',
      _typeParameterType(S),
      typeFormals: [S],
      parameters: [_requiredParameter('_', _typeParameterType(S))],
    );
    C.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = _interfaceType(C, typeArguments: [objectType]);
    // C<A> cOfA;
    var cOfA = _interfaceType(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = _interfaceType(C, typeArguments: [typeB]);
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
    var A = _class(name: 'A', superType: objectType);
    var typeA = _interfaceType(A);

    // class B extends A {}
    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    // class C<T extends A> {
    var CT = _typeParameter('T', bound: typeA);
    var C = _class(
      name: 'C',
      superType: objectType,
      typeParameters: [CT],
    );
    //   S m<S extends Iterable<T>>(S);
    var iterableOfT = iterableType(_typeParameterType(CT));
    var S = _typeParameter('S', bound: iterableOfT);
    var m = _method(
      'm',
      _typeParameterType(S),
      typeFormals: [S],
      parameters: [_requiredParameter('_', _typeParameterType(S))],
    );
    C.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = _interfaceType(C, typeArguments: [objectType]);
    // C<A> cOfA;
    var cOfA = _interfaceType(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = _interfaceType(C, typeArguments: [typeB]);
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
    var T = _typeParameter('T');
    var A = _class(
      name: 'Cloneable',
      superType: objectType,
      typeParameters: [T],
    );
    T.bound = _interfaceType(
      A,
      typeArguments: [_typeParameterType(T)],
    );

    // class B extends A<B> {}
    var B = _class(name: 'B', superType: null);
    B.supertype = _interfaceType(A, typeArguments: [_interfaceType(B)]);
    var typeB = _interfaceType(B);

    // <S extends A<S>>
    var S = _typeParameter('S');
    var typeS = _typeParameterType(S);
    S.bound = _interfaceType(A, typeArguments: [typeS]);

    // (S, S) -> S
    var clone = _functionType(
      typeFormals: [S],
      required: [typeS, typeS],
      returns: typeS,
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
    var tFrom = _typeParameter('TFrom');
    var tTo = _typeParameter('TTo');
    var cast = _functionType(
      typeFormals: [tFrom, tTo],
      required: [_typeParameterType(tFrom)],
      returns: _typeParameterType(tTo),
    );
    expect(_inferCall(cast, [intType]), [intType, dynamicType]);
  }

  void test_genericCastFunctionWithUpperBound() {
    // <TFrom, TTo extends TFrom>(TFrom) -> TTo
    var tFrom = _typeParameter('TFrom');
    var tTo = _typeParameter('TTo', bound: _typeParameterType(tFrom));
    var cast = _functionType(
      typeFormals: [tFrom, tTo],
      required: [_typeParameterType(tFrom)],
      returns: _typeParameterType(tTo),
    );
    expect(_inferCall(cast, [intType]), [intType, intType]);
  }

  void test_parametersToFunctionParam() {
    // <T>(f(T t)) -> T
    var T = _typeParameter('T');
    var cast = _functionType(
      typeFormals: [T],
      required: [
        _functionType(
          required: [_typeParameterType(T)],
          returns: dynamicType,
        )
      ],
      returns: _typeParameterType(T),
    );
    expect(
      _inferCall(cast, [
        _functionType(
          required: [numType],
          returns: dynamicType,
        )
      ]),
      [numType],
    );
  }

  void test_parametersUseLeastUpperBound() {
    // <T>(T x, T y) -> T
    var T = _typeParameter('T');
    var cast = _functionType(
      typeFormals: [T],
      required: [
        _typeParameterType(T),
        _typeParameterType(T),
      ],
      returns: _typeParameterType(T),
    );
    expect(_inferCall(cast, [intType, doubleType]), [numType]);
  }

  void test_parameterTypeUsesUpperBound() {
    // <T extends num>(T) -> dynamic
    var T = _typeParameter('T', bound: numType);
    var f = _functionType(
      typeFormals: [T],
      required: [
        _typeParameterType(T),
      ],
      returns: dynamicType,
    );
    expect(_inferCall(f, [intType]), [intType]);
  }

  void test_returnFunctionWithGenericParameter() {
    // <T>(T -> T) -> (T -> void)
    var T = _typeParameter('T');
    var f = _functionType(
      typeFormals: [T],
      required: [
        _functionType(
          required: [
            _typeParameterType(T),
          ],
          returns: _typeParameterType(T),
        )
      ],
      returns: _functionType(
        required: [
          _typeParameterType(T),
        ],
        returns: voidType,
      ),
    );
    expect(
      _inferCall(f, [
        _functionType(required: [numType], returns: intType)
      ]),
      [intType],
    );
  }

  void test_returnFunctionWithGenericParameterAndContext() {
    // <T>(T -> T) -> (T -> Null)
    var T = _typeParameter('T');
    var f = _functionType(
      typeFormals: [T],
      required: [
        _functionType(
          required: [
            _typeParameterType(T),
          ],
          returns: _typeParameterType(T),
        )
      ],
      returns: _functionType(
        required: [
          _typeParameterType(T),
        ],
        returns: nullType,
      ),
    );
    expect(
      _inferCall(
        f,
        [],
        returnType: _functionType(
          required: [numType],
          returns: intType,
        ),
      ),
      [numType],
    );
  }

  void test_returnFunctionWithGenericParameterAndReturn() {
    // <T>(T -> T) -> (T -> T)
    var T = _typeParameter('T');
    var f = _functionType(
      typeFormals: [T],
      required: [
        _functionType(
          required: [
            _typeParameterType(T),
          ],
          returns: _typeParameterType(T),
        )
      ],
      returns: _functionType(
        required: [
          _typeParameterType(T),
        ],
        returns: _typeParameterType(T),
      ),
    );
    expect(
      _inferCall(f, [
        _functionType(
          required: [numType],
          returns: intType,
        )
      ]),
      [intType],
    );
  }

  void test_returnFunctionWithGenericReturn() {
    // <T>(T -> T) -> (() -> T)
    var T = _typeParameter('T');
    var f = _functionType(
      typeFormals: [T],
      required: [
        _functionType(
          required: [
            _typeParameterType(T),
          ],
          returns: _typeParameterType(T),
        )
      ],
      returns: _functionType(
        returns: _typeParameterType(T),
      ),
    );
    expect(
      _inferCall(f, [
        _functionType(
          required: [numType],
          returns: intType,
        )
      ]),
      [intType],
    );
  }

  void test_returnTypeFromContext() {
    // <T>() -> T
    var T = _typeParameter('T');
    var f = _functionType(
      typeFormals: [T],
      returns: _typeParameterType(T),
    );
    expect(_inferCall(f, [], returnType: stringType), [stringType]);
  }

  void test_returnTypeWithBoundFromContext() {
    // <T extends num>() -> T
    var T = _typeParameter('T', bound: numType);
    var f = _functionType(
      typeFormals: [T],
      returns: _typeParameterType(T),
    );
    expect(_inferCall(f, [], returnType: doubleType), [doubleType]);
  }

  void test_returnTypeWithBoundFromInvalidContext() {
    // <T extends num>() -> T
    var T = _typeParameter('T', bound: numType);
    var f = _functionType(
      typeFormals: [T],
      returns: _typeParameterType(T),
    );
    expect(_inferCall(f, [], returnType: stringType), [nullType]);
  }

  void test_unifyParametersToFunctionParam() {
    // <T>(f(T t), g(T t)) -> T
    var T = _typeParameter('T');
    var cast = _functionType(
      typeFormals: [T],
      required: [
        _functionType(
          required: [_typeParameterType(T)],
          returns: dynamicType,
        ),
        _functionType(
          required: [_typeParameterType(T)],
          returns: dynamicType,
        )
      ],
      returns: _typeParameterType(T),
    );
    expect(
      _inferCall(cast, [
        _functionType(required: [intType], returns: dynamicType),
        _functionType(required: [doubleType], returns: dynamicType)
      ]),
      [nullType],
    );
  }

  void test_unusedReturnTypeIsDynamic() {
    // <T>() -> T
    var T = _typeParameter('T');
    var f = _functionType(
      typeFormals: [T],
      returns: _typeParameterType(T),
    );
    expect(_inferCall(f, []), [dynamicType]);
  }

  void test_unusedReturnTypeWithUpperBound() {
    // <T extends num>() -> T
    var T = _typeParameter('T', bound: numType);
    var f = _functionType(
      typeFormals: [T],
      returns: _typeParameterType(T),
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
    _checkGreatestLowerBound(bottomType, _functionType(), bottomType);
  }

  void test_bottom_interface() {
    var A = _class(name: 'A');
    _checkGreatestLowerBound(bottomType, _interfaceType(A), bottomType);
  }

  void test_bottom_typeParam() {
    var T = _typeParameter('T');
    _checkGreatestLowerBound(bottomType, _typeParameterType(T), bottomType);
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
    var A = _class(name: 'A');
    var B = _class(name: 'B', superType: _interfaceType(A));
    var C = _class(name: 'C', superType: _interfaceType(B));
    _checkGreatestLowerBound(
      _interfaceType(A),
      _interfaceType(C),
      _interfaceType(C),
    );
  }

  void test_classAndSuperinterface() {
    // class A
    // class B implements A
    // class C implements B
    var A = _class(name: 'A');
    var B = _class(name: 'B', interfaces: [_interfaceType(A)]);
    var C = _class(name: 'C', interfaces: [_interfaceType(B)]);
    _checkGreatestLowerBound(
      _interfaceType(A),
      _interfaceType(C),
      _interfaceType(C),
    );
  }

  void test_dynamic_bottom() {
    _checkGreatestLowerBound(dynamicType, bottomType, bottomType);
  }

  void test_dynamic_function() {
    _checkGreatestLowerBound(dynamicType, _functionType(), _functionType());
  }

  void test_dynamic_interface() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);
    _checkGreatestLowerBound(dynamicType, typeA, typeA);
  }

  void test_dynamic_typeParam() {
    var T = _typeParameter('T');
    var typeT = _typeParameterType(T);
    _checkGreatestLowerBound(dynamicType, typeT, typeT);
  }

  void test_dynamic_void() {
    // Note: _checkGreatestLowerBound tests `GLB(x, y)` as well as `GLB(y, x)`
    _checkGreatestLowerBound(dynamicType, voidType, dynamicType);
  }

  void test_functionsDifferentNamedTakeUnion() {
    var type1 = _functionType(
      named: {'a': intType, 'b': intType},
    );
    var type2 = _functionType(
      named: {'b': doubleType, 'c': stringType},
    );
    var expected = _functionType(
      named: {'a': intType, 'b': numType, 'c': stringType},
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsDifferentOptionalArityTakeMax() {
    var type1 = _functionType(
      optional: [intType],
    );
    var type2 = _functionType(
      optional: [doubleType, stringType, objectType],
    );
    var expected = _functionType(
      optional: [numType, stringType, objectType],
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsDifferentRequiredArityBecomeOptional() {
    var type1 = _functionType(
      required: [intType],
    );
    var type2 = _functionType(
      required: [intType, intType, intType],
    );
    var expected = _functionType(
      required: [intType],
      optional: [intType, intType],
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsFromDynamic() {
    var type1 = _functionType(required: [dynamicType]);
    var type2 = _functionType(required: [intType]);
    var expected = _functionType(required: [dynamicType]);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsGlbReturnType() {
    var type1 = _functionType(returns: intType);
    var type2 = _functionType(returns: numType);
    var expected = _functionType(returns: intType);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubNamedParams() {
    var type1 = _functionType(
      named: {'a': stringType, 'b': intType},
    );
    var type2 = _functionType(
      named: {'a': intType, 'b': numType},
    );
    var expected = _functionType(
      named: {'a': objectType, 'b': numType},
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubPositionalParams() {
    var type1 = _functionType(
      optional: [stringType, intType],
    );
    var type2 = _functionType(
      optional: [intType, numType],
    );
    var expected = _functionType(
      optional: [objectType, numType],
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubRequiredParams() {
    var type1 = _functionType(
      required: [stringType, intType, intType],
    );
    var type2 = _functionType(
      required: [intType, doubleType, numType],
    );
    var expected = _functionType(
      required: [objectType, numType, numType],
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsMixedOptionalAndRequiredBecomeOptional() {
    var type1 = _functionType(
      required: [intType, intType],
      optional: [intType, intType, intType],
    );
    var type2 = _functionType(
      required: [intType],
      optional: [intType, intType],
    );
    var expected = _functionType(
      required: [intType],
      optional: [intType, intType, intType, intType],
    );
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsReturnBottomIfMixOptionalAndNamed() {
    // Dart doesn't allow a function to have both optional and named parameters,
    // so if we would have synthethized that, pick bottom instead.
    var type1 = _functionType(
      required: [intType],
      named: {'a': intType},
    );
    var type2 = _functionType(
      named: {'a': intType},
    );
    _checkGreatestLowerBound(type1, type2, bottomType);
  }

  void test_functionsSameType_withNamed() {
    var type1 = _functionType(
      required: [stringType, intType, numType],
      named: {'n': numType},
      returns: intType,
    );

    var type2 = _functionType(
      required: [stringType, intType, numType],
      named: {'n': numType},
      returns: intType,
    );

    var expected = _functionType(
      required: [stringType, intType, numType],
      named: {'n': numType},
      returns: intType,
    );

    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsSameType_withOptional() {
    var type1 = _functionType(
      required: [stringType, intType, numType],
      optional: [doubleType],
      returns: intType,
    );

    var type2 = _functionType(
      required: [stringType, intType, numType],
      optional: [doubleType],
      returns: intType,
    );

    var expected = _functionType(
      required: [stringType, intType, numType],
      optional: [doubleType],
      returns: intType,
    );

    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_interface_function() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);
    _checkGreatestLowerBound(typeA, _functionType(), bottomType);
  }

  void test_mixin() {
    // class A
    // class B
    // class C
    // class D extends A with B, C
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B');
    var typeB = _interfaceType(B);

    var C = _class(name: 'C');
    var typeC = _interfaceType(C);

    var D = _class(
      name: 'D',
      superType: _interfaceType(A),
      mixins: [typeB, typeC],
    );
    var typeD = _interfaceType(D);

    _checkGreatestLowerBound(typeA, typeD, typeD);
    _checkGreatestLowerBound(typeB, typeD, typeD);
    _checkGreatestLowerBound(typeC, typeD, typeD);
  }

  void test_self() {
    var T = _typeParameter('T');
    var A = _class(name: 'A');

    List<DartType> types = [
      dynamicType,
      voidType,
      bottomType,
      _typeParameterType(T),
      _interfaceType(A),
      _functionType(),
    ];

    for (DartType type in types) {
      _checkGreatestLowerBound(type, type, type);
    }
  }

  void test_typeParam_function_noBound() {
    var T = _typeParameter('T');
    _checkGreatestLowerBound(
      _typeParameterType(T),
      _functionType(),
      bottomType,
    );
  }

  void test_typeParam_interface_bounded() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', superType: typeB);
    var typeC = _interfaceType(C);

    var T = _typeParameter('T', bound: typeB);
    _checkGreatestLowerBound(_typeParameterType(T), typeC, bottomType);
  }

  void test_typeParam_interface_noBound() {
    // GLB(T, A) = ⊥
    var T = _typeParameter('T');
    var A = _class(name: 'A');
    _checkGreatestLowerBound(
      _typeParameterType(T),
      _interfaceType(A),
      bottomType,
    );
  }

  void test_typeParameters_different() {
    // GLB(List<int>, List<double>) = ⊥
    var listOfIntType = listType(intType);
    var listOfDoubleType = listType(doubleType);
    // TODO(rnystrom): Can we do something better here?
    _checkGreatestLowerBound(listOfIntType, listOfDoubleType, bottomType);
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
    var A = _class(name: 'A');
    var B = _class(name: 'B');
    _checkGreatestLowerBound(_interfaceType(A), _interfaceType(B), bottomType);
  }

  void test_void() {
    var A = _class(name: 'A');
    var T = _typeParameter('T');
    List<DartType> types = [
      bottomType,
      _functionType(),
      _interfaceType(A),
      _typeParameterType(T),
    ];
    for (DartType type in types) {
      _checkGreatestLowerBound(
        _functionType(returns: voidType),
        _functionType(returns: type),
        _functionType(returns: type),
      );
    }
  }
}

@reflectiveTest
class LeastUpperBoundFunctionsTest extends BoundTestBase {
  void test_differentRequiredArity() {
    var type1 = _functionType(required: [intType, intType]);
    var type2 = _functionType(required: [intType, intType, intType]);
    _checkLeastUpperBound(type1, type2, functionType);
  }

  void test_fuzzyArrows() {
    var type1 = _functionType(required: [dynamicType]);
    var type2 = _functionType(required: [intType]);
    var expected = _functionType(required: [intType]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_glbNamedParams() {
    var type1 = _functionType(
      named: {'a': stringType, 'b': intType},
    );
    var type2 = _functionType(
      named: {'a': intType, 'b': numType},
    );
    var expected = _functionType(
      named: {'a': bottomType, 'b': intType},
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_glbPositionalParams() {
    var type1 = _functionType(
      optional: [stringType, intType],
    );
    var type2 = _functionType(
      optional: [intType, numType],
    );
    var expected = _functionType(
      optional: [bottomType, intType],
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_glbRequiredParams() {
    var type1 = _functionType(
      required: [stringType, intType, intType],
    );
    var type2 = _functionType(
      required: [intType, doubleType, numType],
    );
    var expected = _functionType(
      required: [bottomType, bottomType, intType],
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_ignoreExtraNamedParams() {
    var type1 = _functionType(
      named: {'a': intType, 'b': intType},
    );
    var type2 = _functionType(
      named: {'a': intType, 'c': intType},
    );
    var expected = _functionType(
      named: {'a': intType},
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_ignoreExtraPositionalParams() {
    var type1 = _functionType(
      optional: [intType, intType, stringType],
    );
    var type2 = _functionType(
      optional: [intType],
    );
    var expected = _functionType(
      optional: [intType],
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_lubReturnType() {
    var type1 = _functionType(returns: intType);
    var type2 = _functionType(returns: doubleType);
    var expected = _functionType(returns: numType);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_sameType_withNamed() {
    var type1 = _functionType(
      required: [stringType, intType, numType],
      named: {'n': numType},
      returns: intType,
    );

    var type2 = _functionType(
      required: [stringType, intType, numType],
      named: {'n': numType},
      returns: intType,
    );

    var expected = _functionType(
      required: [stringType, intType, numType],
      named: {'n': numType},
      returns: intType,
    );

    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_sameType_withOptional() {
    var type1 = _functionType(
      required: [stringType, intType, numType],
      optional: [doubleType],
      returns: intType,
    );

    var type2 = _functionType(
      required: [stringType, intType, numType],
      optional: [doubleType],
      returns: intType,
    );

    var expected = _functionType(
      required: [stringType, intType, numType],
      optional: [doubleType],
      returns: intType,
    );

    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_typeFormals_differentBounds() {
    var T1 = _typeParameter('T1', bound: intType);
    var type1 = _functionType(
      typeFormals: [T1],
      returns: _typeParameterType(T1),
    );

    var T2 = _typeParameter('T2', bound: doubleType);
    var type2 = _functionType(
      typeFormals: [T2],
      returns: _typeParameterType(T2),
    );

    _checkLeastUpperBound(type1, type2, functionType);
  }

  void test_typeFormals_differentNumber() {
    var T1 = _typeParameter('T1', bound: numType);
    var type1 = _functionType(
      typeFormals: [T1],
      returns: _typeParameterType(T1),
    );

    var type2 = _functionType(returns: intType);

    _checkLeastUpperBound(type1, type2, functionType);
  }

  void test_typeFormals_sameBounds() {
    var T1 = _typeParameter('T1', bound: numType);
    var type1 = _functionType(
      typeFormals: [T1],
      returns: _typeParameterType(T1),
    );

    var T2 = _typeParameter('T2', bound: numType);
    var type2 = _functionType(
      typeFormals: [T2],
      returns: _typeParameterType(T2),
    );

    var TE = _typeParameter('T', bound: numType);
    var expected = _functionType(
      typeFormals: [TE],
      returns: _typeParameterType(TE),
    );

    _checkLeastUpperBound(type1, type2, expected);
  }
}

@reflectiveTest
class LeastUpperBoundTest extends BoundTestBase {
  void test_bottom_function() {
    _checkLeastUpperBound(bottomType, _functionType(), _functionType());
  }

  void test_bottom_interface() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);
    _checkLeastUpperBound(bottomType, typeA, typeA);
  }

  void test_bottom_typeParam() {
    var T = _typeParameter('T');
    var typeT = _typeParameterType(T);
    _checkLeastUpperBound(bottomType, typeT, typeT);
  }

  void test_directInterfaceCase() {
    // class A
    // class B implements A
    // class C implements B

    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', interfaces: [typeA]);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', interfaces: [typeB]);
    var typeC = _interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_directSubclassCase() {
    // class A
    // class B extends A
    // class C extends B

    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', superType: typeB);
    var typeC = _interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_directSuperclass_nullability() {
    var aElement = _class(name: 'A');
    var aQuestion = _interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.question,
    );
    var aStar = _interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    var aNone = _interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var bElementStar = _class(name: 'B', superType: aStar);
    var bElementNone = _class(name: 'B', superType: aNone);

    InterfaceTypeImpl _bTypeStarElement(NullabilitySuffix nullability) {
      return _interfaceType(
        bElementStar,
        nullabilitySuffix: nullability,
      );
    }

    InterfaceTypeImpl _bTypeNoneElement(NullabilitySuffix nullability) {
      return _interfaceType(
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
    _checkLeastUpperBound(dynamicType, bottomType, dynamicType);
  }

  void test_dynamic_function() {
    _checkLeastUpperBound(dynamicType, _functionType(), dynamicType);
  }

  void test_dynamic_interface() {
    var A = _class(name: 'A');
    _checkLeastUpperBound(dynamicType, _interfaceType(A), dynamicType);
  }

  void test_dynamic_typeParam() {
    var T = _typeParameter('T');
    _checkLeastUpperBound(dynamicType, _typeParameterType(T), dynamicType);
  }

  void test_dynamic_void() {
    // Note: _checkLeastUpperBound tests `LUB(x, y)` as well as `LUB(y, x)`
    _checkLeastUpperBound(dynamicType, voidType, voidType);
  }

  void test_interface_function() {
    var A = _class(name: 'A');
    _checkLeastUpperBound(_interfaceType(A), _functionType(), objectType);
  }

  void test_interface_sameElement_nullability() {
    var aElement = _class(name: 'A');

    var aQuestion = _interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.question,
    );
    var aStar = _interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    var aNone = _interfaceType(
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
    var classA = _class(name: 'A');
    var instA = InstantiatedClass(classA, []);

    var classB = _class(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );

    var mixinM = ElementFactory.mixinElement(
      name: 'M',
      constraints: [instA.withNullabilitySuffixNone],
    );

    _checkLeastUpperBound(
      _interfaceType(
        classB,
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      _interfaceType(
        mixinM,
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      instA.withNullability(NullabilitySuffix.star),
    );
  }

  void test_mixinAndClass_object() {
    var classA = _class(name: 'A');
    var mixinM = ElementFactory.mixinElement(name: 'M');

    _checkLeastUpperBound(
      _interfaceType(classA),
      _interfaceType(mixinM),
      objectType,
    );
  }

  void test_mixinAndClass_sharedInterface() {
    var classA = _class(name: 'A');
    var instA = InstantiatedClass(classA, []);

    var classB = _class(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );

    var mixinM = ElementFactory.mixinElement(
      name: 'M',
      interfaces: [instA.withNullabilitySuffixNone],
    );

    _checkLeastUpperBound(
      _interfaceType(
        classB,
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      _interfaceType(
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

    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', superType: typeA);
    var typeC = _interfaceType(C);

    var D = _class(
      name: 'D',
      superType: typeB,
      mixins: [
        _interfaceType(_class(name: 'M')),
        _interfaceType(_class(name: 'N')),
        _interfaceType(_class(name: 'O')),
        _interfaceType(_class(name: 'P')),
      ],
    );
    var typeD = _interfaceType(D);

    _checkLeastUpperBound(typeD, typeC, typeA);
  }

  void test_nestedFunctionsLubInnerParamTypes() {
    var type1 = _functionType(
      required: [
        _functionType(required: [stringType, intType, intType])
      ],
    );
    var type2 = _functionType(
      required: [
        _functionType(required: [intType, doubleType, numType])
      ],
    );
    var expected = _functionType(
      required: [
        _functionType(required: [objectType, numType, numType])
      ],
    );
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_nestedNestedFunctionsGlbInnermostParamTypes() {
    var type1 = _functionType(required: [
      _functionType(required: [
        _functionType(required: [stringType, intType, intType])
      ])
    ]);
    var type2 = _functionType(required: [
      _functionType(required: [
        _functionType(required: [intType, doubleType, numType])
      ])
    ]);
    var expected = _functionType(required: [
      _functionType(required: [
        _functionType(required: [bottomType, bottomType, intType])
      ])
    ]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_object() {
    var A = _class(name: 'A');
    var B = _class(name: 'B');
    var typeA = _interfaceType(A);
    var typeB = _interfaceType(B);
    var typeObject = typeA.element.supertype;
    // assert that object does not have a super type
    expect(typeObject.element.supertype, isNull);
    // assert that both A and B have the same super type of Object
    expect(typeB.element.supertype, typeObject);
    // finally, assert that the only least upper bound of A and B is Object
    _checkLeastUpperBound(typeA, typeB, typeObject);
  }

  void test_self() {
    var T = _typeParameter('T');
    var A = _class(name: 'A');

    List<DartType> types = [
      dynamicType,
      voidType,
      bottomType,
      _typeParameterType(T),
      _interfaceType(A),
      _functionType()
    ];

    for (DartType type in types) {
      _checkLeastUpperBound(type, type, type);
    }
  }

  void test_sharedSuperclass1() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', superType: typeA);
    var typeC = _interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperclass1_nullability() {
    var aElement = _class(name: 'A');
    var aQuestion = _interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.question,
    );
    var aStar = _interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    var aNone = _interfaceType(
      aElement,
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var bElementNone = _class(name: 'B', superType: aNone);
    var bElementStar = _class(name: 'B', superType: aStar);

    var cElementNone = _class(name: 'C', superType: aNone);
    var cElementStar = _class(name: 'C', superType: aStar);

    InterfaceTypeImpl bTypeElementNone(NullabilitySuffix nullability) {
      return _interfaceType(
        bElementNone,
        nullabilitySuffix: nullability,
      );
    }

    InterfaceTypeImpl bTypeElementStar(NullabilitySuffix nullability) {
      return _interfaceType(
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
      return _interfaceType(
        cElementNone,
        nullabilitySuffix: nullability,
      );
    }

    InterfaceTypeImpl cTypeElementStar(NullabilitySuffix nullability) {
      return _interfaceType(
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
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', superType: typeA);
    var typeC = _interfaceType(C);

    var D = _class(name: 'D', superType: typeC);
    var typeD = _interfaceType(D);

    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperclass3() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', superType: typeB);
    var typeC = _interfaceType(C);

    var D = _class(name: 'D', superType: typeB);
    var typeD = _interfaceType(D);

    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperclass4() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var A2 = _class(name: 'A2');
    var typeA2 = _interfaceType(A2);

    var A3 = _class(name: 'A3');
    var typeA3 = _interfaceType(A3);

    var B = _class(name: 'B', superType: typeA, interfaces: [typeA2]);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', superType: typeA, interfaces: [typeA3]);
    var typeC = _interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface1() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', interfaces: [typeA]);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', interfaces: [typeA]);
    var typeC = _interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface2() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', interfaces: [typeA]);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', interfaces: [typeA]);
    var typeC = _interfaceType(C);

    var D = _class(name: 'D', interfaces: [typeC]);
    var typeD = _interfaceType(D);

    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperinterface3() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', interfaces: [typeA]);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', interfaces: [typeB]);
    var typeC = _interfaceType(C);

    var D = _class(name: 'D', interfaces: [typeB]);
    var typeD = _interfaceType(D);

    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperinterface4() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var A2 = _class(name: 'A2');
    var typeA2 = _interfaceType(A2);

    var A3 = _class(name: 'A3');
    var typeA3 = _interfaceType(A3);

    var B = _class(name: 'B', interfaces: [typeA, typeA2]);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', interfaces: [typeA, typeA3]);
    var typeC = _interfaceType(C);

    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_twoComparables() {
    _checkLeastUpperBound(stringType, numType, objectType);
  }

  void test_typeParam_boundedByParam() {
    var S = _typeParameter('S');
    var typeS = _typeParameterType(S);

    var T = _typeParameter('T', bound: typeS);
    var typeT = _typeParameterType(T);

    _checkLeastUpperBound(typeT, typeS, typeS);
  }

  void test_typeParam_class_implements_Function_ignored() {
    var A = _class(name: 'A', superType: functionType);
    var T = _typeParameter('T', bound: _interfaceType(A));
    _checkLeastUpperBound(_typeParameterType(T), _functionType(), objectType);
  }

  void test_typeParam_fBounded() {
    var T = _typeParameter('Q');
    var A = _class(name: 'A', typeParameters: [T]);

    var S = _typeParameter('S');
    var typeS = _typeParameterType(S);
    S.bound = _interfaceType(A, typeArguments: [typeS]);

    var U = _typeParameter('U');
    var typeU = _typeParameterType(U);
    U.bound = _interfaceType(A, typeArguments: [typeU]);

    _checkLeastUpperBound(
      typeS,
      _typeParameterType(U),
      _interfaceType(A, typeArguments: [objectType]),
    );
  }

  void test_typeParam_function_bounded() {
    var T = _typeParameter('T', bound: functionType);
    _checkLeastUpperBound(_typeParameterType(T), _functionType(), functionType);
  }

  void test_typeParam_function_noBound() {
    var T = _typeParameter('T');
    _checkLeastUpperBound(_typeParameterType(T), _functionType(), objectType);
  }

  void test_typeParam_interface_bounded() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', superType: typeA);
    var typeC = _interfaceType(C);

    var T = _typeParameter('T', bound: typeB);
    var typeT = _typeParameterType(T);

    _checkLeastUpperBound(typeT, typeC, typeA);
  }

  void test_typeParam_interface_noBound() {
    var T = _typeParameter('T');
    var A = _class(name: 'A');
    _checkLeastUpperBound(
      _typeParameterType(T),
      _interfaceType(A),
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
    List<DartType> types = [
      bottomType,
      _functionType(),
      _interfaceType(_class(name: 'A')),
      _typeParameterType(_typeParameter('T')),
    ];
    for (DartType type in types) {
      _checkLeastUpperBound(
        _functionType(returns: voidType),
        _functionType(returns: type),
        _functionType(returns: voidType),
      );
    }
  }
}

@reflectiveTest
class NonNullableSubtypingTest extends SubtypingTestBase {
  @override
  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting(
      additionalFeatures: [Feature.non_nullable],
    );
  }

  void test_dynamicType() {
    List<DartType> equivalents = <DartType>[
      voidType,
      _question(objectType),
      _star(objectType),
    ];
    List<DartType> subtypes = <DartType>[bottomType, nullType, objectType];
    _checkGroups(dynamicType, equivalents: equivalents, subtypes: subtypes);
  }

  @failingTest
  void test_futureOr_topTypes() {
    var objectStar =
        (objectType as TypeImpl).withNullability(NullabilitySuffix.star);
    var objectQuestion =
        (objectType as TypeImpl).withNullability(NullabilitySuffix.question);
    var futureOrObject = futureOrType(objectType);
    var futureOrObjectStar = futureOrType(objectStar);
    var futureOrObjectQuestion = futureOrType(objectQuestion);
    var futureOrStarObject =
        (futureOrObject as TypeImpl).withNullability(NullabilitySuffix.star);
    var futureOrQuestionObject = (futureOrObject as TypeImpl)
        .withNullability(NullabilitySuffix.question);
    var futureOrStarObjectStar = (futureOrObjectStar as TypeImpl)
        .withNullability(NullabilitySuffix.star);
    var futureOrQuestionObjectStar = (futureOrObjectStar as TypeImpl)
        .withNullability(NullabilitySuffix.question);
    var futureOrStarObjectQuestion = (futureOrObjectQuestion as TypeImpl)
        .withNullability(NullabilitySuffix.star);
    var futureOrQuestionObjectQuestion = (futureOrObjectQuestion as TypeImpl)
        .withNullability(NullabilitySuffix.question);

    //FutureOr<Object> <: FutureOr*<Object?>
    _checkGroups(futureOrObject, equivalents: [
      objectStar,
      futureOrObjectStar,
      futureOrStarObject,
      futureOrStarObjectStar,
      objectType
    ], subtypes: [], supertypes: [
      objectQuestion,
      futureOrQuestionObject,
      futureOrObjectQuestion,
      futureOrQuestionObject,
      futureOrQuestionObjectStar,
      futureOrStarObjectQuestion,
      futureOrQuestionObjectQuestion,
    ]);
  }

  void test_int_nullableTypes() {
    List<DartType> equivalents = <DartType>[
      intType,
      _star(intType),
    ];
    List<DartType> subtypes = <DartType>[
      bottomType,
    ];
    List<DartType> supertypes = <DartType>[
      _question(intType),
      objectType,
      _question(objectType),
    ];
    List<DartType> unrelated = <DartType>[
      doubleType,
      nullType,
      _star(nullType),
      _question(nullType),
      _question(bottomType),
    ];
    _checkGroups(intType,
        equivalents: equivalents,
        supertypes: supertypes,
        unrelated: unrelated,
        subtypes: subtypes);
  }

  void test_intQuestion_nullableTypes() {
    List<DartType> equivalents = <DartType>[
      _question(intType),
      _star(intType),
    ];
    List<DartType> subtypes = <DartType>[
      intType,
      nullType,
      _question(nullType),
      _star(nullType),
      bottomType,
      _question(bottomType),
      _star(bottomType),
    ];
    List<DartType> supertypes = <DartType>[
      _question(numType),
      _star(numType),
      _question(objectType),
      _star(objectType),
    ];
    List<DartType> unrelated = <DartType>[doubleType, numType, objectType];
    _checkGroups(_question(intType),
        equivalents: equivalents,
        supertypes: supertypes,
        unrelated: unrelated,
        subtypes: subtypes);
  }

  void test_intStar_nullableTypes() {
    List<DartType> equivalents = <DartType>[
      intType,
      _question(intType),
      _star(intType),
    ];
    List<DartType> subtypes = <DartType>[
      nullType,
      _star(nullType),
      _question(nullType),
      bottomType,
      _star(bottomType),
      _question(bottomType),
    ];
    List<DartType> supertypes = <DartType>[
      numType,
      _question(numType),
      _star(numType),
      objectType,
      _question(objectType),
    ];
    List<DartType> unrelated = <DartType>[doubleType];
    _checkGroups(_star(intType),
        equivalents: equivalents,
        supertypes: supertypes,
        unrelated: unrelated,
        subtypes: subtypes);
  }

  void test_nullType() {
    List<DartType> equivalents = <DartType>[
      nullType,
      _question(nullType),
      _star(nullType),
      _question(bottomType),
    ];
    List<DartType> supertypes = <DartType>[
      _question(intType),
      _star(intType),
      _question(objectType),
      _star(objectType),
      dynamicType,
      voidType,
    ];
    List<DartType> subtypes = <DartType>[bottomType];
    List<DartType> unrelated = <DartType>[
      doubleType,
      intType,
      numType,
      objectType,
    ];

    for (final formOfNull in equivalents) {
      _checkGroups(formOfNull,
          equivalents: equivalents,
          supertypes: supertypes,
          unrelated: unrelated,
          subtypes: subtypes);
    }
  }

  void test_objectType() {
    List<DartType> equivalents = <DartType>[
      _star(objectType),
    ];
    List<DartType> supertypes = <DartType>[
      _question(objectType),
      dynamicType,
      voidType,
    ];
    List<DartType> subtypes = <DartType>[bottomType];
    List<DartType> unrelated = <DartType>[
      _question(doubleType),
      _question(numType),
      _question(intType),
      nullType,
    ];
    _checkGroups(objectType,
        equivalents: equivalents,
        supertypes: supertypes,
        unrelated: unrelated,
        subtypes: subtypes);
  }

  DartType _question(DartType dartType) =>
      (dartType as TypeImpl).withNullability(NullabilitySuffix.question);

  DartType _star(DartType dartType) =>
      (dartType as TypeImpl).withNullability(NullabilitySuffix.star);
}

@reflectiveTest
class SubtypingTest extends SubtypingTestBase {
  void test_bottom_isBottom() {
    var A = _class(name: 'A');
    List<DartType> equivalents = <DartType>[bottomType];
    List<DartType> supertypes = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      functionType,
      _interfaceType(A),
    ];
    _checkGroups(bottomType, equivalents: equivalents, supertypes: supertypes);
  }

  void test_call_method() {
    var A = _class(name: 'A', methods: [
      _method('call', objectType, parameters: [
        _requiredParameter('_', intType),
      ]),
    ]);

    _checkIsNotSubtypeOf(
      _interfaceType(A),
      _functionType(required: [intType], returns: objectType),
    );
  }

  void test_classes() {
    var A = _class(name: 'A');
    var typeA = _interfaceType(A);

    var B = _class(name: 'B', superType: typeA);
    var typeB = _interfaceType(B);

    var C = _class(name: 'C', superType: typeA);
    var typeC = _interfaceType(C);

    var D = _class(
      name: 'D',
      superType: _interfaceType(B),
      interfaces: [typeC],
    );
    var typeD = _interfaceType(D);

    _checkLattice(typeA, typeB, typeC, typeD);
  }

  void test_double() {
    List<DartType> equivalents = <DartType>[doubleType];
    List<DartType> supertypes = <DartType>[numType];
    List<DartType> unrelated = <DartType>[intType];
    _checkGroups(doubleType,
        equivalents: equivalents, supertypes: supertypes, unrelated: unrelated);
  }

  void test_dynamic_isTop() {
    var A = _class(name: 'A');
    List<DartType> equivalents = <DartType>[dynamicType, objectType, voidType];
    List<DartType> subtypes = <DartType>[
      intType,
      doubleType,
      numType,
      stringType,
      functionType,
      _interfaceType(A),
      bottomType,
    ];
    _checkGroups(dynamicType, equivalents: equivalents, subtypes: subtypes);
  }

  void test_function_subtypes_itself_top_types() {
    var tops = [dynamicType, objectType, voidType];
    // Add FutureOr<T> for T := dynamic, object, void
    tops.addAll(tops.map((t) => futureOrType(t)).toList());
    // Add FutureOr<FutureOr<T>> for T := dynamic, object, void
    tops.addAll(tops.skip(3).map((t) => futureOrType(t)).toList());

    // Function should subtype all of those top types.
    _checkGroups(functionType, supertypes: [
      dynamicType,
      objectType,
      voidType,
    ]);

    // Create a non-identical but equal copy of Function, and verify subtyping
    var copyOfFunction = _interfaceType(functionType.element);
    _checkEquivalent(functionType, copyOfFunction);
  }

  void test_genericFunction_generic_monomorphic() {
    var S = _typeParameter('S');
    var T = _typeParameter('T', bound: _typeParameterType(S));
    var U = _typeParameter('U', bound: intType);
    var V = _typeParameter('V', bound: _typeParameterType(U));

    var A = _typeParameter('A');
    var B = _typeParameter('B', bound: _typeParameterType(A));
    var C = _typeParameter('C', bound: intType);
    var D = _typeParameter('D', bound: _typeParameterType(C));

    _checkIsStrictSubtypeOf(
      _functionType(
        typeFormals: [S, T],
        required: [_typeParameterType(S)],
        returns: _typeParameterType(T),
      ),
      _functionType(
        typeFormals: [A, B],
        required: [bottomType],
        returns: dynamicType,
      ),
    );

    _checkIsNotSubtypeOf(
      _functionType(
        typeFormals: [U, V],
        required: [_typeParameterType(U)],
        returns: _typeParameterType(V),
      ),
      _functionType(
        typeFormals: [C, D],
        required: [objectType],
        returns: objectType,
      ),
    );

    _checkIsNotSubtypeOf(
      _functionType(
        typeFormals: [U, V],
        required: [_typeParameterType(U)],
        returns: _typeParameterType(V),
      ),
      _functionType(
        typeFormals: [C, D],
        required: [intType],
        returns: intType,
      ),
    );
  }

  void test_genericFunction_genericDoesNotSubtypeNonGeneric() {
    var S = _typeParameter('S');
    var T = _typeParameter('T', bound: _typeParameterType(S));
    var U = _typeParameter('U', bound: intType);
    var V = _typeParameter('V', bound: _typeParameterType(U));

    _checkIsNotSubtypeOf(
      _functionType(
        typeFormals: [S, T],
        required: [_typeParameterType(S)],
        returns: _typeParameterType(T),
      ),
      _functionType(required: [dynamicType], returns: dynamicType),
    );

    _checkIsNotSubtypeOf(
      _functionType(
        typeFormals: [U, V],
        required: [_typeParameterType(U)],
        returns: _typeParameterType(V),
      ),
      _functionType(required: [objectType], returns: objectType),
    );

    _checkIsNotSubtypeOf(
      _functionType(
        typeFormals: [U, V],
        required: [_typeParameterType(U)],
        returns: _typeParameterType(V),
      ),
      _functionType(required: [intType], returns: intType),
    );
  }

  void test_genericFunction_simple() {
    var S = _typeParameter('S');
    var T = _typeParameter('T');

    _checkEquivalent(
      _functionType(typeFormals: [T]),
      _functionType(typeFormals: [S]),
    );

    _checkEquivalent(
      _functionType(
        typeFormals: [T],
        required: [_typeParameterType(T)],
        returns: _typeParameterType(T),
      ),
      _functionType(
        typeFormals: [S],
        required: [_typeParameterType(S)],
        returns: _typeParameterType(S),
      ),
    );
  }

  void test_genericFunction_simple_bounded() {
    var S = _typeParameter('S');
    var T = _typeParameter('T', bound: _typeParameterType(S));
    var U = _typeParameter('U');
    var V = _typeParameter('V', bound: _typeParameterType(U));

    _checkEquivalent(
      _functionType(typeFormals: [S, T]),
      _functionType(typeFormals: [U, V]),
    );

    _checkEquivalent(
      _functionType(
        typeFormals: [S, T],
        required: [_typeParameterType(S)],
        returns: _typeParameterType(T),
      ),
      _functionType(
        typeFormals: [U, V],
        required: [_typeParameterType(U)],
        returns: _typeParameterType(V),
      ),
    );

    {
      var top = _functionType(
        typeFormals: [S, T],
        required: [_typeParameterType(T)],
        returns: _typeParameterType(S),
      );
      var left = _functionType(
        typeFormals: [U, V],
        required: [_typeParameterType(U)],
        returns: _typeParameterType(U),
      );
      var right = _functionType(
        typeFormals: [U, V],
        required: [_typeParameterType(V)],
        returns: _typeParameterType(V),
      );
      var bottom = _functionType(
        typeFormals: [S, T],
        required: [_typeParameterType(S)],
        returns: _typeParameterType(T),
      );
      _checkLattice(top, left, right, bottom);
    }
  }

  void test_generics() {
    var LT = _typeParameter('T');
    var L = _class(name: 'L', typeParameters: [LT]);

    var MT = _typeParameter('T');
    var M = _class(
      name: 'M',
      typeParameters: [MT],
      interfaces: [
        _interfaceType(
          L,
          typeArguments: [_typeParameterType(MT)],
        )
      ],
    );

    var top = _interfaceType(L, typeArguments: [dynamicType]);
    var left = _interfaceType(M, typeArguments: [dynamicType]);
    var right = _interfaceType(L, typeArguments: [intType]);
    var bottom = _interfaceType(M, typeArguments: [intType]);

    _checkLattice(top, left, right, bottom);
  }

  void test_int() {
    List<DartType> equivalents = <DartType>[intType];
    List<DartType> supertypes = <DartType>[numType];
    List<DartType> unrelated = <DartType>[doubleType];
    _checkGroups(intType,
        equivalents: equivalents, supertypes: supertypes, unrelated: unrelated);
  }

  void test_named_optional() {
    var r = _functionType(required: [intType], returns: intType);
    var o = _functionType(optional: [intType], returns: intType);
    var n = _functionType(named: {'x': intType}, returns: intType);

    var rr = _functionType(
      required: [intType, intType],
      returns: intType,
    );
    var ro = _functionType(
      required: [intType],
      optional: [intType],
      returns: intType,
    );
    var rn = _functionType(
      required: [intType],
      named: {'x': intType},
      returns: intType,
    );
    var oo = _functionType(
      optional: [intType, intType],
      returns: intType,
    );
    var nn = _functionType(
      named: {'x': intType, 'y': intType},
      returns: intType,
    );
    var nnn = _functionType(
      named: {'x': intType, 'y': intType, 'z': intType},
      returns: intType,
    );

    _checkGroups(r,
        equivalents: [r],
        subtypes: [o, ro, rn, oo],
        unrelated: [n, rr, nn, nnn]);
    _checkGroups(o,
        equivalents: [o], subtypes: [oo], unrelated: [n, rr, ro, rn, nn, nnn]);
    _checkGroups(n,
        equivalents: [n],
        subtypes: [nn, nnn],
        unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(rr,
        equivalents: [rr],
        subtypes: [ro, oo],
        unrelated: [r, o, n, rn, nn, nnn]);
    _checkGroups(ro,
        equivalents: [ro], subtypes: [oo], unrelated: [o, n, rn, nn, nnn]);
    _checkGroups(rn,
        equivalents: [rn],
        subtypes: [],
        unrelated: [o, n, rr, ro, oo, nn, nnn]);
    _checkGroups(oo,
        equivalents: [oo], subtypes: [], unrelated: [n, rn, nn, nnn]);
    _checkGroups(nn,
        equivalents: [nn], subtypes: [nnn], unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(nnn,
        equivalents: [nnn], subtypes: [], unrelated: [r, o, rr, ro, rn, oo]);
  }

  void test_num() {
    List<DartType> equivalents = <DartType>[numType];
    List<DartType> supertypes = <DartType>[];
    List<DartType> unrelated = <DartType>[stringType];
    List<DartType> subtypes = <DartType>[intType, doubleType];
    _checkGroups(numType,
        equivalents: equivalents,
        supertypes: supertypes,
        unrelated: unrelated,
        subtypes: subtypes);
  }

  void test_simple_function() {
    var top = _functionType(required: [intType], returns: objectType);
    var left = _functionType(required: [intType], returns: intType);
    var right = _functionType(required: [objectType], returns: objectType);
    var bottom = _functionType(required: [objectType], returns: intType);

    _checkLattice(top, left, right, bottom);
  }

  /// Regression test for https://github.com/dart-lang/sdk/issues/25069
  void test_simple_function_void() {
    var functionType = _functionType(required: [intType], returns: objectType);
    _checkIsNotSubtypeOf(voidType, functionType);
  }

  void test_void_functions() {
    var top = _functionType(required: [intType], returns: voidType);
    var bottom = _functionType(required: [objectType], returns: intType);

    _checkIsStrictSubtypeOf(bottom, top);
  }

  void test_void_isTop() {
    var A = _class(name: 'A');
    List<DartType> equivalents = <DartType>[dynamicType, objectType, voidType];
    List<DartType> subtypes = <DartType>[
      intType,
      doubleType,
      numType,
      stringType,
      functionType,
      _interfaceType(A),
      bottomType
    ];
    _checkGroups(voidType, equivalents: equivalents, subtypes: subtypes);
  }
}

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
    expect(typeSystem.isSubtypeOf(type1, type2), false,
        reason: '$type1 was not supposed to be a subtype of $type2');
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
}

@reflectiveTest
class TypeSystemTest extends AbstractTypeSystemTest {
  InterfaceTypeImpl get functionClassTypeNone {
    return _interfaceType(
      typeProvider.functionType.element,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get functionClassTypeQuestion {
    return _interfaceType(
      typeProvider.functionType.element,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl get functionClassTypeStar {
    return _interfaceType(
      typeProvider.functionType.element,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  DartType get noneType => (typeProvider.stringType as TypeImpl)
      .withNullability(NullabilitySuffix.none);

  FunctionTypeImpl get nothingToVoidFunctionTypeNone {
    return _functionType(
      returns: voidType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  FunctionTypeImpl get nothingToVoidFunctionTypeQuestion {
    return _functionType(
      returns: voidType,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  FunctionTypeImpl get nothingToVoidFunctionTypeStar {
    return _functionType(
      returns: voidType,
      nullabilitySuffix: NullabilitySuffix.star,
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
    return _interfaceType(
      typeProvider.stringType.element,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get stringClassTypeQuestion {
    return _interfaceType(
      typeProvider.stringType.element,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl get stringClassTypeStar {
    return _interfaceType(
      typeProvider.stringType.element,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceTypeImpl futureOrTypeNone({@required DartType argument}) {
    var element = typeProvider.futureOrElement;
    return _interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrTypeQuestion({@required DartType argument}) {
    var element = typeProvider.futureOrElement;
    return _interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureOrTypeStar({@required DartType argument}) {
    var element = typeProvider.futureOrElement;
    return _interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceTypeImpl listClassTypeNone(DartType argument) {
    var element = typeProvider.listElement;
    return _interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl listClassTypeQuestion(DartType argument) {
    var element = typeProvider.listElement;
    return _interfaceType(
      element,
      typeArguments: <DartType>[argument],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl listClassTypeStar(DartType argument) {
    var element = typeProvider.listElement;
    return _interfaceType(
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
    expect(typeSystem.isNonNullable(neverType), true);
  }

  test_isNonNullable_null() {
    expect(typeSystem.isNonNullable(nullType), false);
  }

  test_isNonNullable_typeParameter_noneBound_none() {
    expect(
      typeSystem.isNonNullable(
        typeParameterTypeNone(bound: noneType),
      ),
      true,
    );
  }

  test_isNonNullable_typeParameter_noneBound_question() {
    expect(
      typeSystem.isNonNullable(
        typeParameterTypeQuestion(bound: noneType),
      ),
      false,
    );
  }

  test_isNonNullable_typeParameter_questionBound_none() {
    expect(
      typeSystem.isNonNullable(
        typeParameterTypeNone(bound: questionType),
      ),
      false,
    );
  }

  test_isNonNullable_typeParameter_questionBound_question() {
    expect(
      typeSystem.isNonNullable(
        typeParameterTypeQuestion(bound: questionType),
      ),
      false,
    );
  }

  test_isNonNullable_typeParameter_starBound_star() {
    expect(
      typeSystem.isNonNullable(
        typeParameterTypeStar(bound: starType),
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
    expect(typeSystem.isNullable(neverType), false);
  }

  test_isNullable_never() {
    expect(typeSystem.isNullable(neverType), false);
  }

  test_isNullable_null() {
    expect(typeSystem.isNullable(nullType), true);
  }

  test_isNullable_typeParameter_noneBound_none() {
    expect(
      typeSystem.isNullable(
        typeParameterTypeNone(bound: noneType),
      ),
      false,
    );
  }

  test_isNullable_typeParameter_noneBound_question() {
    expect(
      typeSystem.isNullable(
        typeParameterTypeQuestion(bound: noneType),
      ),
      true,
    );
  }

  test_isNullable_typeParameter_questionBound_none() {
    expect(
      typeSystem.isNullable(
        typeParameterTypeNone(bound: questionType),
      ),
      false,
    );
  }

  test_isNullable_typeParameter_questionBound_question() {
    expect(
      typeSystem.isNullable(
        typeParameterTypeQuestion(bound: questionType),
      ),
      true,
    );
  }

  test_isNullable_typeParameter_starBound_star() {
    expect(
      typeSystem.isNullable(
        typeParameterTypeStar(bound: starType),
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
    expect(typeSystem.isPotentiallyNonNullable(neverType), true);
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
    expect(typeSystem.isPotentiallyNullable(neverType), false);
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
    expect(typeSystem.promoteToNonNull(neverType), neverType);
  }

  test_promoteToNonNull_null() {
    expect(typeSystem.promoteToNonNull(nullType), neverType);
  }

  test_promoteToNonNull_typeParameter_noneBound_none() {
    expect(
      typeSystem.promoteToNonNull(
        typeParameterTypeNone(bound: noneType),
      ),
      typeParameterTypeNone(bound: noneType),
    );
  }

  test_promoteToNonNull_typeParameter_nullBound_none() {
    expect(
      typeSystem.promoteToNonNull(
        typeParameterTypeNone(bound: null),
      ),
      typeParameterTypeNone(bound: objectClassTypeNone),
    );
  }

  test_promoteToNonNull_typeParameter_questionBound_none() {
    expect(
      typeSystem.promoteToNonNull(
        typeParameterTypeNone(bound: stringClassTypeQuestion),
      ),
      typeParameterTypeNone(bound: stringClassTypeNone),
    );
  }

  test_promoteToNonNull_typeParameter_questionBound_question() {
    expect(
      typeSystem.promoteToNonNull(
        typeParameterTypeQuestion(bound: stringClassTypeQuestion),
      ),
      typeParameterTypeNone(bound: stringClassTypeNone),
    );
  }

  test_promoteToNonNull_typeParameter_questionBound_star() {
    expect(
      typeSystem.promoteToNonNull(
        typeParameterTypeStar(bound: stringClassTypeQuestion),
      ),
      typeParameterTypeNone(bound: stringClassTypeNone),
    );
  }

  test_promoteToNonNull_typeParameter_starBound_none() {
    expect(
      typeSystem.promoteToNonNull(
        typeParameterTypeNone(bound: stringClassTypeStar),
      ),
      typeParameterTypeNone(bound: stringClassTypeNone),
    );
  }

  test_promoteToNonNull_void() {
    expect(
      typeSystem.promoteToNonNull(voidType),
      voidType,
    );
  }

  DartType typeParameterTypeNone({@required DartType bound}) {
    var element = _typeParameter('T', bound: bound);
    return _typeParameterType(
      element,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  DartType typeParameterTypeQuestion({@required DartType bound}) {
    var element = _typeParameter('T', bound: bound);
    return _typeParameterType(
      element,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  DartType typeParameterTypeStar({@required DartType bound}) {
    var element = _typeParameter('T', bound: bound);
    return _typeParameterType(
      element,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }
}
