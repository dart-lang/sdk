// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests related to the [TypeSystem] class.

import 'package:analyzer/analyzer.dart'
    show ErrorReporter, ParameterKind, StrongModeCode;
import 'package:analyzer/dart/ast/standard_ast_factory.dart' show astFactory;
import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart' show KeywordToken;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart'
    show NonExistingSource, UriKind;
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:path/path.dart' show toUri;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_context_factory.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstraintMatchingTest);
    defineReflectiveTests(StrongAssignabilityTest);
    defineReflectiveTests(StrongSubtypingTest);
    defineReflectiveTests(StrongGenericFunctionInferenceTest);
    defineReflectiveTests(StrongLeastUpperBoundTest);
    defineReflectiveTests(StrongGreatestLowerBoundTest);
  });
}

/**
 * Base class for testing LUB and GLB in spec and strong mode.
 */
abstract class BoundTestBase {
  TypeProvider typeProvider;
  TypeSystem typeSystem;
  FunctionType simpleFunctionType;

  DartType get bottomType => typeProvider.bottomType;
  InterfaceType get doubleType => typeProvider.doubleType;
  DartType get dynamicType => typeProvider.dynamicType;
  InterfaceType get functionType => typeProvider.functionType;
  InterfaceType get futureOrType => typeProvider.futureOrType;
  InterfaceType get intType => typeProvider.intType;
  InterfaceType get iterableType => typeProvider.iterableType;
  InterfaceType get listType => typeProvider.listType;
  InterfaceType get numType => typeProvider.numType;
  InterfaceType get objectType => typeProvider.objectType;
  InterfaceType get stringType => typeProvider.stringType;
  StrongTypeSystemImpl get strongTypeSystem =>
      typeSystem as StrongTypeSystemImpl;

  DartType get voidType => VoidTypeImpl.instance;

  void setUp() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    typeProvider = context.typeProvider;
    var simpleFunctionElement =
        ElementFactory.genericTypeAliasElement('A', returnType: voidType);
    simpleFunctionType = simpleFunctionElement.type;
  }

  void _checkGreatestLowerBound(
      DartType type1, DartType type2, DartType expectedResult) {
    DartType glb = strongTypeSystem.getGreatestLowerBound(type1, type2);
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
    glb = strongTypeSystem.getGreatestLowerBound(type2, type1);
    if (glb is FunctionTypeImpl) {
      expect(typeSystem.isSubtypeOf(glb, expectedResult), true);
      expect(typeSystem.isSubtypeOf(expectedResult, glb), true);
    } else {
      expect(glb, expectedResult);
    }
  }

  void _checkLeastUpperBound(
      DartType type1, DartType type2, DartType expectedResult) {
    DartType lub = typeSystem.getLeastUpperBound(type1, type2);
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

  /**
   * Creates a function type with the given parameter and return types.
   *
   * The return type defaults to `void` if omitted.
   */
  FunctionType _functionType(List<DartType> required,
      {List<DartType> optional,
      Map<String, DartType> named,
      DartType returns}) {
    if (returns == null) {
      returns = voidType;
    }

    return ElementFactory.functionElement8(required, returns,
            optional: optional, named: named)
        .type;
  }
}

@reflectiveTest
class ConstraintMatchingTest {
  TypeProvider typeProvider;
  TypeSystem typeSystem;
  TypeParameterType T;

  DartType get dynamicType => DynamicTypeImpl.instance;

  InterfaceType get functionType => typeProvider.functionType;

  InterfaceType get intType => typeProvider.intType;

  InterfaceType get nullType => typeProvider.nullType;

  InterfaceType get objectType => typeProvider.objectType;

  InterfaceType get stringType => typeProvider.stringType;

  DartType get voidType => VoidTypeImpl.instance;

  DartType fn(DartType paramType, DartType returnType) =>
      new FunctionElementImpl.synthetic([
        new ParameterElementImpl.synthetic(
            'value', paramType, ParameterKind.REQUIRED)
      ], returnType)
          .type;

  DartType future(DartType T) => typeProvider.futureType.instantiate([T]);

  DartType futureOr(DartType T) => typeProvider.futureOrType.instantiate([T]);

  DartType iterable(DartType T) => typeProvider.iterableType.instantiate([T]);

  DartType list(DartType T) => typeProvider.listType.instantiate([T]);

  void setUp() {
    typeProvider = AnalysisContextFactory.contextWithCore().typeProvider;
    typeSystem = new StrongTypeSystemImpl(typeProvider);
    T = _newTypeParameter('T');
  }

  void test_function_coreFunction() {
    _checkOrdinarySubtypeMatch(fn(intType, stringType), functionType, [T],
        covariant: true);
  }

  void test_function_parameter_types() {
    _checkIsSubtypeMatchOf(
        fn(T, intType), fn(stringType, intType), [T], ['String <: T'],
        covariant: true);
  }

  void test_function_return_types() {
    _checkIsSubtypeMatchOf(
        fn(intType, T), fn(intType, stringType), [T], ['T <: String'],
        covariant: true);
  }

  void test_futureOr_futureOr() {
    _checkIsSubtypeMatchOf(
        futureOr(T), futureOr(stringType), [T], ['T <: String'],
        covariant: true);
  }

  void test_futureOr_x_fail_future_branch() {
    // FutureOr<List<T>> <: List<String> can't be satisfied because
    // Future<List<T>> <: List<String> can't be satisfied
    _checkIsNotSubtypeMatchOf(futureOr(list(T)), list(stringType), [T],
        covariant: true);
  }

  void test_futureOr_x_fail_nonFuture_branch() {
    // FutureOr<List<T>> <: Future<List<String>> can't be satisfied because
    // List<T> <: Future<List<String>> can't be satisfied
    _checkIsNotSubtypeMatchOf(futureOr(list(T)), future(list(stringType)), [T],
        covariant: true);
  }

  void test_futureOr_x_success() {
    // FutureOr<T> <: Future<T> can be satisfied by T=Null.  At this point in
    // the type inference algorithm all we figure out is that T must be a
    // subtype of both String and Future<String>.
    _checkIsSubtypeMatchOf(futureOr(T), future(stringType), [T],
        ['T <: String', 'T <: Future<String>'],
        covariant: true);
  }

  void test_lhs_null() {
    // Null <: T is trivially satisfied by the constraint Null <: T.
    _checkIsSubtypeMatchOf(nullType, T, [T], ['Null <: T'], covariant: false);
    // For any other type X, Null <: X is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(nullType, list(T), [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, stringType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, voidType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, dynamicType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, objectType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, nullType, [T], covariant: false);
    _checkOrdinarySubtypeMatch(nullType, fn(intType, stringType), [T],
        covariant: false);
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
    var S = _newTypeParameter('S');
    _checkIsSubtypeMatchOf(list(S), list(T), [T], ['S <: T'], covariant: false);
  }

  void test_param_on_lhs_contravariant_via_bound() {
    // When doing a contravariant match, the type parameters we're trying to
    // find types for are on the right hand side.  Is a type parameter also
    // appears on the left hand side, we may have to constrain the RHS type
    // parameter using the bounds of the LHS type parameter.
    //
    // In other words, S <: List<T> is satisfied provided that
    // bound(S) <: List<T>.
    var S = _newTypeParameter('S', list(stringType));
    _checkIsSubtypeMatchOf(S, list(T), [T], ['String <: T'], covariant: false);
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
    var S = _newTypeParameter('S');
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
    var S = _newTypeParameter('S');
    _checkIsNotSubtypeMatchOf(list(T), S, [T], covariant: true);
  }

  void test_related_interface_types_failure() {
    _checkIsNotSubtypeMatchOf(iterable(T), list(stringType), [T],
        covariant: true);
  }

  void test_related_interface_types_success() {
    _checkIsSubtypeMatchOf(list(T), iterable(stringType), [T], ['T <: String'],
        covariant: true);
  }

  void test_rhs_dynamic() {
    // T <: dynamic is trivially satisfied by the constraint T <: dynamic.
    _checkIsSubtypeMatchOf(T, dynamicType, [T], ['T <: dynamic'],
        covariant: true);
    // For any other type X, X <: dynamic is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(list(T), dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(stringType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullType, dynamicType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(fn(intType, stringType), dynamicType, [T],
        covariant: true);
  }

  void test_rhs_object() {
    // T <: Object is trivially satisfied by the constraint T <: Object.
    _checkIsSubtypeMatchOf(T, objectType, [T], ['T <: Object'],
        covariant: true);
    // For any other type X, X <: Object is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(list(T), objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(stringType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullType, objectType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(fn(intType, stringType), objectType, [T],
        covariant: true);
  }

  void test_rhs_void() {
    // T <: void is trivially satisfied by the constraint T <: void.
    _checkIsSubtypeMatchOf(T, voidType, [T], ['T <: void'], covariant: true);
    // For any other type X, X <: void is satisfied without the need for any
    // constraints.
    _checkOrdinarySubtypeMatch(list(T), voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(stringType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(voidType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(dynamicType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(objectType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(nullType, voidType, [T], covariant: true);
    _checkOrdinarySubtypeMatch(fn(intType, stringType), voidType, [T],
        covariant: true);
  }

  void test_same_interface_types() {
    _checkIsSubtypeMatchOf(list(T), list(stringType), [T], ['T <: String'],
        covariant: true);
  }

  void test_x_futureOr_fail_both_branches() {
    // List<T> <: FutureOr<String> can't be satisfied because neither
    // List<T> <: Future<String> nor List<T> <: int can be satisfied
    _checkIsNotSubtypeMatchOf(list(T), futureOr(stringType), [T],
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
        future(stringType), futureOr(T), [T], ['String <: T'],
        covariant: false);
  }

  void test_x_futureOr_pass_both_branches_constraints_from_future_branch() {
    // Future<T> <: FutureOr<Object> can be satisfied because both
    // Future<T> <: Future<Object> and Future<T> <: Object can be satisfied.
    // Trying to match Future<T> <: Future<Object> generates the constraint
    // T <: Object, whereas trying to match Future<T> <: Object generates no
    // constraints, so we keep the constraint T <: Object.
    _checkIsSubtypeMatchOf(
        future(T), futureOr(objectType), [T], ['T <: Object'],
        covariant: true);
  }

  void test_x_futureOr_pass_both_branches_constraints_from_nonFuture_branch() {
    // Null <: FutureOr<T> can be satisfied because both
    // Null <: Future<T> and Null <: T can be satisfied.
    // Trying to match Null <: FutureOr<T> generates no constraints, whereas
    // trying to match Null <: T generates the constraint Null <: T,
    // so we keep the constraint Null <: T.
    _checkIsSubtypeMatchOf(nullType, futureOr(T), [T], ['Null <: T'],
        covariant: false);
  }

  void test_x_futureOr_pass_both_branches_no_constraints() {
    // Future<String> <: FutureOr<Object> is satisfied because both
    // Future<String> <: Future<Object> and Future<String> <: Object.
    // No constraints are recorded.
    _checkIsSubtypeMatchOf(future(stringType), futureOr(objectType), [T], [],
        covariant: true);
  }

  void test_x_futureOr_pass_future_branch() {
    // Future<T> <: FutureOr<String> can be satisfied because
    // Future<T> <: Future<String> can be satisfied
    _checkIsSubtypeMatchOf(
        future(T), futureOr(stringType), [T], ['T <: String'],
        covariant: true);
  }

  void test_x_futureOr_pass_nonFuture_branch() {
    // List<T> <: FutureOr<List<String>> can be satisfied because
    // List<T> <: List<String> can be satisfied
    _checkIsSubtypeMatchOf(
        list(T), futureOr(list(stringType)), [T], ['T <: String'],
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

  TypeParameterType _newTypeParameter(String name, [DartType bound]) {
    var element = new TypeParameterElementImpl(name, 0);
    if (bound != null) {
      element.bound = bound;
    }
    return new TypeParameterTypeImpl(element);
  }
}

/**
 * Base class for testing LUB in spec and strong mode.
 * Defines helper functions and tests. Tests here are ones whose behavior is
 * the same in strong and spec mode.
 */
abstract class LeastUpperBoundTestBase extends BoundTestBase {
  void test_bottom_function() {
    _checkLeastUpperBound(bottomType, simpleFunctionType, simpleFunctionType);
  }

  void test_bottom_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(bottomType, interfaceType, interfaceType);
  }

  void test_bottom_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(bottomType, typeParam, typeParam);
  }

  void test_directInterfaceCase() {
    // class A
    // class B implements A
    // class C implements B
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType>[typeA];
    classC.interfaces = <InterfaceType>[typeB];
    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_directSubclassCase() {
    // class A
    // class B extends A
    // class C extends B
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_dynamic_bottom() {
    _checkLeastUpperBound(dynamicType, bottomType, dynamicType);
  }

  void test_dynamic_function() {
    _checkLeastUpperBound(dynamicType, simpleFunctionType, dynamicType);
  }

  void test_dynamic_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(dynamicType, interfaceType, dynamicType);
  }

  void test_dynamic_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(dynamicType, typeParam, dynamicType);
  }

  void test_dynamic_void() {
    // Note: _checkLeastUpperBound tests `LUB(x, y)` as well as `LUB(y, x)`
    _checkLeastUpperBound(dynamicType, voidType, voidType);
  }

  void test_functionsDifferentRequiredArity() {
    FunctionType type1 = _functionType([intType, intType]);
    FunctionType type2 = _functionType([intType, intType, intType]);
    _checkLeastUpperBound(type1, type2, functionType);
  }

  void test_functionsIgnoreExtraNamedParams() {
    FunctionType type1 = _functionType([], named: {'a': intType, 'b': intType});
    FunctionType type2 = _functionType([], named: {'a': intType, 'c': intType});
    FunctionType expected = _functionType([], named: {'a': intType});
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsIgnoreExtraPositionalParams() {
    FunctionType type1 =
        _functionType([], optional: [intType, intType, stringType]);
    FunctionType type2 = _functionType([], optional: [intType]);
    FunctionType expected = _functionType([], optional: [intType]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsLubReturnType() {
    FunctionType type1 = _functionType([], returns: intType);
    FunctionType type2 = _functionType([], returns: doubleType);
    FunctionType expected = _functionType([], returns: numType);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsSameType() {
    FunctionType type1 = _functionType([stringType, intType, numType],
        optional: [doubleType], named: {'n': numType}, returns: intType);
    FunctionType type2 = _functionType([stringType, intType, numType],
        optional: [doubleType], named: {'n': numType}, returns: intType);
    FunctionType expected = _functionType([stringType, intType, numType],
        optional: [doubleType], named: {'n': numType}, returns: intType);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_interface_function() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(interfaceType, simpleFunctionType, objectType);
  }

  void test_mixinCase() {
    // class A
    // class B extends A
    // class C extends A
    // class D extends B with M, N, O, P
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElement classC = ElementFactory.classElement("C", classA.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    classD.mixins = <InterfaceType>[
      ElementFactory.classElement2("M").type,
      ElementFactory.classElement2("N").type,
      ElementFactory.classElement2("O").type,
      ElementFactory.classElement2("P").type
    ];
    _checkLeastUpperBound(typeD, typeC, typeA);
  }

  void test_nestedFunctionsLubInnerParamTypes() {
    FunctionType type1 = _functionType([
      _functionType([stringType, intType, intType])
    ]);
    FunctionType type2 = _functionType([
      _functionType([intType, doubleType, numType])
    ]);
    FunctionType expected = _functionType([
      _functionType([objectType, numType, numType])
    ]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_object() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    DartType typeObject = typeA.element.supertype;
    // assert that object does not have a super type
    expect((typeObject.element as ClassElement).supertype, isNull);
    // assert that both A and B have the same super type of Object
    expect(typeB.element.supertype, typeObject);
    // finally, assert that the only least upper bound of A and B is Object
    _checkLeastUpperBound(typeA, typeB, typeObject);
  }

  void test_self() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    DartType interfaceType = ElementFactory.classElement2('A', []).type;

    List<DartType> types = [
      dynamicType,
      voidType,
      bottomType,
      typeParam,
      interfaceType,
      simpleFunctionType
    ];

    for (DartType type in types) {
      _checkLeastUpperBound(type, type, type);
    }
  }

  void test_sharedSuperclass1() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperclass2() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classC.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeD = classD.type;
    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperclass3() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type);
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperclass4() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classA2 = ElementFactory.classElement2("A2");
    ClassElement classA3 = ElementFactory.classElement2("A3");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeA2 = classA2.type;
    InterfaceType typeA3 = classA3.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType>[typeA2];
    classC.interfaces = <InterfaceType>[typeA3];
    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface1() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType>[typeA];
    classC.interfaces = <InterfaceType>[typeA];
    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface2() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    ClassElementImpl classD = ElementFactory.classElement2("D");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    classB.interfaces = <InterfaceType>[typeA];
    classC.interfaces = <InterfaceType>[typeA];
    classD.interfaces = <InterfaceType>[typeC];
    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperinterface3() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    ClassElementImpl classD = ElementFactory.classElement2("D");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    classB.interfaces = <InterfaceType>[typeA];
    classC.interfaces = <InterfaceType>[typeB];
    classD.interfaces = <InterfaceType>[typeB];
    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperinterface4() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classA2 = ElementFactory.classElement2("A2");
    ClassElement classA3 = ElementFactory.classElement2("A3");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeA = classA.type;
    InterfaceType typeA2 = classA2.type;
    InterfaceType typeA3 = classA3.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType>[typeA, typeA2];
    classC.interfaces = <InterfaceType>[typeA, typeA3];
    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_twoComparables() {
    _checkLeastUpperBound(stringType, numType, objectType);
  }

  void test_typeParam_function_bounded() {
    TypeParameterElementImpl typeParamElement =
        ElementFactory.typeParameterElement('T');
    typeParamElement.bound = functionType;
    DartType typeParam = typeParamElement.type;
    _checkLeastUpperBound(typeParam, simpleFunctionType, functionType);
  }

  void test_typeParam_function_noBound() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(typeParam, simpleFunctionType, objectType);
  }

  void test_typeParam_interface_bounded() {
    DartType typeA = ElementFactory.classElement2('A', []).type;
    DartType typeB = ElementFactory.classElement('B', typeA).type;
    DartType typeC = ElementFactory.classElement('C', typeA).type;
    TypeParameterElementImpl typeParamElement =
        ElementFactory.typeParameterElement('T');
    typeParamElement.bound = typeB;
    DartType typeParam = typeParamElement.type;
    _checkLeastUpperBound(typeParam, typeC, typeA);
  }

  void test_typeParam_interface_noBound() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(typeParam, interfaceType, objectType);
  }

  void test_typeParameters_same() {
    // List<int>
    // List<int>
    InterfaceType listOfIntType = listType.instantiate(<DartType>[intType]);
    _checkLeastUpperBound(listOfIntType, listOfIntType, listOfIntType);
  }

  void test_void() {
    List<DartType> types = [
      bottomType,
      simpleFunctionType,
      ElementFactory.classElement2('A', []).type,
      ElementFactory.typeParameterElement('T').type
    ];
    for (DartType type in types) {
      _checkLeastUpperBound(
          _functionType([], returns: voidType),
          _functionType([], returns: type),
          _functionType([], returns: voidType));
    }
  }
}

@reflectiveTest
class StrongAssignabilityTest {
  TypeProvider typeProvider;
  TypeSystem typeSystem;

  DartType get bottomType => typeProvider.bottomType;
  InterfaceType get doubleType => typeProvider.doubleType;
  DartType get dynamicType => typeProvider.dynamicType;
  InterfaceType get functionType => typeProvider.functionType;
  InterfaceType get intType => typeProvider.intType;
  InterfaceType get listType => typeProvider.listType;
  InterfaceType get numType => typeProvider.numType;
  InterfaceType get objectType => typeProvider.objectType;
  InterfaceType get stringType => typeProvider.stringType;
  DartType get voidType => VoidTypeImpl.instance;

  void setUp() {
    typeProvider = new TestTypeProvider();
    typeSystem = new StrongTypeSystemImpl(typeProvider);
  }

  void test_isAssignableTo_bottom_isBottom() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      interfaceType,
      bottomType
    ];

    _checkGroups(bottomType, interassignable: interassignable);
  }

  void test_isAssignableTo_call_method() {
    ClassElementImpl classBottom = ElementFactory.classElement2("B");
    MethodElement methodBottom =
        ElementFactory.methodElement("call", objectType, <DartType>[intType]);
    classBottom.methods = <MethodElement>[methodBottom];

    DartType top =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    InterfaceType bottom = classBottom.type;

    _checkIsStrictAssignableTo(bottom, top);
  }

  void test_isAssignableTo_classes() {
    ClassElement classTop = ElementFactory.classElement2("A");
    ClassElement classLeft = ElementFactory.classElement("B", classTop.type);
    ClassElement classRight = ElementFactory.classElement("C", classTop.type);
    ClassElement classBottom = ElementFactory.classElement("D", classLeft.type)
      ..interfaces = <InterfaceType>[classRight.type];
    InterfaceType top = classTop.type;
    InterfaceType left = classLeft.type;
    InterfaceType right = classRight.type;
    InterfaceType bottom = classBottom.type;

    _checkLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_double() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      doubleType,
      numType,
      bottomType
    ];
    List<DartType> unrelated = <DartType>[
      intType,
      stringType,
      interfaceType,
    ];

    _checkGroups(doubleType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_dynamic_isTop() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      interfaceType,
      bottomType
    ];
    _checkGroups(dynamicType, interassignable: interassignable);
  }

  void test_isAssignableTo_generics() {
    ClassElementImpl LClass = ElementFactory.classElement2('L', ["T"]);
    InterfaceType LType = LClass.type;
    ClassElementImpl MClass = ElementFactory.classElement2('M', ["T"]);
    DartType typeParam = MClass.typeParameters[0].type;
    InterfaceType superType = LType.instantiate(<DartType>[typeParam]);
    MClass.interfaces = <InterfaceType>[superType];
    InterfaceType MType = MClass.type;

    InterfaceType top = LType.instantiate(<DartType>[dynamicType]);
    InterfaceType left = MType.instantiate(<DartType>[dynamicType]);
    InterfaceType right = LType.instantiate(<DartType>[intType]);
    InterfaceType bottom = MType.instantiate(<DartType>[intType]);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_int() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      numType,
      bottomType
    ];
    List<DartType> unrelated = <DartType>[
      doubleType,
      stringType,
      interfaceType,
    ];

    _checkGroups(intType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_named_optional() {
    DartType r =
        TypeBuilder.function(required: <DartType>[intType], result: intType);
    DartType o = TypeBuilder.function(
        required: <DartType>[], optional: <DartType>[intType], result: intType);
    DartType n = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType},
        result: intType);
    DartType rr = TypeBuilder.function(
        required: <DartType>[intType, intType], result: intType);
    DartType ro = TypeBuilder.function(
        required: <DartType>[intType],
        optional: <DartType>[intType],
        result: intType);
    DartType rn = TypeBuilder.function(
        required: <DartType>[intType],
        named: <String, DartType>{'x': intType},
        result: intType);
    DartType oo = TypeBuilder.function(
        required: <DartType>[],
        optional: <DartType>[intType, intType],
        result: intType);
    DartType nn = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType, 'y': intType},
        result: intType);
    DartType nnn = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType, 'y': intType, 'z': intType},
        result: intType);

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
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      numType,
      intType,
      doubleType,
      bottomType
    ];
    List<DartType> unrelated = <DartType>[
      stringType,
      interfaceType,
    ];

    _checkGroups(numType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_simple_function() {
    FunctionType top =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    FunctionType left =
        TypeBuilder.function(required: <DartType>[intType], result: intType);
    FunctionType right = TypeBuilder.function(
        required: <DartType>[objectType], result: objectType);
    FunctionType bottom =
        TypeBuilder.function(required: <DartType>[objectType], result: intType);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_void_functions() {
    FunctionType top =
        TypeBuilder.function(required: <DartType>[intType], result: voidType);
    FunctionType bottom =
        TypeBuilder.function(required: <DartType>[objectType], result: intType);

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

@reflectiveTest
class StrongGenericFunctionInferenceTest {
  TypeProvider typeProvider;
  StrongTypeSystemImpl typeSystem;

  DartType get bottomType => typeProvider.bottomType;
  InterfaceType get doubleType => typeProvider.doubleType;
  DartType get dynamicType => typeProvider.dynamicType;
  InterfaceType get functionType => typeProvider.functionType;
  InterfaceType get intType => typeProvider.intType;
  InterfaceType get iterableType => typeProvider.iterableType;
  InterfaceType get listType => typeProvider.listType;
  DartType get nullType => typeProvider.nullType;
  InterfaceType get numType => typeProvider.numType;
  InterfaceType get objectType => typeProvider.objectType;
  InterfaceType get stringType => typeProvider.stringType;
  DartType get voidType => VoidTypeImpl.instance;

  void setUp() {
    typeProvider = new TestTypeProvider();
    typeSystem = new StrongTypeSystemImpl(typeProvider);
  }

  void test_boundedByAnotherTypeParameter() {
    // <TFrom, TTo extends Iterable<TFrom>>(TFrom) -> TTo
    var tFrom = TypeBuilder.variable('TFrom');
    var tTo =
        TypeBuilder.variable('TTo', bound: iterableType.instantiate([tFrom]));
    var cast = TypeBuilder.function(
        types: [tFrom, tTo], required: [tFrom], result: tTo);
    expect(_inferCall(cast, [stringType]), [
      stringType,
      iterableType.instantiate([stringType])
    ]);
  }

  void test_boundedByOuterClass() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var a = ElementFactory.classElement('A', objectType);

    // class B extends A {}
    var b = ElementFactory.classElement('B', a.type);

    // class C<T extends A> {
    var c = ElementFactory.classElement('C', objectType, ['T']);
    (c.typeParameters[0] as TypeParameterElementImpl).bound = a.type;
    //   S m<S extends T>(S);
    var s = TypeBuilder.variable('S');
    (s.element as TypeParameterElementImpl).bound = c.typeParameters[0].type;
    var m = ElementFactory.methodElement('m', s, [s]);
    m.typeParameters = [s.element];
    c.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = c.type.instantiate([objectType]);
    // C<A> cOfA;
    var cOfA = c.type.instantiate([a.type]);
    // C<B> cOfB;
    var cOfB = c.type.instantiate([b.type]);
    // B b;
    // cOfB.m(b); // infer <B>
    expect(_inferCall(cOfB.getMethod('m').type, [b.type]), [b.type, b.type]);
    // cOfA.m(b); // infer <B>
    expect(_inferCall(cOfA.getMethod('m').type, [b.type]), [a.type, b.type]);
    // cOfObject.m(b); // infer <B>
    expect(_inferCall(cOfObject.getMethod('m').type, [b.type]),
        [objectType, b.type]);
  }

  void test_boundedByOuterClassSubstituted() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var a = ElementFactory.classElement('A', objectType);

    // class B extends A {}
    var b = ElementFactory.classElement('B', a.type);

    // class C<T extends A> {
    var c = ElementFactory.classElement('C', objectType, ['T']);
    (c.typeParameters[0] as TypeParameterElementImpl).bound = a.type;
    //   S m<S extends Iterable<T>>(S);
    var s = TypeBuilder.variable('S');
    var iterableOfT = iterableType.instantiate([c.typeParameters[0].type]);
    (s.element as TypeParameterElementImpl).bound = iterableOfT;
    var m = ElementFactory.methodElement('m', s, [s]);
    m.typeParameters = [s.element];
    c.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = c.type.instantiate([objectType]);
    // C<A> cOfA;
    var cOfA = c.type.instantiate([a.type]);
    // C<B> cOfB;
    var cOfB = c.type.instantiate([b.type]);
    // List<B> b;
    var listOfB = listType.instantiate([b.type]);
    // cOfB.m(b); // infer <B>
    expect(_inferCall(cOfB.getMethod('m').type, [listOfB]), [b.type, listOfB]);
    // cOfA.m(b); // infer <B>
    expect(_inferCall(cOfA.getMethod('m').type, [listOfB]), [a.type, listOfB]);
    // cOfObject.m(b); // infer <B>
    expect(_inferCall(cOfObject.getMethod('m').type, [listOfB]),
        [objectType, listOfB]);
  }

  void test_boundedRecursively() {
    // class Clonable<T extends Clonable<T>>
    ClassElementImpl clonable =
        ElementFactory.classElement('Clonable', objectType, ['T']);
    (clonable.typeParameters[0] as TypeParameterElementImpl).bound =
        clonable.type;
    // class Foo extends Clonable<Foo>
    ClassElementImpl foo = ElementFactory.classElement('Foo', null);
    foo.supertype = clonable.type.instantiate([foo.type]);

    // <S extends Clonable<S>>
    var s = TypeBuilder.variable('S');
    (s.element as TypeParameterElementImpl).bound =
        clonable.type.instantiate([s]);
    // (S, S) -> S
    var clone = TypeBuilder.function(types: [s], required: [s, s], result: s);
    expect(_inferCall(clone, [foo.type, foo.type]), [foo.type]);

    // Something invalid...
    expect(_inferCall(clone, [stringType, numType], expectError: true),
        [objectType]);
  }

  void test_genericCastFunction() {
    // <TFrom, TTo>(TFrom) -> TTo
    var tFrom = TypeBuilder.variable('TFrom');
    var tTo = TypeBuilder.variable('TTo');
    var cast = TypeBuilder.function(
        types: [tFrom, tTo], required: [tFrom], result: tTo);
    expect(_inferCall(cast, [intType]), [intType, dynamicType]);
  }

  void test_genericCastFunctionWithUpperBound() {
    // <TFrom, TTo extends TFrom>(TFrom) -> TTo
    var tFrom = TypeBuilder.variable('TFrom');
    var tTo = TypeBuilder.variable('TTo', bound: tFrom);
    var cast = TypeBuilder.function(
        types: [tFrom, tTo], required: [tFrom], result: tTo);
    expect(_inferCall(cast, [intType]), [intType, intType]);
  }

  void test_parametersToFunctionParam() {
    // <T>(f(T t)) -> T
    var t = TypeBuilder.variable('T');
    var cast = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: dynamicType)
    ], result: t);
    expect(
        _inferCall(cast, [
          TypeBuilder.function(required: [numType], result: dynamicType)
        ]),
        [numType]);
  }

  void test_parametersUseLeastUpperBound() {
    // <T>(T x, T y) -> T
    var t = TypeBuilder.variable('T');
    var cast = TypeBuilder.function(types: [t], required: [t, t], result: t);
    expect(_inferCall(cast, [intType, doubleType]), [numType]);
  }

  void test_parameterTypeUsesUpperBound() {
    // <T extends num>(T) -> dynamic
    var t = TypeBuilder.variable('T', bound: numType);
    var f =
        TypeBuilder.function(types: [t], required: [t], result: dynamicType);
    expect(_inferCall(f, [intType]), [intType]);
  }

  void test_returnFunctionWithGenericParameter() {
    // <T>(T -> T) -> (T -> void)
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: t)
    ], result: TypeBuilder.function(required: [t], result: voidType));
    expect(
        _inferCall(f, [
          TypeBuilder.function(required: [numType], result: intType)
        ]),
        [intType]);
  }

  void test_returnFunctionWithGenericParameterAndContext() {
    // <T>(T -> T) -> (T -> Null)
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: t)
    ], result: TypeBuilder.function(required: [t], result: nullType));
    expect(
        _inferCall(f, [],
            returnType:
                TypeBuilder.function(required: [numType], result: intType)),
        [numType]);
  }

  void test_returnFunctionWithGenericParameterAndReturn() {
    // <T>(T -> T) -> (T -> T)
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: t)
    ], result: TypeBuilder.function(required: [t], result: t));
    expect(
        _inferCall(f, [
          TypeBuilder.function(required: [numType], result: intType)
        ]),
        [intType]);
  }

  void test_returnFunctionWithGenericReturn() {
    // <T>(T -> T) -> (() -> T)
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: t)
    ], result: TypeBuilder.function(required: [], result: t));
    expect(
        _inferCall(f, [
          TypeBuilder.function(required: [numType], result: intType)
        ]),
        [intType]);
  }

  void test_returnTypeFromContext() {
    // <T>() -> T
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, [], returnType: stringType), [stringType]);
  }

  void test_returnTypeWithBoundFromContext() {
    // <T extends num>() -> T
    var t = TypeBuilder.variable('T', bound: numType);
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, [], returnType: doubleType), [doubleType]);
  }

  void test_returnTypeWithBoundFromInvalidContext() {
    // <T extends num>() -> T
    var t = TypeBuilder.variable('T', bound: numType);
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, [], returnType: stringType), [nullType]);
  }

  void test_unifyParametersToFunctionParam() {
    // <T>(f(T t), g(T t)) -> T
    var t = TypeBuilder.variable('T');
    var cast = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: dynamicType),
      TypeBuilder.function(required: [t], result: dynamicType)
    ], result: t);
    expect(
        _inferCall(cast, [
          TypeBuilder.function(required: [intType], result: dynamicType),
          TypeBuilder.function(required: [doubleType], result: dynamicType)
        ]),
        [nullType]);
  }

  void test_unusedReturnTypeIsDynamic() {
    // <T>() -> T
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, []), [dynamicType]);
  }

  void test_unusedReturnTypeWithUpperBound() {
    // <T extends num>() -> T
    var t = TypeBuilder.variable('T', bound: numType);
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, []), [numType]);
  }

  List<DartType> _inferCall(FunctionTypeImpl ft, List<DartType> arguments,
      {DartType returnType, bool expectError: false}) {
    var listener = new RecordingErrorListener();

    var reporter = new ErrorReporter(
        listener,
        new NonExistingSource(
            '/test.dart', toUri('/test.dart'), UriKind.FILE_URI));

    FunctionType inferred = typeSystem.inferGenericFunctionOrType(
        ft, ft.parameters, arguments, returnType,
        errorReporter: reporter,
        errorNode: astFactory.nullLiteral(new KeywordToken(Keyword.NULL, 0)));

    if (expectError) {
      expect(listener.errors.map((e) => e.errorCode).toList(),
          [StrongModeCode.COULD_NOT_INFER],
          reason: 'expected exactly 1 could not infer error.');
    } else {
      expect(listener.errors, isEmpty, reason: 'did not expect any errors.');
    }
    return inferred?.typeArguments;
  }
}

/**
 * Tests GLB, which only exists in strong mode.
 */
@reflectiveTest
class StrongGreatestLowerBoundTest extends BoundTestBase {
  void setUp() {
    super.setUp();
    typeSystem = new StrongTypeSystemImpl(typeProvider);
  }

  void test_bottom_function() {
    _checkGreatestLowerBound(bottomType, simpleFunctionType, bottomType);
  }

  void test_bottom_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkGreatestLowerBound(bottomType, interfaceType, bottomType);
  }

  void test_bottom_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkGreatestLowerBound(bottomType, typeParam, bottomType);
  }

  void test_bounds_of_top_types_complete() {
    // Test every combination of a subset of Tops programatically.
    final futureOrDynamicType = futureOrType.instantiate([dynamicType]);
    final futureOrObjectType = futureOrType.instantiate([objectType]);
    final futureOrVoidType = futureOrType.instantiate([voidType]);
    final futureOrFutureOrDynamicType =
        futureOrType.instantiate([futureOrDynamicType]);
    final futureOrFutureOrObjectType =
        futureOrType.instantiate([futureOrObjectType]);
    final futureOrFutureOrVoidType =
        futureOrType.instantiate([futureOrVoidType]);

    final orderedTops = [
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
    final futureOrDynamicType = futureOrType.instantiate([dynamicType]);
    final futureOrFutureOrDynamicType =
        futureOrType.instantiate([futureOrDynamicType]);

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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    _checkGreatestLowerBound(classA.type, classC.type, classC.type);
  }

  void test_classAndSuperinterface() {
    // class A
    // class B implements A
    // class C implements B
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classB.interfaces = <InterfaceType>[classA.type];
    classC.interfaces = <InterfaceType>[classB.type];
    _checkGreatestLowerBound(classA.type, classC.type, classC.type);
  }

  void test_dynamic_bottom() {
    _checkGreatestLowerBound(dynamicType, bottomType, bottomType);
  }

  void test_dynamic_function() {
    _checkGreatestLowerBound(
        dynamicType, simpleFunctionType, simpleFunctionType);
  }

  void test_dynamic_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkGreatestLowerBound(dynamicType, interfaceType, interfaceType);
  }

  void test_dynamic_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkGreatestLowerBound(dynamicType, typeParam, typeParam);
  }

  void test_dynamic_void() {
    // Note: _checkGreatestLowerBound tests `GLB(x, y)` as well as `GLB(y, x)`
    _checkGreatestLowerBound(dynamicType, voidType, dynamicType);
  }

  void test_functionsDifferentNamedTakeUnion() {
    FunctionType type1 = _functionType([], named: {'a': intType, 'b': intType});
    FunctionType type2 =
        _functionType([], named: {'b': doubleType, 'c': stringType});
    FunctionType expected =
        _functionType([], named: {'a': intType, 'b': numType, 'c': stringType});
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsDifferentOptionalArityTakeMax() {
    FunctionType type1 = _functionType([], optional: [intType]);
    FunctionType type2 =
        _functionType([], optional: [doubleType, stringType, objectType]);
    FunctionType expected =
        _functionType([], optional: [numType, stringType, objectType]);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsDifferentRequiredArityBecomeOptional() {
    FunctionType type1 = _functionType([intType]);
    FunctionType type2 = _functionType([intType, intType, intType]);
    FunctionType expected =
        _functionType([intType], optional: [intType, intType]);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsFromDynamic() {
    FunctionType type1 = _functionType([dynamicType]);
    FunctionType type2 = _functionType([intType]);
    FunctionType expected = _functionType([dynamicType]);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsGlbReturnType() {
    FunctionType type1 = _functionType([], returns: intType);
    FunctionType type2 = _functionType([], returns: numType);
    FunctionType expected = _functionType([], returns: intType);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubNamedParams() {
    FunctionType type1 =
        _functionType([], named: {'a': stringType, 'b': intType});
    FunctionType type2 = _functionType([], named: {'a': intType, 'b': numType});
    FunctionType expected =
        _functionType([], named: {'a': objectType, 'b': numType});
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubPositionalParams() {
    FunctionType type1 = _functionType([], optional: [stringType, intType]);
    FunctionType type2 = _functionType([], optional: [intType, numType]);
    FunctionType expected = _functionType([], optional: [objectType, numType]);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsLubRequiredParams() {
    FunctionType type1 = _functionType([stringType, intType, intType]);
    FunctionType type2 = _functionType([intType, doubleType, numType]);
    FunctionType expected = _functionType([objectType, numType, numType]);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsMixedOptionalAndRequiredBecomeOptional() {
    FunctionType type1 = _functionType([intType, intType],
        optional: [intType, intType, intType]);
    FunctionType type2 = _functionType([intType], optional: [intType, intType]);
    FunctionType expected = _functionType([intType],
        optional: [intType, intType, intType, intType]);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_functionsReturnBottomIfMixOptionalAndNamed() {
    // Dart doesn't allow a function to have both optional and named parameters,
    // so if we would have synthethized that, pick bottom instead.
    FunctionType type1 = _functionType([intType], named: {'a': intType});
    FunctionType type2 = _functionType([], named: {'a': intType});
    _checkGreatestLowerBound(type1, type2, bottomType);
  }

  void test_functionsSameType() {
    FunctionType type1 = _functionType([stringType, intType, numType],
        optional: [doubleType], named: {'n': numType}, returns: intType);
    FunctionType type2 = _functionType([stringType, intType, numType],
        optional: [doubleType], named: {'n': numType}, returns: intType);
    FunctionType expected = _functionType([stringType, intType, numType],
        optional: [doubleType], named: {'n': numType}, returns: intType);
    _checkGreatestLowerBound(type1, type2, expected);
  }

  void test_interface_function() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkGreatestLowerBound(interfaceType, simpleFunctionType, bottomType);
  }

  void test_mixin() {
    // class A
    // class B
    // class C
    // class D extends A with B, C
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement2("B");
    ClassElement classC = ElementFactory.classElement2("C");
    ClassElementImpl classD = ElementFactory.classElement("D", classA.type);
    classD.mixins = <InterfaceType>[classB.type, classC.type];
    _checkGreatestLowerBound(classA.type, classD.type, classD.type);
    _checkGreatestLowerBound(classB.type, classD.type, classD.type);
    _checkGreatestLowerBound(classC.type, classD.type, classD.type);
  }

  void test_self() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    DartType interfaceType = ElementFactory.classElement2('A', []).type;

    List<DartType> types = [
      dynamicType,
      voidType,
      bottomType,
      typeParam,
      interfaceType,
      simpleFunctionType
    ];

    for (DartType type in types) {
      _checkGreatestLowerBound(type, type, type);
    }
  }

  void test_typeParam_function_noBound() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkGreatestLowerBound(typeParam, simpleFunctionType, bottomType);
  }

  void test_typeParam_interface_bounded() {
    DartType typeA = ElementFactory.classElement2('A', []).type;
    DartType typeB = ElementFactory.classElement('B', typeA).type;
    DartType typeC = ElementFactory.classElement('C', typeB).type;
    TypeParameterElementImpl typeParam =
        ElementFactory.typeParameterElement('T');
    typeParam.bound = typeB;
    _checkGreatestLowerBound(typeParam.type, typeC, bottomType);
  }

  void test_typeParam_interface_noBound() {
    // GLB(T, A) = ⊥
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkGreatestLowerBound(typeParam, interfaceType, bottomType);
  }

  void test_typeParameters_different() {
    // GLB(List<int>, List<double>) = ⊥
    InterfaceType listOfIntType = listType.instantiate(<DartType>[intType]);
    InterfaceType listOfDoubleType =
        listType.instantiate(<DartType>[doubleType]);
    // TODO(rnystrom): Can we do something better here?
    _checkGreatestLowerBound(listOfIntType, listOfDoubleType, bottomType);
  }

  void test_typeParameters_same() {
    // GLB(List<int>, List<int>) = List<int>
    InterfaceType listOfIntType = listType.instantiate(<DartType>[intType]);
    _checkGreatestLowerBound(listOfIntType, listOfIntType, listOfIntType);
  }

  void test_unrelatedClasses() {
    // class A
    // class B
    // class C
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    _checkGreatestLowerBound(classA.type, classB.type, bottomType);
  }

  void test_void() {
    List<DartType> types = [
      bottomType,
      simpleFunctionType,
      ElementFactory.classElement2('A', []).type,
      ElementFactory.typeParameterElement('T').type
    ];
    for (DartType type in types) {
      _checkGreatestLowerBound(_functionType([], returns: voidType),
          _functionType([], returns: type), _functionType([], returns: type));
    }
  }
}

/**
 * Tests LUB in strong mode.
 *
 * Tests defined in this class are ones whose behavior is spec mode-specific.
 * In particular, function parameters are compared using LUB in spec mode, but
 * GLB in strong mode.
 */
@reflectiveTest
class StrongLeastUpperBoundTest extends LeastUpperBoundTestBase {
  void setUp() {
    super.setUp();
    typeSystem = new StrongTypeSystemImpl(typeProvider);
  }

  void test_functionsFuzzyArrows() {
    FunctionType type1 = _functionType([dynamicType]);
    FunctionType type2 = _functionType([intType]);
    FunctionType expected = _functionType([intType]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsGlbNamedParams() {
    FunctionType type1 =
        _functionType([], named: {'a': stringType, 'b': intType});
    FunctionType type2 = _functionType([], named: {'a': intType, 'b': numType});
    FunctionType expected =
        _functionType([], named: {'a': bottomType, 'b': intType});
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsGlbPositionalParams() {
    FunctionType type1 = _functionType([], optional: [stringType, intType]);
    FunctionType type2 = _functionType([], optional: [intType, numType]);
    FunctionType expected = _functionType([], optional: [bottomType, intType]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsGlbRequiredParams() {
    FunctionType type1 = _functionType([stringType, intType, intType]);
    FunctionType type2 = _functionType([intType, doubleType, numType]);
    FunctionType expected = _functionType([bottomType, bottomType, intType]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_nestedNestedFunctionsGlbInnermostParamTypes() {
    FunctionType type1 = _functionType([
      _functionType([
        _functionType([stringType, intType, intType])
      ])
    ]);
    FunctionType type2 = _functionType([
      _functionType([
        _functionType([intType, doubleType, numType])
      ])
    ]);
    FunctionType expected = _functionType([
      _functionType([
        _functionType([bottomType, bottomType, intType])
      ])
    ]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_typeParam_boundedByParam() {
    TypeParameterElementImpl typeParamElementT =
        ElementFactory.typeParameterElement('T');
    TypeParameterElementImpl typeParamElementS =
        ElementFactory.typeParameterElement('S');
    DartType typeParamT = typeParamElementT.type;
    DartType typeParamS = typeParamElementS.type;
    typeParamElementT.bound = typeParamS;
    _checkLeastUpperBound(typeParamT, typeParamS, typeParamS);
  }

  void test_typeParam_class_implements_Function_ignored() {
    DartType typeA = ElementFactory.classElement('A', functionType).type;
    TypeParameterElementImpl typeParamElement =
        ElementFactory.typeParameterElement('T');
    typeParamElement.bound = typeA;
    DartType typeParam = typeParamElement.type;
    _checkLeastUpperBound(typeParam, simpleFunctionType, objectType);
  }

  void test_typeParam_fBounded() {
    ClassElementImpl AClass = ElementFactory.classElement2('A', ["Q"]);
    InterfaceType AType = AClass.type;

    DartType s = TypeBuilder.variable("S");
    (s.element as TypeParameterElementImpl).bound = AType.instantiate([s]);
    DartType u = TypeBuilder.variable("U");
    (u.element as TypeParameterElementImpl).bound = AType.instantiate([u]);

    _checkLeastUpperBound(s, u, AType.instantiate([objectType]));
  }

  /// Check least upper bound of the same class with different type parameters.
  void test_typeParameters_different() {
    // class List<int>
    // class List<double>
    InterfaceType listOfIntType = listType.instantiate(<DartType>[intType]);
    InterfaceType listOfDoubleType =
        listType.instantiate(<DartType>[doubleType]);
    InterfaceType listOfNum = listType.instantiate(<DartType>[numType]);
    _checkLeastUpperBound(listOfIntType, listOfDoubleType, listOfNum);
  }

  /// Check least upper bound of two related classes with different
  /// type parameters.
  void test_typeParametersAndClass_different() {
    // class List<int>
    // class Iterable<double>
    InterfaceType listOfIntType = listType.instantiate(<DartType>[intType]);
    InterfaceType iterableOfDoubleType =
        iterableType.instantiate(<DartType>[doubleType]);
    // TODO(leafp): this should be iterableOfNumType
    _checkLeastUpperBound(listOfIntType, iterableOfDoubleType, objectType);
  }
}

@reflectiveTest
class StrongSubtypingTest {
  TypeProvider typeProvider;
  TypeSystem typeSystem;

  DartType get bottomType => typeProvider.bottomType;
  InterfaceType get doubleType => typeProvider.doubleType;
  DartType get dynamicType => typeProvider.dynamicType;
  InterfaceType get functionType => typeProvider.functionType;
  InterfaceType get futureOrType => typeProvider.futureOrType;
  InterfaceType get intType => typeProvider.intType;
  InterfaceType get listType => typeProvider.listType;
  InterfaceType get numType => typeProvider.numType;
  InterfaceType get objectType => typeProvider.objectType;
  InterfaceType get stringType => typeProvider.stringType;
  DartType get voidType => VoidTypeImpl.instance;

  void setUp() {
    typeProvider = AnalysisContextFactory.contextWithCore().typeProvider;
    typeSystem = new StrongTypeSystemImpl(typeProvider);
  }

  void test_bottom_isBottom() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> equivalents = <DartType>[bottomType];
    List<DartType> supertypes = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      functionType,
      interfaceType
    ];
    _checkGroups(bottomType, equivalents: equivalents, supertypes: supertypes);
  }

  void test_call_method() {
    ClassElementImpl classBottom = ElementFactory.classElement2("Bottom");
    MethodElement methodBottom =
        ElementFactory.methodElement("call", objectType, <DartType>[intType]);
    classBottom.methods = <MethodElement>[methodBottom];

    DartType top =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    InterfaceType bottom = classBottom.type;

    _checkIsNotSubtypeOf(bottom, top);
  }

  void test_classes() {
    ClassElement classTop = ElementFactory.classElement2("A");
    ClassElement classLeft = ElementFactory.classElement("B", classTop.type);
    ClassElement classRight = ElementFactory.classElement("C", classTop.type);
    ClassElement classBottom = ElementFactory.classElement("D", classLeft.type)
      ..interfaces = <InterfaceType>[classRight.type];
    InterfaceType top = classTop.type;
    InterfaceType left = classLeft.type;
    InterfaceType right = classRight.type;
    InterfaceType bottom = classBottom.type;

    _checkLattice(top, left, right, bottom);
  }

  void test_double() {
    List<DartType> equivalents = <DartType>[doubleType];
    List<DartType> supertypes = <DartType>[numType];
    List<DartType> unrelated = <DartType>[intType];
    _checkGroups(doubleType,
        equivalents: equivalents, supertypes: supertypes, unrelated: unrelated);
  }

  void test_dynamic_isTop() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> equivalents = <DartType>[dynamicType, objectType, voidType];
    List<DartType> subtypes = <DartType>[
      intType,
      doubleType,
      numType,
      stringType,
      functionType,
      interfaceType,
      bottomType
    ];
    _checkGroups(dynamicType, equivalents: equivalents, subtypes: subtypes);
  }

  void test_function_subtypes_itself_top_types() {
    var tops = [dynamicType, objectType, voidType];
    // Add FutureOr<T> for T := dynamic, object, void
    tops.addAll(tops.map((t) => futureOrType.instantiate([t])).toList());
    // Add FutureOr<FutureOr<T>> for T := dynamic, object, void
    tops.addAll(
        tops.skip(3).map((t) => futureOrType.instantiate([t])).toList());

    // Function should subtype all of those top types.
    _checkGroups(functionType, supertypes: [
      dynamicType,
      objectType,
      voidType,
    ]);

    // Create a non-identical but equal copy of Function, and verify subtyping
    var copyOfFunction = new InterfaceTypeImpl(functionType.element, null);
    _checkEquivalent(functionType, copyOfFunction);
  }

  void test_genericFunction_generic_monomorphic() {
    DartType s = TypeBuilder.variable("S");
    DartType t = TypeBuilder.variable("T", bound: s);
    DartType u = TypeBuilder.variable("U", bound: intType);
    DartType v = TypeBuilder.variable("V", bound: u);

    DartType a = TypeBuilder.variable("A");
    DartType b = TypeBuilder.variable("B", bound: a);
    DartType c = TypeBuilder.variable("C", bound: intType);
    DartType d = TypeBuilder.variable("D", bound: c);

    _checkIsStrictSubtypeOf(
        TypeBuilder.function(types: [s, t], required: [s], result: t),
        TypeBuilder.function(
            types: [a, b], required: [bottomType], result: dynamicType));

    _checkIsNotSubtypeOf(
        TypeBuilder.function(types: [u, v], required: [u], result: v),
        TypeBuilder.function(
            types: [c, d], required: [objectType], result: objectType));

    _checkIsNotSubtypeOf(
        TypeBuilder.function(types: [u, v], required: [u], result: v),
        TypeBuilder.function(
            types: [c, d], required: [intType], result: intType));
  }

  void test_genericFunction_genericDoesNotSubtypeNonGeneric() {
    DartType s = TypeBuilder.variable("S");
    DartType t = TypeBuilder.variable("T", bound: s);
    DartType u = TypeBuilder.variable("U", bound: intType);
    DartType v = TypeBuilder.variable("V", bound: u);

    _checkIsNotSubtypeOf(
        TypeBuilder.function(types: [s, t], required: [s], result: t),
        TypeBuilder.function(required: [dynamicType], result: dynamicType));

    _checkIsNotSubtypeOf(
        TypeBuilder.function(types: [u, v], required: [u], result: v),
        TypeBuilder.function(required: [objectType], result: objectType));

    _checkIsNotSubtypeOf(
        TypeBuilder.function(types: [u, v], required: [u], result: v),
        TypeBuilder.function(required: [intType], result: intType));
  }

  void test_genericFunction_simple() {
    DartType s = TypeBuilder.variable("S");
    DartType t = TypeBuilder.variable("T");

    _checkEquivalent(
        TypeBuilder.function(types: [t]), TypeBuilder.function(types: [s]));

    _checkEquivalent(TypeBuilder.function(types: [t], required: [t], result: t),
        TypeBuilder.function(types: [s], required: [s], result: s));
  }

  void test_genericFunction_simple_bounded() {
    DartType s = TypeBuilder.variable("S");
    DartType t = TypeBuilder.variable("T", bound: s);
    DartType u = TypeBuilder.variable("U");
    DartType v = TypeBuilder.variable("V", bound: u);

    _checkEquivalent(TypeBuilder.function(types: [s, t]),
        TypeBuilder.function(types: [u, v]));

    _checkEquivalent(
        TypeBuilder.function(types: [s, t], required: [s], result: t),
        TypeBuilder.function(types: [u, v], required: [u], result: v));

    {
      DartType top =
          TypeBuilder.function(types: [s, t], required: [t], result: s);
      DartType left =
          TypeBuilder.function(types: [u, v], required: [u], result: u);
      DartType right =
          TypeBuilder.function(types: [u, v], required: [v], result: v);
      DartType bottom =
          TypeBuilder.function(types: [s, t], required: [s], result: t);
      _checkLattice(top, left, right, bottom);
    }
  }

  void test_generics() {
    ClassElementImpl LClass = ElementFactory.classElement2('L', ["T"]);
    InterfaceType LType = LClass.type;
    ClassElementImpl MClass = ElementFactory.classElement2('M', ["T"]);
    DartType typeParam = MClass.typeParameters[0].type;
    InterfaceType superType = LType.instantiate(<DartType>[typeParam]);
    MClass.interfaces = <InterfaceType>[superType];
    InterfaceType MType = MClass.type;

    InterfaceType top = LType.instantiate(<DartType>[dynamicType]);
    InterfaceType left = MType.instantiate(<DartType>[dynamicType]);
    InterfaceType right = LType.instantiate(<DartType>[intType]);
    InterfaceType bottom = MType.instantiate(<DartType>[intType]);

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
    DartType r =
        TypeBuilder.function(required: <DartType>[intType], result: intType);
    DartType o = TypeBuilder.function(
        required: <DartType>[], optional: <DartType>[intType], result: intType);
    DartType n = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType},
        result: intType);
    DartType rr = TypeBuilder.function(
        required: <DartType>[intType, intType], result: intType);
    DartType ro = TypeBuilder.function(
        required: <DartType>[intType],
        optional: <DartType>[intType],
        result: intType);
    DartType rn = TypeBuilder.function(
        required: <DartType>[intType],
        named: <String, DartType>{'x': intType},
        result: intType);
    DartType oo = TypeBuilder.function(
        required: <DartType>[],
        optional: <DartType>[intType, intType],
        result: intType);
    DartType nn = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType, 'y': intType},
        result: intType);
    DartType nnn = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType, 'y': intType, 'z': intType},
        result: intType);

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
    FunctionType top =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    FunctionType left =
        TypeBuilder.function(required: <DartType>[intType], result: intType);
    FunctionType right = TypeBuilder.function(
        required: <DartType>[objectType], result: objectType);
    FunctionType bottom =
        TypeBuilder.function(required: <DartType>[objectType], result: intType);

    _checkLattice(top, left, right, bottom);
  }

  /// Regression test for https://github.com/dart-lang/sdk/issues/25069
  void test_simple_function_void() {
    FunctionType functionType =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    _checkIsNotSubtypeOf(voidType, functionType);
  }

  void test_void_functions() {
    FunctionType top =
        TypeBuilder.function(required: <DartType>[intType], result: voidType);
    FunctionType bottom =
        TypeBuilder.function(required: <DartType>[objectType], result: intType);

    _checkIsStrictSubtypeOf(bottom, top);
  }

  void test_void_isTop() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> equivalents = <DartType>[dynamicType, objectType, voidType];
    List<DartType> subtypes = <DartType>[
      intType,
      doubleType,
      numType,
      stringType,
      functionType,
      interfaceType,
      bottomType
    ];
    _checkGroups(voidType, equivalents: equivalents, subtypes: subtypes);
  }

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
    expect(typeSystem.isSubtypeOf(type1, type2), false);
  }

  void _checkIsStrictSubtypeOf(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  void _checkIsSubtypeOf(DartType type1, DartType type2) {
    expect(typeSystem.isSubtypeOf(type1, type2), true);
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

class TypeBuilder {
  static FunctionTypeImpl function(
      {List<DartType> types,
      List<DartType> required,
      List<DartType> optional,
      Map<String, DartType> named,
      DartType result}) {
    result = result ?? VoidTypeImpl.instance;
    required = required ?? [];
    FunctionElementImpl f = ElementFactory.functionElement8(required, result,
        optional: optional, named: named);
    if (types != null) {
      f.typeParameters =
          new List<TypeParameterElement>.from(types.map((t) => t.element));
    }
    return f.type = new FunctionTypeImpl(f);
  }

  static TypeParameterType variable(String name, {DartType bound}) =>
      ElementFactory.typeParameterWithType(name, bound).type;
}
