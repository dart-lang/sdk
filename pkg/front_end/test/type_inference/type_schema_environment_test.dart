// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:front_end/src/source/source_library_builder.dart';
import 'package:front_end/src/type_inference/type_constraint_gatherer.dart';
import 'package:front_end/src/type_inference/type_inference_engine.dart';
import 'package:front_end/src/type_inference/type_schema.dart';
import 'package:front_end/src/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/testing/type_parser_environment.dart';
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeSchemaEnvironmentTest);
  });
}

@reflectiveTest
class TypeSchemaEnvironmentTest {
  late Env typeParserEnvironment;
  late TypeSchemaEnvironment typeSchemaEnvironment;

  final Map<String, DartType Function()> additionalTypes = {
    "UNKNOWN": () => new UnknownType(),
  };

  late Library _coreLibrary;
  late Library _testLibrary;

  Library get coreLibrary => _coreLibrary;
  Library get testLibrary => _testLibrary;

  Component get component => typeParserEnvironment.component;
  CoreTypes get coreTypes => typeParserEnvironment.coreTypes;

  late final OperationsCfe _operations;

  void parseTestLibrary(String testLibraryText) {
    typeParserEnvironment = new Env(testLibraryText);
    typeSchemaEnvironment = new TypeSchemaEnvironment(
      coreTypes,
      new ClassHierarchy(component, coreTypes),
    );
    assert(
      typeParserEnvironment.component.libraries.length == 2,
      "The tests are supposed to have exactly two libraries: "
      "the core library and the test library.",
    );
    _operations = new OperationsCfe(
      typeSchemaEnvironment,
      fieldNonPromotabilityInfo: FieldNonPromotabilityInfo(
        fieldNameInfo: {},
        individualPropertyReasons: {},
      ),
      typeCacheNonNullable: {},
      typeCacheNullable: {},
      typeCacheLegacy: {},
    );
    Library firstLibrary = typeParserEnvironment.component.libraries.first;
    Library secondLibrary = typeParserEnvironment.component.libraries.last;
    if (firstLibrary.importUri.isScheme("dart") &&
        firstLibrary.importUri.path == "core") {
      _coreLibrary = firstLibrary;
      _testLibrary = secondLibrary;
    } else {
      assert(
        secondLibrary.importUri.isScheme("dart") &&
            secondLibrary.importUri.path == "core",
        "One of the libraries is expected to be 'dart:core'.",
      );
      _coreLibrary == secondLibrary;
      _testLibrary = firstLibrary;
    }
  }

  void checkConstraintSolving(
    String constraint,
    String expected, {
    required bool grounded,
  }) {
    expect(
      _operations.chooseTypeFromConstraint(
        parseConstraint(constraint),
        grounded: grounded,
        isContravariant: false,
      ),
      parseType(expected),
    );
  }

  void checkConstraintUpperBound({
    required String constraint,
    required String bound,
  }) {
    expect(parseConstraint(constraint).upper, parseType(bound));
  }

  void checkConstraintLowerBound({
    required String constraint,
    required String bound,
  }) {
    expect(parseConstraint(constraint).lower, parseType(bound));
  }

  void checkTypeSatisfiesConstraint(String type, String constraint) {
    expect(
      typeSchemaEnvironment.typeSatisfiesConstraint(
        parseType(type),
        parseConstraint(constraint),
      ),
      isTrue,
    );
  }

  void checkTypeDoesntSatisfyConstraint(String type, String constraint) {
    expect(
      typeSchemaEnvironment.typeSatisfiesConstraint(
        parseType(type),
        parseConstraint(constraint),
      ),
      isFalse,
    );
  }

  void checkIsSubtype(String subtype, String supertype) {
    expect(
      typeSchemaEnvironment
          .performSubtypeCheck(parseType(subtype), parseType(supertype))
          .isSuccess(),
      isTrue,
    );
  }

  void checkIsNotSubtype(String subtype, String supertype) {
    expect(
      typeSchemaEnvironment
          .performSubtypeCheck(parseType(subtype), parseType(supertype))
          .isSuccess(),
      isFalse,
    );
  }

  void checkLowerBound({
    required String type1,
    required String type2,
    required String lowerBound,
    String? typeParameters,
  }) {
    typeParserEnvironment.withTypeParameters(typeParameters, (
      List<TypeParameter> typeParameterNodes,
    ) {
      expect(
        typeSchemaEnvironment.getStandardLowerBound(
          parseType(type1),
          parseType(type2),
        ),
        parseType(lowerBound),
      );
    });
  }

  void checkInference({
    required String typeParametersToInfer,
    required String functionType,
    String? actualParameterTypes,
    String? returnContextType,
    String? inferredTypesFromDownwardPhase,
    required String expectedTypes,
  }) {
    typeParserEnvironment.withStructuralParameters(typeParametersToInfer, (
      List<StructuralParameter> typeParameterNodesToInfer,
    ) {
      FunctionType functionTypeNode = parseType(functionType) as FunctionType;
      DartType? returnContextTypeNode = returnContextType == null
          ? null
          : parseType(returnContextType);
      List<DartType>? actualTypeNodes = actualParameterTypes == null
          ? null
          : parseTypes(actualParameterTypes);
      List<DartType> expectedTypeNodes = parseTypes(expectedTypes);
      DartType declaredReturnTypeNode = functionTypeNode.returnType;
      List<DartType>? formalTypeNodes = actualParameterTypes == null
          ? null
          : functionTypeNode.positionalParameters;

      List<DartType>? inferredTypeNodes;
      if (inferredTypesFromDownwardPhase == null) {
        inferredTypeNodes = null;
      } else {
        inferredTypeNodes = parseTypes(inferredTypesFromDownwardPhase);
      }

      TypeConstraintGatherer gatherer = typeSchemaEnvironment
          .setupGenericTypeInference(
            declaredReturnTypeNode,
            typeParameterNodesToInfer,
            returnContextTypeNode,
            inferenceUsingBoundsIsEnabled: false,
            typeOperations: new OperationsCfe(
              typeSchemaEnvironment,
              fieldNonPromotabilityInfo: new FieldNonPromotabilityInfo(
                fieldNameInfo: {},
                individualPropertyReasons: {},
              ),
              typeCacheNonNullable: {},
              typeCacheNullable: {},
              typeCacheLegacy: {},
            ),
            inferenceResultForTesting: null,
            internalNodeForTesting: null,
          );
      if (formalTypeNodes == null) {
        inferredTypeNodes = typeSchemaEnvironment.choosePreliminaryTypes(
          gatherer.computeConstraints(),
          typeParameterNodesToInfer,
          inferredTypeNodes,
          inferenceUsingBoundsIsEnabled: true,
          dataForTesting: null,
          internalNodeForTesting: null,
          typeOperations: _operations,
        );
      } else {
        gatherer.constrainArguments(
          formalTypeNodes,
          actualTypeNodes!,
          internalNodeForTesting: null,
        );
        inferredTypeNodes = typeSchemaEnvironment.chooseFinalTypes(
          gatherer.computeConstraints(),
          typeParameterNodesToInfer,
          inferredTypeNodes!,
          inferenceUsingBoundsIsEnabled: true,
          dataForTesting: null,
          internalNodeForTesting: null,
          typeOperations: _operations,
        );
      }

      assert(
        inferredTypeNodes.length == expectedTypeNodes.length,
        "The numbers of expected types and type parameters to infer "
        "mismatch.",
      );
      for (int i = 0; i < inferredTypeNodes.length; ++i) {
        expect(inferredTypeNodes[i], expectedTypeNodes[i]);
      }
    });
  }

  void checkInferenceFromConstraints({
    required String typeParameter,
    required String constraints,
    String? inferredTypeFromDownwardPhase,
    required bool downwardsInferPhase,
    required String expected,
  }) {
    assert(inferredTypeFromDownwardPhase == null || !downwardsInferPhase);

    typeParserEnvironment.withStructuralParameters(typeParameter, (
      List<StructuralParameter> typeParameterNodes,
    ) {
      assert(typeParameterNodes.length == 1);

      MergedTypeConstraint typeConstraint = parseConstraint(constraints);
      DartType expectedTypeNode = parseType(expected);
      StructuralParameter typeParameterNode = typeParameterNodes.single;
      List<DartType>? inferredTypeNodes = inferredTypeFromDownwardPhase == null
          ? null
          : <DartType>[parseType(inferredTypeFromDownwardPhase)];

      inferredTypeNodes = _operations
          .chooseTypes(
            [typeParameterNode],
            {typeParameterNode: typeConstraint},
            inferredTypeNodes,
            preliminary: downwardsInferPhase,
            inferenceUsingBoundsIsEnabled: true,
            dataForTesting: null,
            astNodeForTesting: null,
          )
          .cast();

      expect(inferredTypeNodes.single, expectedTypeNode);
    });
  }

  /// Parses a string like "<: T <: S >: R" into a [TypeConstraint].
  ///
  /// The [constraint] string is assumed to be a sequence of bounds added to the
  /// constraint.  Each element of the sequence is either "<: T" or ":> T",
  /// where the former adds an upper bound and the latter adds a lower bound.
  /// The bounds are added to the constraint in the order they are mentioned in
  /// the [constraint] string, from left to right.
  MergedTypeConstraint parseConstraint(String constraint) {
    MergedTypeConstraint result = new MergedTypeConstraint(
      lower: SharedTypeSchemaView(const UnknownType()),
      upper: SharedTypeSchemaView(const UnknownType()),
      origin: const UnknownTypeConstraintOrigin(),
    );
    List<String> upperBoundSegments = constraint.split("<:");
    bool firstUpperBoundSegment = true;
    for (String upperBoundSegment in upperBoundSegments) {
      if (firstUpperBoundSegment) {
        firstUpperBoundSegment = false;
        if (upperBoundSegment.isEmpty) {
          continue;
        }
      }
      List<String> lowerBoundSegments = upperBoundSegment.split(":>");
      bool firstLowerBoundSegment = true;
      for (String segment in lowerBoundSegments) {
        if (firstLowerBoundSegment) {
          firstLowerBoundSegment = false;
          if (segment.isNotEmpty) {
            result.mergeInTypeSchemaUpper(
              SharedTypeSchemaView(parseType(segment)),
              _operations,
            );
          }
        } else {
          result.mergeInTypeSchemaLower(
            SharedTypeSchemaView(parseType(segment)),
            _operations,
          );
        }
      }
    }
    return result;
  }

  DartType parseType(String type) {
    return typeParserEnvironment.parseType(
      type,
      additionalTypes: additionalTypes,
    );
  }

  List<DartType> parseTypes(String types) {
    return typeParserEnvironment.parseTypes(
      types,
      additionalTypes: additionalTypes,
    );
  }

  void test_glb_bottom() {
    parseTestLibrary("class A;");
    checkLowerBound(type1: "Null", type2: "A", lowerBound: "Never");
    checkLowerBound(type1: "A", type2: "Null", lowerBound: "Never");
  }

  void test_glb_function() {
    parseTestLibrary("class A; class B extends A;");

    // GLB(() -> A, () -> B) = () -> B
    checkLowerBound(type1: "() -> A", type2: "() -> B", lowerBound: "() -> B");

    // GLB(() -> void, (A, B) -> void) = ([A, B]) -> void
    checkLowerBound(
      type1: "() -> void",
      type2: "(A, B) -> void",
      lowerBound: "([A, B]) -> void",
    );
    checkLowerBound(
      type1: "(A, B) -> void",
      type2: "() -> void",
      lowerBound: "([A, B]) -> void",
    );

    // GLB((A) -> void, (B) -> void) = (A) -> void
    checkLowerBound(
      type1: "(A) -> void",
      type2: "(B) -> void",
      lowerBound: "(A) -> void",
    );
    checkLowerBound(
      type1: "(B) -> void",
      type2: "(A) -> void",
      lowerBound: "(A) -> void",
    );

    // GLB(({a: A}) -> void, ({b: B}) -> void) = ({a: A, b: B}) -> void
    checkLowerBound(
      type1: "({A a}) -> void",
      type2: "({B b}) -> void",
      lowerBound: "({A a, B b}) -> void",
    );
    checkLowerBound(
      type1: "({B b}) -> void",
      type2: "({A a}) -> void",
      lowerBound: "({A a, B b}) -> void",
    );

    // GLB(({a: A, c: A}) -> void, ({b: B, d: B}) -> void)
    //     = ({a: A, b: B, c: A, d: B}) -> void
    checkLowerBound(
      type1: "({A a, A c}) -> void",
      type2: "({B b, B d}) -> void",
      lowerBound: "({A a, B b, A c, B d}) -> void",
    );

    // GLB(({a: A, b: B}) -> void, ({a: B, b: A}) -> void)
    //     = ({a: A, b: A}) -> void
    checkLowerBound(
      type1: "({A a, B b}) -> void",
      type2: "({B a, A b}) -> void",
      lowerBound: "({A a, A b}) -> void",
    );
    checkLowerBound(
      type1: "({B a, A b}) -> void",
      type2: "({A a, B b}) -> void",
      lowerBound: "({A a, A b}) -> void",
    );

    // GLB((B, {a: A}) -> void, (B) -> void) = (B, {a: A}) -> void
    checkLowerBound(
      type1: "(B, {A a}) -> void",
      type2: "(B) -> void",
      lowerBound: "(B, {A a}) -> void",
    );

    // GLB(({a: A}) -> void, (B) -> void) = bottom
    checkLowerBound(
      type1: "({A a}) -> void",
      type2: "(B) -> void",
      lowerBound: "Never",
    );

    // GLB(({a: A}) -> void, ([B]) -> void) = bottom
    checkLowerBound(
      type1: "({A a}) -> void",
      type2: "([B]) -> void",
      lowerBound: "Never",
    );
  }

  void test_glb_identical() {
    parseTestLibrary("class A;");
    checkLowerBound(type1: "A", type2: "A", lowerBound: "A");
  }

  void test_glb_subtype() {
    parseTestLibrary("class A; class B extends A;");

    checkLowerBound(type1: "A", type2: "B", lowerBound: "B");
    checkLowerBound(type1: "B", type2: "A", lowerBound: "B");
  }

  void test_glb_top() {
    parseTestLibrary("class A;");
    checkLowerBound(type1: "dynamic", type2: "A", lowerBound: "A");
    checkLowerBound(type1: "A", type2: "dynamic", lowerBound: "A");
    checkLowerBound(type1: "Object", type2: "A", lowerBound: "A");
    checkLowerBound(type1: "A", type2: "Object", lowerBound: "A");
    checkLowerBound(type1: "void", type2: "A", lowerBound: "A");
    checkLowerBound(type1: "A", type2: "void", lowerBound: "A");
  }

  void test_glb_unknown() {
    parseTestLibrary("class A;");
    checkLowerBound(type1: "A", type2: "UNKNOWN", lowerBound: "A");
    checkLowerBound(type1: "UNKNOWN", type2: "A", lowerBound: "A");
  }

  void test_glb_unrelated() {
    parseTestLibrary("class A; class B;");
    checkLowerBound(type1: "A", type2: "B", lowerBound: "Never");
  }

  void test_lub_classic() {
    // Make the class hierarchy:
    //
    // Object
    //   |
    //   A
    //  /|
    // B C
    // |X|
    // D E
    parseTestLibrary("""
      class A;
      class B extends A;
      class C extends A;
      class D implements B, C;
      class E implements B, C;
    """);

    checkUpperBound(type1: "D", type2: "E", upperBound: "A");
  }

  void test_lub_commonClass() {
    parseTestLibrary("");
    checkUpperBound(
      type1: "List<int>",
      type2: "List<double>",
      upperBound: "List<num>",
    );
  }

  void test_lub_function() {
    parseTestLibrary("class A; class B extends A;");

    // LUB(() -> A, () -> B) = () -> A
    checkUpperBound(type1: "() -> A", type2: "() -> B", upperBound: "() -> A");

    // LUB(([A]) -> void, (A) -> void) = Function
    checkUpperBound(
      type1: "([A]) -> void",
      type2: "(A) -> void",
      upperBound: "Function",
    );

    // LUB(() -> void, (A, B) -> void) = Function
    checkUpperBound(
      type1: "() -> void",
      type2: "(A, B) -> void",
      upperBound: "Function",
    );
    checkUpperBound(
      type1: "(A, B) -> void",
      type2: "() -> void",
      upperBound: "Function",
    );

    // LUB((A) -> void, (B) -> void) = (B) -> void
    checkUpperBound(
      type1: "(A) -> void",
      type2: "(B) -> void",
      upperBound: "(B) -> void",
    );
    checkUpperBound(
      type1: "(B) -> void",
      type2: "(A) -> void",
      upperBound: "(B) -> void",
    );

    // LUB(({a: A}) -> void, ({b: B}) -> void) = () -> void
    checkUpperBound(
      type1: "({A a}) -> void",
      type2: "({B b}) -> void",
      upperBound: "() -> void",
    );
    checkUpperBound(
      type1: "({B b}) -> void",
      type2: "({A a}) -> void",
      upperBound: "() -> void",
    );

    // LUB(({a: A, c: A}) -> void, ({b: B, d: B}) -> void) = () -> void
    checkUpperBound(
      type1: "({A a, A c}) -> void",
      type2: "({B b, B d}) -> void",
      upperBound: "() -> void",
    );

    // LUB(({a: A, b: B}) -> void, ({a: B, b: A}) -> void)
    //     = ({a: B, b: B}) -> void
    checkUpperBound(
      type1: "({A a, B b}) -> void",
      type2: "({B a, A b}) -> void",
      upperBound: "({B a, B b}) -> void",
    );
    checkUpperBound(
      type1: "({B a, A b}) -> void",
      type2: "({A a, B b}) -> void",
      upperBound: "({B a, B b}) -> void",
    );

    // LUB((B, {a: A}) -> void, (B) -> void) = (B) -> void
    checkUpperBound(
      type1: "(B, {A a}) -> void",
      type2: "(B) -> void",
      upperBound: "(B) -> void",
    );

    // LUB(({a: A}) -> void, (B) -> void) = Function
    checkUpperBound(
      type1: "({A a}) -> void",
      type2: "(B) -> void",
      upperBound: "Function",
    );

    // GLB(({a: A}) -> void, ([B]) -> void) = Function
    checkUpperBound(
      type1: "({A a}) -> void",
      type2: "([B]) -> void",
      upperBound: "Function",
    );
  }

  void test_lub_identical() {
    parseTestLibrary("class A;");
    checkUpperBound(type1: "A", type2: "A", upperBound: "A");
  }

  void test_lub_sameClass() {
    parseTestLibrary("class A; class B extends A; class Map<X, Y>;");
    checkUpperBound(
      type1: "Map<A, B>",
      type2: "Map<B, A>",
      upperBound: "Map<A, A>",
    );
  }

  void test_lub_subtype() {
    parseTestLibrary("");
    checkUpperBound(
      type1: "List<int>",
      type2: "Iterable<num>",
      upperBound: "Iterable<num>",
    );
    checkUpperBound(
      type1: "Iterable<num>",
      type2: "List<int>",
      upperBound: "Iterable<num>",
    );
  }

  void test_lub_top() {
    parseTestLibrary("class A;");

    checkUpperBound(type1: "dynamic", type2: "A", upperBound: "dynamic");
    checkUpperBound(type1: "A", type2: "dynamic", upperBound: "dynamic");
    checkUpperBound(type1: "Object", type2: "A", upperBound: "Object");
    checkUpperBound(type1: "A", type2: "Object", upperBound: "Object");
    checkUpperBound(type1: "void", type2: "A", upperBound: "void");
    checkUpperBound(type1: "A", type2: "void", upperBound: "void");
    checkUpperBound(type1: "dynamic", type2: "Object", upperBound: "dynamic");
    checkUpperBound(type1: "Object", type2: "dynamic", upperBound: "dynamic");
    checkUpperBound(type1: "dynamic", type2: "void", upperBound: "void");
    checkUpperBound(type1: "void", type2: "dynamic", upperBound: "void");
    checkUpperBound(type1: "Object", type2: "void", upperBound: "void");
    checkUpperBound(type1: "void", type2: "Object", upperBound: "void");
  }

  void test_lub_typeParameter() {
    parseTestLibrary("");

    // LUB(T, T) = T
    checkUpperBound(
      type1: "T",
      type2: "T",
      upperBound: "T",
      typeParameters: "T extends List<T>",
    );

    // LUB(T, List<Bottom>) = LUB(List<Object>, List<Bottom>) = List<Object?>
    checkUpperBound(
      type1: "T",
      type2: "List<Null>",
      upperBound: "List<Object?>",
      typeParameters: "T extends List<T>",
    );
    checkUpperBound(
      type1: "List<Null>",
      type2: "T",
      upperBound: "List<Object?>",
      typeParameters: "T extends List<T>",
    );

    // LUB(T, U) = LUB(List<Object>, U) = LUB(List<Object?>, List<Bottom>)
    // = List<Object>
    checkUpperBound(
      type1: "T",
      type2: "U",
      upperBound: "List<Object?>",
      typeParameters: "T extends List<T>, U extends List<Null>",
    );
    checkUpperBound(
      type1: "U",
      type2: "T",
      upperBound: "List<Object?>",
      typeParameters: "T extends List<T>, U extends List<Null>",
    );
  }

  void test_lub_unknown() {
    parseTestLibrary("class A;");
    checkUpperBound(type1: "A", type2: "UNKNOWN", upperBound: "A");
    checkUpperBound(type1: "UNKNOWN", type2: "A", upperBound: "A");
  }

  void test_solveTypeConstraint() {
    parseTestLibrary("""
      class A;
      class B extends A;

      class C<T extends Object>;
      class D<T extends Object> extends C<T>;

      class E<X>;
      class F<Y> extends E<Y>;
    """);

    // TODO(cstefantsova): Test for various nullabilities.

    // Solve(? <: T <: ?) => ?
    checkConstraintSolving("", "UNKNOWN", grounded: false);

    // Solve(? <: T <: ?, grounded) => ?
    // Fully unconstrained variables are inferred via instantiate-to-bounds
    // rather than constraint solving.
    checkConstraintSolving("", "UNKNOWN", grounded: true);

    // Solve(A <: T <: ?) => A
    checkConstraintSolving(":> A", "A", grounded: false);

    // Solve(A <: T <: ?, grounded) => A
    checkConstraintSolving(":> A", "A", grounded: true);

    // Solve(A<?> <: T <: ?) => A<?>
    checkConstraintSolving(":> C<UNKNOWN>", "C<UNKNOWN>", grounded: false);

    // Solve(A<?> <: T <: ?, grounded) => A<Never>
    checkConstraintSolving(":> C<UNKNOWN>", "C<Never>", grounded: true);

    // Solve(? <: T <: A) => A
    checkConstraintSolving("<: A", "A", grounded: false);

    // Solve(? <: T <: A, grounded) => A
    checkConstraintSolving("<: A", "A", grounded: true);

    // Solve(? <: T <: A<?>) => A<?>
    checkConstraintSolving("<: C<UNKNOWN>", "C<UNKNOWN>", grounded: false);

    // Solve(? <: T <: A<?>, grounded) => A<Object?>
    checkConstraintSolving("<: C<UNKNOWN>", "C<Object?>", grounded: true);

    // Solve(B <: T <: A) => B
    checkConstraintSolving(":> B <: A", "B", grounded: false);

    // Solve(B <: T <: A, grounded) => B
    checkConstraintSolving(":> B <: A", "B", grounded: true);

    // Solve(B<?> <: T <: A) => A
    checkConstraintSolving(
      ":> D<UNKNOWN> <: C<dynamic>",
      "C<dynamic>",
      grounded: false,
    );

    // Solve(B<?> <: T <: A, grounded) => A
    checkConstraintSolving(
      ":> D<UNKNOWN> <: C<dynamic>",
      "C<dynamic>",
      grounded: true,
    );

    // Solve(B <: T <: A<?>) => B
    checkConstraintSolving(
      ":> D<Null> <: C<UNKNOWN>",
      "D<Null>",
      grounded: false,
    );

    // Solve(B <: T <: A<?>, grounded) => B
    checkConstraintSolving(
      ":> D<Null> <: C<UNKNOWN>",
      "D<Null>",
      grounded: true,
    );

    // Solve(B<?> <: T <: A<?>) => B<?>
    checkConstraintSolving(
      ":> D<UNKNOWN> <: C<UNKNOWN>",
      "D<UNKNOWN>",
      grounded: false,
    );

    // Solve(B<?> <: T <: A<?>) => B<Never>
    checkConstraintSolving(
      ":> D<UNKNOWN> <: C<UNKNOWN>",
      "D<Never>",
      grounded: true,
    );

    // Solve(? <: T <: ?) => ?
    checkConstraintSolving("", "UNKNOWN", grounded: false);

    // Solve(? <: T <: ?, grounded) => ?
    // Fully unconstrained variables are inferred via instantiate-to-bounds
    // rather than constraint solving.
    checkConstraintSolving("", "UNKNOWN", grounded: true);

    // Solve(E <: T <: ?) => E
    checkConstraintSolving(":> E<dynamic>", "E<dynamic>", grounded: false);

    // Solve(E <: T <: ?, grounded) => E
    checkConstraintSolving(":> E<dynamic>", "E<dynamic>", grounded: true);

    // Solve(E<?> <: T <: ?) => E<?>
    checkConstraintSolving(":> E<UNKNOWN>", "E<UNKNOWN>", grounded: false);

    // Solve(E<?> <: T <: ?, grounded) => E<Never>
    checkConstraintSolving(":> E<UNKNOWN>", "E<Never>", grounded: true);

    // Solve(? <: T <: E) => E
    checkConstraintSolving("<: E<dynamic>", "E<dynamic>", grounded: false);

    // Solve(? <: T <: E, grounded) => E
    checkConstraintSolving("<: E<dynamic>", "E<dynamic>", grounded: true);

    // Solve(? <: T <: E<?>) => E<?>
    checkConstraintSolving("<: E<UNKNOWN>", "E<UNKNOWN>", grounded: false);

    // Solve(? <: T <: E<?>, grounded) => E<dynamic>
    checkConstraintSolving("<: E<UNKNOWN>", "E<Object?>", grounded: true);

    // Solve(F <: T <: E) => F
    checkConstraintSolving(
      ":> F<dynamic> <: E<dynamic>",
      "F<dynamic>",
      grounded: false,
    );

    // Solve(F <: T <: E, grounded) => F
    checkConstraintSolving(
      ":> F<dynamic> <: E<dynamic>",
      "F<dynamic>",
      grounded: true,
    );

    // Solve(F<?> <: T <: E) => E
    checkConstraintSolving(
      ":> F<UNKNOWN> <: E<dynamic>",
      "E<dynamic>",
      grounded: false,
    );

    // Solve(F<?> <: T <: E, grounded) => E
    checkConstraintSolving(
      ":> F<UNKNOWN> <: E<dynamic>",
      "E<dynamic>",
      grounded: true,
    );

    // Solve(F <: T <: E<?>) => F
    checkConstraintSolving(
      ":> F<dynamic> <: E<UNKNOWN>",
      "F<dynamic>",
      grounded: false,
    );

    // Solve(F <: T <: E<?>, grounded) => F
    checkConstraintSolving(
      ":> F<dynamic> <: E<UNKNOWN>",
      "F<dynamic>",
      grounded: true,
    );

    // Solve(F<?> <: T <: E<?>) => F<?>
    checkConstraintSolving(
      ":> F<UNKNOWN> <: E<UNKNOWN>",
      "F<UNKNOWN>",
      grounded: false,
    );

    // Solve(F<?> <: T <: E<?>, grounded) => F<Never>
    checkConstraintSolving(
      ":> F<UNKNOWN> <: E<UNKNOWN>",
      "F<Never>",
      grounded: true,
    );
  }

  void test_typeConstraint_default() {
    parseTestLibrary("");
    checkConstraintUpperBound(constraint: "", bound: "UNKNOWN");
    checkConstraintLowerBound(constraint: "", bound: "UNKNOWN");
  }

  void test_typeSatisfiesConstraint() {
    parseTestLibrary("""
      class A;
      class B extends A;
      class C extends B;
      class D extends C;
      class E extends D;
    """);

    checkTypeDoesntSatisfyConstraint("A", ":> D <: B");
    checkTypeSatisfiesConstraint("B", ":> D <: B");
    checkTypeSatisfiesConstraint("C", ":> D <: B");
    checkTypeSatisfiesConstraint("D", ":> D <: B");
    checkTypeDoesntSatisfyConstraint("E", ":> D <: B");
  }

  void test_unknown_at_bottom() {
    parseTestLibrary("class A;");

    // TODO(cstefantsova): Test for various nullabilities.
    checkIsSubtype("UNKNOWN", "A");
  }

  void test_unknown_at_top() {
    parseTestLibrary("class A; class Map<X, Y>;");
    checkIsSubtype("A", "UNKNOWN");
    checkIsSubtype("Map<A, A>", "Map<UNKNOWN, UNKNOWN>");
    checkIsSubtype("Map<A, Null>", "Map<UNKNOWN, UNKNOWN>");
  }

  void checkTypeShapeCheckSufficiency({
    required String expressionStaticType,
    required String checkTargetType,
    required String typeParameters,
    required TypeShapeCheckSufficiency sufficiency,
  }) {
    typeParserEnvironment.withStructuralParameters(typeParameters, (
      List<StructuralParameter> structuralParameters,
    ) {
      expect(
        typeSchemaEnvironment.computeTypeShapeCheckSufficiency(
              expressionStaticType: parseType(expressionStaticType),
              checkTargetType: parseType(checkTargetType),
            ) ==
            sufficiency,
        isTrue,
      );
    });
  }

  void test_addLowerBound() {
    parseTestLibrary("""
      class A;
      class B extends A;
      class C extends A;
    """);

    // TODO(cstefantsova): Test for various nullabilities.

    // typeConstraint: EMPTY <: TYPE <: EMPTY
    checkConstraintLowerBound(constraint: "", bound: "UNKNOWN");

    // typeConstraint: B <: TYPE <: EMPTY
    checkConstraintLowerBound(constraint: ":> B", bound: "B");

    // typeConstraint: UP(B, C) <: TYPE <: EMPTY,
    //     where UP(B, C) = A
    checkConstraintLowerBound(constraint: ":> B :> C", bound: "A");
  }

  void test_addUpperBound() {
    parseTestLibrary("""
      class A;
      class B extends A;
      class C extends A;
    """);

    // TODO(cstefantsova): Test for various nullabilities.

    // typeConstraint: EMPTY <: TYPE <: EMPTY
    checkConstraintUpperBound(constraint: "", bound: "UNKNOWN");

    // typeConstraint: EMPTY <: TYPE <: A
    checkConstraintUpperBound(constraint: "<: A", bound: "A");

    // typeConstraint: EMPTY <: TYPE <: DOWN(A, B),
    //     where DOWN(A, B) = B
    checkConstraintUpperBound(constraint: "<: A <: B", bound: "B");

    // typeConstraint: EMPTY <: TYPE <: DOWN(B, C),
    //     where DOWN(B, C) = Never
    checkConstraintUpperBound(constraint: "<:A <: B <: C", bound: "Never");
  }

  /// Some of the types satisfying the TOP predicate.
  ///
  /// There's an infinite amount of such types, and the list contains some
  /// practical base cases.  For the definition of TOP see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  static const Map<String, String?> topPredicateEnumeration = {
    // dynamic and void.
    "dynamic": null,
    "void": null,

    // T? where OBJECT(T).
    "Object?": null,
    "FutureOr<Object>?": null,
    "FutureOr<FutureOr<Object>>?": null,

    // FutureOr<T> where TOP(T).
    "FutureOr<dynamic>": null,
    "FutureOr<void>": null,
    "FutureOr<Object?>": null,
    "FutureOr<FutureOr<Object>?>": null,
    "FutureOr<FutureOr<FutureOr<Object>>?>": null,
    "FutureOr<FutureOr<dynamic>?>": null,
    "FutureOr<FutureOr<void>?>": null,
    "FutureOr<FutureOr<Object?>?>": null,
    "FutureOr<FutureOr<FutureOr<Object>?>?>": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>?>": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>>?>": null,
    "FutureOr<FutureOr<dynamic>>": null,
    "FutureOr<FutureOr<void>>": null,
    "FutureOr<FutureOr<Object?>>": null,
    "FutureOr<FutureOr<FutureOr<Object>?>>": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>>": null,

    // T? where TOP(T).
    "FutureOr<dynamic>?": null,
    "FutureOr<void>?": null,
    "FutureOr<Object?>?": null,
    "FutureOr<FutureOr<Object>?>?": null,
    "FutureOr<FutureOr<FutureOr<Object>>?>?": null,
    "FutureOr<FutureOr<FutureOr<Object>>>?": null,
    "FutureOr<FutureOr<dynamic>?>?": null,
    "FutureOr<FutureOr<void>?>?": null,
    "FutureOr<FutureOr<Object?>?>?": null,
    "FutureOr<FutureOr<FutureOr<Object>?>?>?": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>?>?": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>>?>?": null,
    "FutureOr<FutureOr<dynamic>>?": null,
    "FutureOr<FutureOr<void>>?": null,
    "FutureOr<FutureOr<Object?>>?": null,
    "FutureOr<FutureOr<FutureOr<Object>?>>?": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>>?": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>>>?": null,
  };

  /// Some of the types satisfying the OBJECT predicate.
  ///
  /// There's an infinite amount of such types, and the list contains some
  /// practical base cases.  For the definition of OBJECT see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  static const Map<String, String?> objectPredicateEnumeration = {
    "Object": null,
    "FutureOr<Object>": null,
    "FutureOr<FutureOr<Object>>": null,
  };

  /// Some of the types satisfying the BOTTOM predicate.
  ///
  /// There's an infinite amount of such types, and the list contains some
  /// practical base cases.  For the definition of BOTTOM see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  ///
  /// The names of the variables here and in [nullPredicateEnumeration] should
  /// be distinct to avoid collisions.
  static const Map<String, String?> bottomPredicateEnumeration = {
    "Never": null,
    "Xb & Never": "Xb extends Object?",
    "Yb & Zb & Never": "Yb extends Object?, Zb extends Object?",
    "Vb": "Vb extends Never",
    "Wb": "Wb extends Tb, Tb extends Never",
    "Sb & Rb": "Sb extends Object?, Rb extends Never",
  };

  /// Some of the types satisfying the NULL predicate.
  ///
  /// There's an infinite amount of such types, and the list contains some
  /// practical base cases.  For the definition of NULL see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  ///
  /// The names of the variables here and in [bottomPredicateEnumeration] should
  /// be distinct to avoid collisions.
  static const Map<String, String?> nullPredicateEnumeration = {
    // T? where BOTTOM(T).
    "Never?": null,
    "Xn?": "Xn extends Never",
    "Yn?": "Yn extends Zn, Zn extends Never",

    // Null.
    "Null": null,
  };

  static String? joinTypeParameters(
    String? typeParameters1,
    String? typeParameters2,
  ) {
    if (typeParameters1 == null) return typeParameters2;
    if (typeParameters2 == null) return typeParameters1;
    if (typeParameters1 == typeParameters2) return typeParameters1;
    return "$typeParameters1, $typeParameters2";
  }

  void test_lower_bound_bottom() {
    parseTestLibrary("class A;");

    // DOWN(T1, T2) where BOTTOM(T1) and BOTTOM(T2) =
    //   T1 if MOREBOTTOM(T1, T2)
    //   T2 otherwise
    for (String t1 in bottomPredicateEnumeration.keys) {
      for (String t2 in bottomPredicateEnumeration.keys) {
        String? typeParameters = joinTypeParameters(
          bottomPredicateEnumeration[t1],
          bottomPredicateEnumeration[t2],
        );
        typeParserEnvironment.withTypeParameters(typeParameters, (_) {
          String expected =
              typeSchemaEnvironment.morebottom(parseType(t1), parseType(t2))
              ? t1
              : t2;
          checkLowerBound(
            type1: t1,
            type2: t2,
            lowerBound: expected,
            typeParameters: typeParameters,
          );
        });
      }
    }

    // DOWN(T1, T2) = T2 if BOTTOM(T2)
    for (String type in ["A", "A?"]) {
      for (String t2 in bottomPredicateEnumeration.keys) {
        checkLowerBound(
          type1: type,
          type2: t2,
          lowerBound: t2,
          typeParameters: bottomPredicateEnumeration[t2],
        );
      }
    }

    // DOWN(T1, T2) = T1 if BOTTOM(T1)
    for (String t1 in bottomPredicateEnumeration.keys) {
      for (String type in ["A", "A?"]) {
        checkLowerBound(
          type1: t1,
          type2: type,
          lowerBound: t1,
          typeParameters: bottomPredicateEnumeration[t1],
        );
      }
    }

    // DOWN(T1, T2) where NULL(T1) and NULL(T2) =
    //   T1 if MOREBOTTOM(T1, T2)
    //   T2 otherwise
    for (String t1 in nullPredicateEnumeration.keys) {
      for (String t2 in nullPredicateEnumeration.keys) {
        String? typeParameters = joinTypeParameters(
          nullPredicateEnumeration[t1],
          nullPredicateEnumeration[t2],
        );
        typeParserEnvironment.withTypeParameters(typeParameters, (_) {
          String expected =
              typeSchemaEnvironment.morebottom(parseType(t1), parseType(t2))
              ? t1
              : t2;
          checkLowerBound(
            type1: t1,
            type2: t2,
            lowerBound: expected,
            typeParameters: typeParameters,
          );
        });
      }
    }

    // DOWN(Null, T2) =
    //   Null if Null <: T2
    //   Never otherwise
    for (String t1 in nullPredicateEnumeration.keys) {
      checkLowerBound(
        type1: t1,
        type2: "A?",
        lowerBound: t1,
        typeParameters: nullPredicateEnumeration[t1],
      );
      checkLowerBound(
        type1: t1,
        type2: "A",
        lowerBound: "Never",
        typeParameters: nullPredicateEnumeration[t1],
      );
    }

    // DOWN(T1, Null) =
    //   Null if Null <: T1
    //   Never otherwise
    for (String t2 in nullPredicateEnumeration.keys) {
      checkLowerBound(
        type1: "A?",
        type2: t2,
        lowerBound: t2,
        typeParameters: nullPredicateEnumeration[t2],
      );
      checkLowerBound(
        type1: "A",
        type2: t2,
        lowerBound: "Never",
        typeParameters: nullPredicateEnumeration[t2],
      );
    }
  }

  void test_lower_bound_object() {
    parseTestLibrary("");

    checkLowerBound(
      type1: "Object",
      type2: "FutureOr<Null>",
      lowerBound: "Never",
    );
    checkLowerBound(
      type1: "FutureOr<Null>",
      type2: "Object",
      lowerBound: "Never",
    );

    // FutureOr<dynamic> is top.
    checkLowerBound(
      type1: "Object",
      type2: "FutureOr<dynamic>",
      lowerBound: "Object",
    );
    checkLowerBound(
      type1: "FutureOr<dynamic>",
      type2: "Object",
      lowerBound: "Object",
    );

    // FutureOr<X> is not top and cannot be made non-nullable.
    checkLowerBound(
      type1: "Object",
      type2: "FutureOr<X>",
      lowerBound: "Never",
      typeParameters: 'X extends dynamic',
    );
    checkLowerBound(
      type1: "FutureOr<X>",
      type2: "Object",
      lowerBound: "Never",
      typeParameters: 'X extends dynamic',
    );

    // FutureOr<void> is top.
    checkLowerBound(
      type1: "Object",
      type2: "FutureOr<void>",
      lowerBound: "Object",
    );
    checkLowerBound(
      type1: "FutureOr<void>",
      type2: "Object",
      lowerBound: "Object",
    );
  }

  void test_lower_bound_function() {
    parseTestLibrary("""
      class A;
      class B extends A;
    """);

    // TODO(cstefantsova): Test for various nullabilities.
    checkLowerBound(type1: "() -> A", type2: "() -> B", lowerBound: "() -> B");
    checkLowerBound(
      type1: "() -> void",
      type2: "(A, B) -> void",
      lowerBound: "([A, B]) -> void",
    );
    checkLowerBound(
      type1: "(A, B) -> void",
      type2: "() -> void",
      lowerBound: "([A, B]) -> void",
    );
    checkLowerBound(
      type1: "(A) -> void",
      type2: "(B) -> void",
      lowerBound: "(A) -> void",
    );
    checkLowerBound(
      type1: "(B) -> void",
      type2: "(A) -> void",
      lowerBound: "(A) -> void",
    );
    checkLowerBound(
      type1: "({A a}) -> void",
      type2: "({B b}) -> void",
      lowerBound: "({A a, B b}) -> void",
    );
    checkLowerBound(
      type1: "({B b}) -> void",
      type2: "({A a}) -> void",
      lowerBound: "({A a, B b}) -> void",
    );
    checkLowerBound(
      type1: "({A a, A c}) -> void",
      type2: "({B b, B d}) -> void",
      lowerBound: "({A a, B b, A c, B d}) -> void",
    );
    checkLowerBound(
      type1: "({A a, B b}) -> void",
      type2: "({B a, A b}) -> void",
      lowerBound: "({A a, A b}) -> void",
    );
    checkLowerBound(
      type1: "({B a, A b}) -> void",
      type2: "({A a, B b}) -> void",
      lowerBound: "({A a, A b}) -> void",
    );
    checkLowerBound(
      type1: "(B, {A a}) -> void",
      type2: "(B) -> void",
      lowerBound: "(B, {A a}) -> void",
    );
    checkLowerBound(
      type1: "({A a}) -> void",
      type2: "(B) -> void",
      lowerBound: "Never",
    );
    checkLowerBound(
      type1: "({A a}) -> void",
      type2: "([B]) -> void",
      lowerBound: "Never",
    );
    checkLowerBound(
      type1: "<X>() -> void",
      type2: "<Y>() -> void",
      lowerBound: "<Z>() -> void",
    );
    checkLowerBound(
      type1: "<X>(X) -> List<X>",
      type2: "<Y>(Y) -> List<Y>",
      lowerBound: "<Z>(Z) -> List<Z>",
    );
    checkLowerBound(
      type1: "<X1, X2 extends List<X1>>(X1) -> X2",
      type2: "<Y1, Y2 extends List<Y1>>(Y1) -> Y2",
      lowerBound: "<Z1, Z2 extends List<Z1>>(Z1) -> Z2",
    );
    checkLowerBound(
      type1: "<X extends int>(X) -> void",
      type2: "<Y extends double>(Y) -> void",
      lowerBound: "Never",
    );

    checkLowerBound(
      type1: "({required A a, A b, required A c, A d, required A e}) -> A",
      type2: "({required B a, required B b, B c, B f, required B g}) -> B",
      lowerBound: "({required A a, A b, A c, A d, A e, B f, B g}) -> B",
    );

    checkLowerBound(
      type1: "<X extends dynamic>() -> void",
      type2: "<Y extends Object?>() -> void",
      lowerBound: "<Z extends dynamic>() -> void",
    );
    checkLowerBound(
      type1: "<X extends Null>() -> void",
      type2: "<Y extends Never?>() -> void",
      lowerBound: "<Z extends Null>() -> void",
    );
    checkLowerBound(
      type1: "<X extends FutureOr<dynamic>?>() -> void",
      type2: "<Y extends FutureOr<Object?>>() -> void",
      lowerBound: "<Z extends FutureOr<dynamic>?>() -> void",
    );
  }

  void test_lower_bound_record() {
    parseTestLibrary("""
      class A;
      class B extends A;
    """);

    checkLowerBound(type1: "(A, B)", type2: "(B, A)", lowerBound: "(B, B)");
    checkLowerBound(
      type1: "(A, {B b})",
      type2: "(B, {A b})",
      lowerBound: "(B, {B b})",
    );
    checkLowerBound(
      type1: "(A, {(B, {A a}) b})",
      type2: "(B, {(A, {B a}) b})",
      lowerBound: "(B, {(B, {B a}) b})",
    );
    checkLowerBound(type1: "(A?, B)", type2: "(B, A?)", lowerBound: "(B, B)");
    checkLowerBound(type1: "(A, B?)", type2: "(B?, A)", lowerBound: "(B, B)");

    checkLowerBound(type1: "(A, A)", type2: "(A, A, A)", lowerBound: "Never");
    checkLowerBound(type1: "(A, A)", type2: "(A, {A a})", lowerBound: "Never");
    checkLowerBound(type1: "({A a})", type2: "(A, A)", lowerBound: "Never");
    checkLowerBound(
      type1: "({A a, B b})",
      type2: "({A a})",
      lowerBound: "Never",
    );

    checkLowerBound(type1: "(A, B)", type2: "Record", lowerBound: "(A, B)");
    checkLowerBound(type1: "Record", type2: "(A, B)", lowerBound: "(A, B)");

    checkLowerBound(
      type1: "(A, B)",
      type2: "(A, B) -> void",
      lowerBound: "Never",
    );
    checkLowerBound(type1: "Record", type2: "A", lowerBound: "Never");
  }

  void test_lower_bound_identical() {
    parseTestLibrary("class A;");

    checkLowerBound(type1: "A", type2: "A", lowerBound: "A");
    checkLowerBound(type1: "A?", type2: "A?", lowerBound: "A?");
  }

  void test_lower_bound_subtype() {
    parseTestLibrary("""
      class A;
      class B extends A;
    """);

    checkLowerBound(type1: "A", type2: "B", lowerBound: "B");
    checkLowerBound(type1: "A", type2: "B?", lowerBound: "B");

    checkLowerBound(type1: "A?", type2: "B", lowerBound: "B");
    checkLowerBound(type1: "A?", type2: "B?", lowerBound: "B?");

    checkLowerBound(type1: "B", type2: "A", lowerBound: "B");
    checkLowerBound(type1: "B?", type2: "A", lowerBound: "B");

    checkLowerBound(type1: "B", type2: "A?", lowerBound: "B");
    checkLowerBound(type1: "B?", type2: "A?", lowerBound: "B?");

    checkLowerBound(
      type1: "Iterable<A>",
      type2: "List<B>",
      lowerBound: "List<B>",
    );
    checkLowerBound(
      type1: "Iterable<A>",
      type2: "List<B>?",
      lowerBound: "List<B>",
    );

    checkLowerBound(
      type1: "Iterable<A>?",
      type2: "List<B>",
      lowerBound: "List<B>",
    );
    checkLowerBound(
      type1: "Iterable<A>?",
      type2: "List<B>?",
      lowerBound: "List<B>?",
    );

    checkLowerBound(
      type1: "List<B>",
      type2: "Iterable<A>",
      lowerBound: "List<B>",
    );
    checkLowerBound(
      type1: "List<B>?",
      type2: "Iterable<A>",
      lowerBound: "List<B>",
    );

    checkLowerBound(
      type1: "List<B>",
      type2: "Iterable<A>?",
      lowerBound: "List<B>",
    );
    checkLowerBound(
      type1: "List<B>?",
      type2: "Iterable<A>?",
      lowerBound: "List<B>?",
    );
  }

  void test_lower_bound_top() {
    parseTestLibrary("class A;");

    // DOWN(T1, T2) where TOP(T1) and TOP(T2) =
    //   T1 if MORETOP(T2, T1)
    //   T2 otherwise
    for (String t1 in topPredicateEnumeration.keys) {
      for (String t2 in topPredicateEnumeration.keys) {
        String? typeParameters = joinTypeParameters(
          topPredicateEnumeration[t1],
          topPredicateEnumeration[t2],
        );
        typeParserEnvironment.withTypeParameters(typeParameters, (_) {
          String expected =
              typeSchemaEnvironment.moretop(parseType(t2), parseType(t1))
              ? t1
              : t2;
          checkLowerBound(
            type1: t1,
            type2: t2,
            lowerBound: expected,
            typeParameters: typeParameters,
          );
        });
      }
    }

    // DOWN(T1, T2) = T2 if TOP(T1)
    for (String t1 in topPredicateEnumeration.keys) {
      checkLowerBound(
        type1: t1,
        type2: "A",
        lowerBound: "A",
        typeParameters: topPredicateEnumeration[t1],
      );
    }

    // DOWN(T1, T2) = T1 if TOP(T2)
    for (String t2 in topPredicateEnumeration.keys) {
      checkLowerBound(
        type1: "A",
        type2: t2,
        lowerBound: "A",
        typeParameters: topPredicateEnumeration[t2],
      );
    }
  }

  void test_lower_bound_unknown() {
    parseTestLibrary("class A;");

    checkLowerBound(type1: "A", type2: "UNKNOWN", lowerBound: "A");
    checkLowerBound(type1: "A?", type2: "UNKNOWN", lowerBound: "A?");

    checkLowerBound(type1: "UNKNOWN", type2: "A", lowerBound: "A");
    checkLowerBound(type1: "UNKNOWN", type2: "A?", lowerBound: "A?");
  }

  void test_lower_bound_unrelated() {
    parseTestLibrary("""
      class A;
      class B;
    """);

    checkLowerBound(type1: "A", type2: "B", lowerBound: "Never");
    checkLowerBound(type1: "A", type2: "B?", lowerBound: "Never");

    checkLowerBound(type1: "A?", type2: "B", lowerBound: "Never");
    checkLowerBound(type1: "A?", type2: "B?", lowerBound: "Never?");
  }

  void test_inferGenericFunctionOrType() {
    parseTestLibrary("");

    // TODO(cstefantsova): Test for various nullabilities.

    // Test an instantiation of [1, 2.0] with no context.  This should infer
    // as List<?> during downwards inference.
    checkInference(
      typeParametersToInfer: "T extends Object?",
      functionType: "(T, T) -> List<T>",
      actualParameterTypes: null,
      returnContextType: null,
      expectedTypes: "UNKNOWN",
    );
    // And upwards inference should refine it to List<num>.
    checkInference(
      typeParametersToInfer: "T extends Object?",
      functionType: "(T, T) -> List<T>",
      actualParameterTypes: "int, double",
      returnContextType: null,
      inferredTypesFromDownwardPhase: "UNKNOWN",
      expectedTypes: "num",
    );

    // Test an instantiation of [1, 2.0] with a context of List<Object>.  This
    // should infer as List<Object> during downwards inference.
    checkInference(
      typeParametersToInfer: "T extends Object?",
      functionType: "(T, T) -> List<T>",
      actualParameterTypes: null,
      returnContextType: "List<Object>",
      expectedTypes: "Object",
    );
    // And upwards inference should preserve the type.
    checkInference(
      typeParametersToInfer: "T extends Object?",
      functionType: "(T, T) -> List<T>",
      actualParameterTypes: "int, double",
      returnContextType: "List<Object>",
      inferredTypesFromDownwardPhase: "Object",
      expectedTypes: "Object",
    );

    // Test an instantiation of [1, 2.0, null] with no context.  This should
    // infer as List<?> during downwards inference.
    checkInference(
      typeParametersToInfer: "T extends Object?",
      functionType: "(T, T, T) -> List<T>",
      actualParameterTypes: null,
      returnContextType: null,
      expectedTypes: "UNKNOWN",
    );
    // And upwards inference should refine it to List<num?>.
    checkInference(
      typeParametersToInfer: "T extends Object?",
      functionType: "(T, T, T) -> List<T>",
      actualParameterTypes: "int, double, Null",
      returnContextType: null,
      inferredTypesFromDownwardPhase: "UNKNOWN",
      expectedTypes: "num?",
    );

    // Test an instantiation of legacy [1, 2.0] with no context.
    // This should infer as List<?> during downwards inference.
    checkInference(
      typeParametersToInfer: "T extends Object?",
      functionType: "(T, T) -> List<T>",
      actualParameterTypes: null,
      returnContextType: null,
      expectedTypes: "UNKNOWN",
    );
    checkInference(
      typeParametersToInfer: "T extends Object?",
      functionType: "(T, T) -> List<T>",
      actualParameterTypes: "int, double",
      returnContextType: null,
      inferredTypesFromDownwardPhase: "UNKNOWN",
      expectedTypes: "num",
    );

    // Test an instantiation of [1, 2.0] with no context.  This should infer
    // as List<?> during downwards inference.
    checkInference(
      typeParametersToInfer: "T extends Object",
      functionType: "() -> List<T>",
      actualParameterTypes: null,
      returnContextType: null,
      expectedTypes: "UNKNOWN",
    );
    // And upwards inference should refine it to List<num>.
    checkInference(
      typeParametersToInfer: "T extends Object",
      functionType: "(T, T) -> List<T>",
      actualParameterTypes: "int, double",
      returnContextType: null,
      inferredTypesFromDownwardPhase: "UNKNOWN",
      expectedTypes: "num",
    );

    // Test an instantiation of [1, 2.0] with a context of List<Object>.  This
    // should infer as List<Object> during downwards inference.
    checkInference(
      typeParametersToInfer: "T extends Object",
      functionType: "() -> List<T>",
      actualParameterTypes: null,
      returnContextType: "List<Object>",
      expectedTypes: "Object",
    );
    // And upwards inference should preserve the type.
    checkInference(
      typeParametersToInfer: "T extends Object",
      functionType: "(T, T) -> List<T>",
      actualParameterTypes: "int, double",
      returnContextType: "List<Object>",
      inferredTypesFromDownwardPhase: "Object",
      expectedTypes: "Object",
    );
  }

  void test_inferTypeFromConstraints_applyBound() {
    parseTestLibrary("");

    // Assuming: class A<T extends num> {}

    // TODO(cstefantsova): Test for various nullabilities.

    // With no constraints:
    // Downward inference should infer A<?>
    checkInferenceFromConstraints(
      typeParameter: "T extends num",
      constraints: "",
      downwardsInferPhase: true,
      expected: "UNKNOWN",
    );
    // Upward inference should infer A<num>
    checkInferenceFromConstraints(
      typeParameter: "T extends num",
      constraints: "",
      downwardsInferPhase: false,
      inferredTypeFromDownwardPhase: "UNKNOWN",
      expected: "num",
    );

    // With an upper bound of Object:
    // Downward inference should infer A<num>
    checkInferenceFromConstraints(
      typeParameter: "T extends num",
      constraints: "<: Object",
      downwardsInferPhase: true,
      expected: "num",
    );
    // Upward inference should infer A<num>
    checkInferenceFromConstraints(
      typeParameter: "T extends num",
      constraints: "<: Object",
      downwardsInferPhase: false,
      inferredTypeFromDownwardPhase: "num",
      expected: "num",
    );
    // Upward inference should still infer A<num> even if there are more
    // constraints now, because num was finalized during downward inference.
    checkInferenceFromConstraints(
      typeParameter: "T extends num",
      constraints: ":> int <: int",
      downwardsInferPhase: false,
      inferredTypeFromDownwardPhase: "num",
      expected: "num",
    );
  }

  void test_inferTypeFromConstraints_simple() {
    parseTestLibrary("");

    // TODO(cstefantsova): Test for various nullabilities.

    // With an upper bound of List<?>:
    // Downwards inference should infer List<List<?>>
    checkInferenceFromConstraints(
      typeParameter: "T extends Object?",
      constraints: "<: List<UNKNOWN>",
      downwardsInferPhase: true,
      expected: "List<UNKNOWN>",
    );
    // Upwards inference should refine that to List<List<Object?>>
    checkInferenceFromConstraints(
      typeParameter: "T extends Object?",
      constraints: "<: List<UNKNOWN>",
      downwardsInferPhase: false,
      inferredTypeFromDownwardPhase: "List<UNKNOWN>",
      expected: "List<Object?>",
    );

    // With an upper bound of List<?>:
    // Downwards inference should infer List<List<?>>
    checkInferenceFromConstraints(
      typeParameter: "T extends Object",
      constraints: "<: List<UNKNOWN>",
      downwardsInferPhase: true,
      expected: "List<UNKNOWN>",
    );
    // Upwards inference should refine that to List<List<Object?>>
    checkInferenceFromConstraints(
      typeParameter: "T extends Object",
      constraints: "<: List<UNKNOWN>",
      downwardsInferPhase: false,
      inferredTypeFromDownwardPhase: "List<UNKNOWN>",
      expected: "List<Object?>",
    );
  }

  void test_upper_bound_classic() {
    // Make the class hierarchy:
    //
    // Object
    //   |
    //   A
    //  /|\
    // B C K
    // |X| |
    // D E L
    parseTestLibrary("""
      class A;
      class B implements A;
      class C implements A;
      class K implements A;
      class D implements B, C;
      class E implements B, C;
      class L implements K;
    """);

    // TODO(cstefantsova): Test for various nullabilities.
    checkUpperBound(type1: "B", type2: "E", upperBound: "B");
    checkUpperBound(type1: "D", type2: "C", upperBound: "C");
    checkUpperBound(type1: "D", type2: "E", upperBound: "A");
    checkUpperBound(type1: "D", type2: "A", upperBound: "A");
    checkUpperBound(type1: "B", type2: "K", upperBound: "A");
    checkUpperBound(type1: "B", type2: "L", upperBound: "A");
  }

  void test_upper_bound_commonClass() {
    parseTestLibrary("");

    checkUpperBound(
      type1: "List<int>",
      type2: "List<double>",
      upperBound: "List<num>",
    );
    checkUpperBound(
      type1: "List<int?>",
      type2: "List<double>",
      upperBound: "List<num?>",
    );
  }

  void test_upper_bound_object() {
    parseTestLibrary("");

    checkUpperBound(
      type1: "Object",
      type2: "FutureOr<Function?>",
      upperBound: "Object?",
    );
    checkUpperBound(
      type1: "FutureOr<Function?>",
      type2: "Object",
      upperBound: "Object?",
    );
  }

  void test_upper_bound_function() {
    parseTestLibrary("""
      class A;
      class B extends A;
    """);

    checkUpperBound(
      type1: "() ->? A",
      type2: "() -> B?",
      upperBound: "() ->? A?",
    );
    checkUpperBound(
      type1: "([A]) -> void",
      type2: "(A) -> void",
      upperBound: "Function",
    );
    checkUpperBound(
      type1: "() -> void",
      type2: "(A, B) -> void",
      upperBound: "Function",
    );
    checkUpperBound(
      type1: "(A, B) -> void",
      type2: "() -> void",
      upperBound: "Function",
    );
    checkUpperBound(
      type1: "(A) -> void",
      type2: "(B) -> void",
      upperBound: "(B) -> void",
    );
    checkUpperBound(
      type1: "(B) -> void",
      type2: "(A) -> void",
      upperBound: "(B) -> void",
    );
    checkUpperBound(
      type1: "({A a}) -> void",
      type2: "({B b}) -> void",
      upperBound: "() -> void",
    );
    checkUpperBound(
      type1: "({B b}) -> void",
      type2: "({A a}) -> void",
      upperBound: "() -> void",
    );
    checkUpperBound(
      type1: "({A a, A c}) -> void",
      type2: "({B b, B d}) -> void",
      upperBound: "() -> void",
    );
    checkUpperBound(
      type1: "({A a, B b}) -> void",
      type2: "({B a, A b}) -> void",
      upperBound: "({B a, B b}) -> void",
    );
    checkUpperBound(
      type1: "({B a, A b}) -> void",
      type2: "({A a, B b}) -> void",
      upperBound: "({B a, B b}) -> void",
    );
    checkUpperBound(
      type1: "(B, {A a}) -> void",
      type2: "(B) -> void",
      upperBound: "(B) -> void",
    );
    checkUpperBound(
      type1: "({A a}) -> void",
      type2: "(B) -> void",
      upperBound: "Function",
    );
    checkUpperBound(
      type1: "() -> void",
      type2: "([B]) -> void",
      upperBound: "() -> void",
    );
    checkUpperBound(
      type1: "<X>() -> void",
      type2: "<Y>() -> void",
      upperBound: "<Z>() -> void",
    );
    checkUpperBound(
      type1: "<X>(X) -> List<X>",
      type2: "<Y>(Y) -> List<Y>",
      upperBound: "<Z>(Z) -> List<Z>",
    );
    checkUpperBound(
      type1: "<X1, X2 extends List<X1>>(X1) -> X2",
      type2: "<Y1, Y2 extends List<Y1>>(Y1) -> Y2",
      upperBound: "<Z1, Z2 extends List<Z1>>(Z1) -> Z2",
    );
    checkUpperBound(
      type1: "<X extends int>() -> void",
      type2: "<Y extends double>() -> void",
      upperBound: "Function",
    );

    checkUpperBound(
      type1: "({required A a, B b}) -> A",
      type2: "({B a, required A b}) -> B",
      upperBound: "({required B a, required B b}) -> A",
    );

    checkUpperBound(
      type1: "<X extends dynamic>() -> void",
      type2: "<Y extends Object?>() -> void",
      upperBound: "<Z extends dynamic>() -> void",
    );
    checkUpperBound(
      type1: "<X extends Null>() -> void",
      type2: "<Y extends Never?>() -> void",
      upperBound: "<Z extends Null>() -> void",
    );
    checkUpperBound(
      type1: "<X extends FutureOr<dynamic>?>() -> void",
      type2: "<Y extends FutureOr<Object?>>() -> void",
      upperBound: "<Z extends FutureOr<dynamic>?>() -> void",
    );

    checkUpperBound(
      type1: "([dynamic]) -> dynamic",
      type2: "([dynamic]) -> dynamic",
      upperBound: "([dynamic]) -> dynamic",
    );
  }

  void test_upper_bound_record() {
    parseTestLibrary("""
      class A;
      class B extends A;
    """);

    checkUpperBound(type1: "(A, B)", type2: "(B, A)", upperBound: "(A, A)");
    checkUpperBound(
      type1: "(A, {B b})",
      type2: "(B, {A b})",
      upperBound: "(A, {A b})",
    );
    checkUpperBound(
      type1: "(A, {(B, {A a}) b})",
      type2: "(B, {(A, {B a}) b})",
      upperBound: "(A, {(A, {A a}) b})",
    );
    checkUpperBound(type1: "(A?, B)", type2: "(B, A?)", upperBound: "(A?, A?)");
    checkUpperBound(type1: "(A, B?)", type2: "(B?, A)", upperBound: "(A?, A?)");

    checkUpperBound(type1: "(A, A)", type2: "(A, A, A)", upperBound: "Record");
    checkUpperBound(type1: "(A, A)", type2: "(A, {A a})", upperBound: "Record");
    checkUpperBound(type1: "({A a})", type2: "(A, A)", upperBound: "Record");
    checkUpperBound(
      type1: "({A a, B b})",
      type2: "({A a})",
      upperBound: "Record",
    );

    checkUpperBound(type1: "(A, B)", type2: "Record", upperBound: "Record");
    checkUpperBound(type1: "Record", type2: "(A, B)", upperBound: "Record");

    checkUpperBound(
      type1: "(A, B)",
      type2: "(A, B) -> void",
      upperBound: "Object",
    );
    checkUpperBound(type1: "Record", type2: "A", upperBound: "Object");
  }

  void test_upper_bound_identical() {
    parseTestLibrary("class A;");

    checkUpperBound(type1: "A", type2: "A", upperBound: "A");
    checkUpperBound(type1: "A", type2: "A?", upperBound: "A?");

    checkUpperBound(type1: "A?", type2: "A", upperBound: "A?");
    checkUpperBound(type1: "A?", type2: "A?", upperBound: "A?");
  }

  void test_upper_bound_sameClass() {
    parseTestLibrary("""
      class A;
      class B extends A;
      class Pair<X, Y>;
    """);

    checkUpperBound(
      type1: "Pair<A, B>",
      type2: "Pair<B, A>",
      upperBound: "Pair<A, A>",
    );
    checkUpperBound(
      type1: "Pair<A, B>",
      type2: "Pair<B?, A>",
      upperBound: "Pair<A?, A>",
    );
    checkUpperBound(
      type1: "Pair<A?, B?>",
      type2: "Pair<B, A>",
      upperBound: "Pair<A?, A?>",
    );
  }

  void test_upper_bound_subtype() {
    parseTestLibrary("""
      class A;
      class B extends A;
    """);

    // UP(T1, T2) = T2 if T1 <: T2
    //   Note that both types must be class types at this point
    checkUpperBound(
      type1: "List<B>",
      type2: "Iterable<A>",
      upperBound: "Iterable<A>",
    );
    checkUpperBound(
      type1: "List<B>",
      type2: "Iterable<A?>",
      upperBound: "Iterable<A?>",
    );
    checkUpperBound(
      type1: "List<B>",
      type2: "Iterable<A>?",
      upperBound: "Iterable<A>?",
    );
    checkUpperBound(
      type1: "List<B>?",
      type2: "Iterable<A>",
      upperBound: "Iterable<A>?",
    );
    checkUpperBound(
      type1: "List<B>?",
      type2: "Iterable<A>?",
      upperBound: "Iterable<A>?",
    );

    // UP(T1, T2) = T2 if T1 <: T2
    //   Note that both types must be class types at this point
    checkUpperBound(
      type1: "List<B?>",
      type2: "Iterable<A?>",
      upperBound: "Iterable<A?>",
    );

    // UP(C0<T0, ..., Tn>, C1<S0, ..., Sk>)
    //     = least upper bound of two interfaces as in Dart 1.
    checkUpperBound(
      type1: "List<B?>",
      type2: "Iterable<A>",
      upperBound: "Object",
    );

    // UP(T1, T2) = T1 if T2 <: T1
    //   Note that both types must be class types at this point
    checkUpperBound(
      type1: "Iterable<A>",
      type2: "List<B>",
      upperBound: "Iterable<A>",
    );
    checkUpperBound(
      type1: "Iterable<A>",
      type2: "List<B?>",
      upperBound: "Object",
    );
    checkUpperBound(
      type1: "Iterable<A>",
      type2: "List<B>?",
      upperBound: "Iterable<A>?",
    );

    // UP(T1, T2) = T1 if T2 <: T1
    //   Note that both types must be class types at this point
    checkUpperBound(
      type1: "Iterable<A?>",
      type2: "List<B>",
      upperBound: "Iterable<A?>",
    );
    checkUpperBound(
      type1: "Iterable<A?>",
      type2: "List<B?>",
      upperBound: "Iterable<A?>",
    );
    checkUpperBound(
      type1: "Iterable<A>?",
      type2: "List<B>",
      upperBound: "Iterable<A>?",
    );
    checkUpperBound(
      type1: "Iterable<A>?",
      type2: "List<B>?",
      upperBound: "Iterable<A>?",
    );
  }

  void test_upper_bound_top() {
    parseTestLibrary("class A;");

    // UP(T1, T2) where TOP(T1) and TOP(T2) =
    //   T1 if MORETOP(T1, T2)
    //   T2 otherwise
    for (String t1 in topPredicateEnumeration.keys) {
      for (String t2 in topPredicateEnumeration.keys) {
        String? typeParameters = joinTypeParameters(
          topPredicateEnumeration[t1],
          topPredicateEnumeration[t2],
        );
        typeParserEnvironment.withTypeParameters(typeParameters, (_) {
          String expected =
              typeSchemaEnvironment.moretop(parseType(t1), parseType(t2))
              ? t1
              : t2;
          checkUpperBound(
            type1: t1,
            type2: t2,
            upperBound: expected,
            typeParameters: typeParameters,
          );
        });
      }
    }

    // UP(T1, T2) = T1 if TOP(T1)
    for (String t1 in topPredicateEnumeration.keys) {
      for (String t2 in ["A", "A?"]) {
        checkUpperBound(
          type1: t1,
          type2: t2,
          upperBound: t1,
          typeParameters: topPredicateEnumeration[t1],
        );
      }
    }

    // UP(T1, T2) = T2 if TOP(T2)
    for (String t1 in ["A", "A?"]) {
      for (String t2 in topPredicateEnumeration.keys) {
        checkUpperBound(
          type1: t1,
          type2: t2,
          upperBound: t2,
          typeParameters: topPredicateEnumeration[t2],
        );
      }
    }

    // UP(T1, T2) where OBJECT(T1) and OBJECT(T2) =
    //   T1 if MORETOP(T1, T2)
    //   T2 otherwise
    for (String t1 in objectPredicateEnumeration.keys) {
      for (String t2 in objectPredicateEnumeration.keys) {
        String? typeParameters = joinTypeParameters(
          objectPredicateEnumeration[t1],
          objectPredicateEnumeration[t2],
        );
        typeParserEnvironment.withTypeParameters(typeParameters, (_) {
          String expected =
              typeSchemaEnvironment.moretop(parseType(t1), parseType(t2))
              ? t1
              : t2;
          checkUpperBound(
            type1: t1,
            type2: t2,
            upperBound: expected,
            typeParameters: typeParameters,
          );
        });
      }
    }

    // UP(T1, T2) where OBJECT(T1) =
    //   T1 if T2 is non-nullable
    //   T1? otherwise
    for (String t1 in objectPredicateEnumeration.keys) {
      checkUpperBound(
        type1: t1,
        type2: "A?",
        upperBound: "${t1}?",
        typeParameters: objectPredicateEnumeration[t1],
      );
      checkUpperBound(type1: t1, type2: "A", upperBound: t1);
    }

    // UP(T1, T2) where OBJECT(T2) =
    //   T2 if T1 is non-nullable
    //   T2? otherwise
    for (String t2 in objectPredicateEnumeration.keys) {
      checkUpperBound(type1: "A?", type2: t2, upperBound: "${t2}?");
      checkUpperBound(type1: "A", type2: t2, upperBound: t2);
    }
  }

  void test_upper_bound_bottom() {
    parseTestLibrary("class A;");

    // UP(T1, T2) where BOTTOM(T1) and BOTTOM(T2) =
    //   T2 if MOREBOTTOM(T1, T2)
    //   T1 otherwise
    for (String t1 in bottomPredicateEnumeration.keys) {
      for (String t2 in bottomPredicateEnumeration.keys) {
        String? typeParameters = joinTypeParameters(
          bottomPredicateEnumeration[t1],
          bottomPredicateEnumeration[t2],
        );
        typeParserEnvironment.withTypeParameters(typeParameters, (_) {
          String expected =
              typeSchemaEnvironment.morebottom(parseType(t1), parseType(t2))
              ? t2
              : t1;
          checkUpperBound(
            type1: t1,
            type2: t2,
            upperBound: expected,
            typeParameters: typeParameters,
          );
        });
      }
    }

    // UP(T1, T2) = T2 if BOTTOM(T1)
    for (String t1 in bottomPredicateEnumeration.keys) {
      for (String t2 in ["A", "A?"]) {
        checkUpperBound(
          type1: t1,
          type2: t2,
          upperBound: t2,
          typeParameters: bottomPredicateEnumeration[t1],
        );
      }
    }

    // UP(T1, T2) = T1 if BOTTOM(T2)
    for (String t1 in ["A", "A?"]) {
      for (String t2 in bottomPredicateEnumeration.keys) {
        checkUpperBound(
          type1: t1,
          type2: t2,
          upperBound: t1,
          typeParameters: bottomPredicateEnumeration[t2],
        );
      }
    }

    // UP(T1, T2) where NULL(T1) and NULL(T2) =
    //   T2 if MOREBOTTOM(T1, T2)
    //   T1 otherwise
    for (String t1 in nullPredicateEnumeration.keys) {
      for (String t2 in nullPredicateEnumeration.keys) {
        String? typeParameters = joinTypeParameters(
          nullPredicateEnumeration[t1],
          nullPredicateEnumeration[t2],
        );
        typeParserEnvironment.withTypeParameters(typeParameters, (_) {
          String expected =
              typeSchemaEnvironment.morebottom(parseType(t1), parseType(t2))
              ? t2
              : t1;
          checkUpperBound(
            type1: t1,
            type2: t2,
            upperBound: expected,
            typeParameters: typeParameters,
          );
        });
      }
    }

    // UP(T1, T2) where NULL(T1) =
    //   T2 if T2 is nullable
    //   T2? otherwise
    for (String t1 in nullPredicateEnumeration.keys) {
      checkUpperBound(
        type1: t1,
        type2: "A",
        upperBound: "A?",
        typeParameters: nullPredicateEnumeration[t1],
      );
      checkUpperBound(
        type1: t1,
        type2: "A?",
        upperBound: "A?",
        typeParameters: nullPredicateEnumeration[t1],
      );
    }

    // UP(T1, T2) where NULL(T2) =
    //   T1 if T1 is nullable
    //   T1? otherwise
    for (String t2 in nullPredicateEnumeration.keys) {
      checkUpperBound(
        type1: "A",
        type2: t2,
        upperBound: "A?",
        typeParameters: nullPredicateEnumeration[t2],
      );
      checkUpperBound(
        type1: "A?",
        type2: t2,
        upperBound: "A?",
        typeParameters: nullPredicateEnumeration[t2],
      );
    }
  }

  void test_upper_bound_typeParameter() {
    parseTestLibrary("");

    // TODO(cstefantsova): Test for various nullabilities.
    checkUpperBound(
      type1: "T",
      type2: "T",
      upperBound: "T",
      typeParameters: "T extends Object",
    );
    checkUpperBound(
      type1: "T",
      type2: "List<Never>",
      upperBound: "List<Object?>",
      typeParameters: "T extends List<T>",
    );
    checkUpperBound(
      type1: "List<Never>",
      type2: "T",
      upperBound: "List<Object?>",
      typeParameters: "T extends List<T>",
    );
    checkUpperBound(
      type1: "T",
      type2: "U",
      upperBound: "List<Object?>",
      typeParameters: "T extends List<T>, U extends List<Never>",
    );
    checkUpperBound(
      type1: "U",
      type2: "T",
      upperBound: "List<Object?>",
      typeParameters: "T extends List<T>, U extends List<Never>",
    );
    checkUpperBound(
      type1: "T",
      type2: "T",
      upperBound: "T",
      typeParameters: "T extends Object?",
    );

    // These cases are observed through `a ?? b`. Here the resulting type
    // is `UP(NonNull(a), b)`, where `NonNull(a)` is an intersection type
    // `T & S`. In this case `b` is `null`. We have neither `Null <: T`
    // nor `T <: Null`, so the result is `Up(S, Null)`.

    // We have
    //
    //     NonNull(T extends Object?) = T & Object
    //
    // resulting in
    //
    //     Up(Object, Null) = Object?
    //
    checkUpperBound(
      type1: "T",
      type2: "Null",
      upperBound: "Object?",
      typeParameters: "T extends Object?",
      nonNull1: true,
    );

    // We have
    //
    //     NonNull(T extends bool?) = T & bool
    //
    // resulting in
    //
    //     Up(bool, Null) = bool?
    //
    checkUpperBound(
      type1: "T",
      type2: "Null",
      upperBound: "bool?",
      typeParameters: "T extends bool?",
      nonNull1: true,
    );

    // We have
    //
    //     NonNull(T extends bool) = T
    //
    // resulting in
    //
    //     Up(T, Null) = T?
    //
    checkUpperBound(
      type1: "T",
      type2: "Null",
      upperBound: "T?",
      typeParameters: "T extends bool",
      nonNull1: true,
    );
  }

  void test_upper_bound_unknown() {
    parseTestLibrary("class A;");

    checkLowerBound(type1: "A", type2: "UNKNOWN", lowerBound: "A");
    checkLowerBound(type1: "A?", type2: "UNKNOWN", lowerBound: "A?");

    checkLowerBound(type1: "UNKNOWN", type2: "A", lowerBound: "A");
    checkLowerBound(type1: "UNKNOWN", type2: "A?", lowerBound: "A?");
  }

  void test_upper_bound_extension_type() {
    parseTestLibrary(
      "extension type E1(Object? it); "
      "extension type E2(Object it);"
      "extension type E3<X>(X it); "
      "extension type E4(Object it) implements Object; "
      "extension type E5<X extends Object>(X it) implements Object;",
    );
    checkUpperBound(type1: "E1", type2: "E1", upperBound: "E1");
    checkUpperBound(type1: "E2", type2: "E2", upperBound: "E2");
    checkUpperBound(type1: "E1", type2: "E2", upperBound: "Object?");
    checkUpperBound(type1: "E1", type2: "E3<Object?>", upperBound: "Object?");
    checkUpperBound(type1: "E1", type2: "E3<num?>", upperBound: "Object?");
    checkUpperBound(type1: "E2", type2: "E3<Object?>", upperBound: "Object?");
    checkUpperBound(type1: "E2", type2: "E3<num?>", upperBound: "Object?");
    checkUpperBound(type1: "E2", type2: "E3<Object>", upperBound: "Object?");
    checkUpperBound(type1: "E4", type2: "E5<Object>", upperBound: "Object");
  }

  void test_upper_bound_extension_type_implements() {
    parseTestLibrary(
      "extension type E1(int it) implements num; "
      "extension type E2(double it) implements double; "
      "extension type E3<X extends num>(X it) implements num; "
      "extension type E4<X extends num>(X it) implements E3<X>; "
      "extension type E5(num? it); "
      "extension type E6(num? it) implements E5; "
      "extension type E7(String it) implements String; "
      "extension type E8(bool it); "
      "extension type E9(int it) implements E6; "
      "extension type E10(double it) implements E5; "
      "extension type E11<X>(X it); "
      "extension type E12(bool it) implements Object;",
    );
    checkUpperBound(type1: "E1", type2: "E2", upperBound: "num");
    checkUpperBound(type1: "E1", type2: "E3<int>", upperBound: "num");
    checkUpperBound(type1: "E2", type2: "E3<double>", upperBound: "num");
    checkUpperBound(type1: "E1", type2: "E4<int>", upperBound: "num");
    checkUpperBound(type1: "E2", type2: "E4<double>", upperBound: "num");
    checkUpperBound(type1: "E1", type2: "E5", upperBound: "Object?");
    checkUpperBound(type1: "E2", type2: "E5", upperBound: "Object?");
    checkUpperBound(type1: "E1", type2: "E6", upperBound: "Object?");
    checkUpperBound(type1: "E2", type2: "E6", upperBound: "Object?");
    checkUpperBound(type1: "E1", type2: "E7", upperBound: "Object");
    checkUpperBound(type1: "E1", type2: "E8", upperBound: "Object?");
    checkUpperBound(type1: "E1", type2: "E12", upperBound: "Object");
    checkUpperBound(type1: "E6", type2: "E9", upperBound: "E6");
    checkUpperBound(type1: "E5", type2: "E9", upperBound: "E5");
    checkUpperBound(type1: "E5", type2: "E6", upperBound: "E5");
    checkUpperBound(type1: "E1", type2: "E1?", upperBound: "E1?");
    checkUpperBound(type1: "E6?", type2: "E9", upperBound: "E6?");
    checkUpperBound(type1: "E6", type2: "E9?", upperBound: "E6?");
    checkUpperBound(type1: "E6", type2: "E10", upperBound: "E5");
    checkUpperBound(type1: "E5", type2: "E10", upperBound: "E5");
    checkUpperBound(type1: "E6?", type2: "E10", upperBound: "E5?");
    checkUpperBound(type1: "E6", type2: "E10?", upperBound: "E5?");
    checkUpperBound(
      type1: "E11<num>",
      type2: "E11<num?>",
      upperBound: "E11<num?>",
    );
    checkUpperBound(
      type1: "E11<int>",
      type2: "E11<String>",
      upperBound: "E11<Object>",
    );
  }

  void test_upper_bound_extension_and_interface_types() {
    parseTestLibrary(
      "class A<X>; class B implements A<String>;"
      "extension type E1(num? it); "
      "extension type E2(num it); "
      "extension type E3(num? it) implements E1; "
      "extension type E4(num it) implements num; "
      "extension type E5<Y extends Object>(Y it) implements A<Y>; "
      "extension type E6(num it) implements Object;",
    );
    checkUpperBound(type1: "E1", type2: "num?", upperBound: "Object?");
    checkUpperBound(type1: "E1", type2: "num", upperBound: "Object?");
    checkUpperBound(type1: "E1", type2: "int?", upperBound: "Object?");
    checkUpperBound(type1: "E1", type2: "int", upperBound: "Object?");

    checkUpperBound(type1: "E2", type2: "num?", upperBound: "Object?");
    checkUpperBound(type1: "E2", type2: "num", upperBound: "Object?");
    checkUpperBound(type1: "E6", type2: "num", upperBound: "Object");
    checkUpperBound(type1: "E2", type2: "int?", upperBound: "Object?");
    checkUpperBound(type1: "E2", type2: "int", upperBound: "Object?");
    checkUpperBound(type1: "E6", type2: "int", upperBound: "Object");

    checkUpperBound(type1: "E3", type2: "num?", upperBound: "Object?");
    checkUpperBound(type1: "E3", type2: "num", upperBound: "Object?");
    checkUpperBound(type1: "E3", type2: "int?", upperBound: "Object?");
    checkUpperBound(type1: "E3", type2: "int", upperBound: "Object?");

    checkUpperBound(type1: "E4", type2: "num?", upperBound: "num?");
    checkUpperBound(type1: "E4", type2: "num", upperBound: "num");
    checkUpperBound(type1: "E4", type2: "int?", upperBound: "num?");
    checkUpperBound(type1: "E4", type2: "int", upperBound: "num");

    checkUpperBound(type1: "E4?", type2: "num?", upperBound: "num?");
    checkUpperBound(type1: "E4?", type2: "num", upperBound: "num?");
    checkUpperBound(type1: "E4?", type2: "int?", upperBound: "num?");
    checkUpperBound(type1: "E4?", type2: "int", upperBound: "num?");

    checkUpperBound(
      type1: "E5<String>",
      type2: "A<String?>",
      upperBound: "A<String?>",
    );
    checkUpperBound(
      type1: "E5<String>",
      type2: "A<String>",
      upperBound: "A<String>",
    );
    checkUpperBound(
      type1: "E5<String>",
      type2: "A<Object?>",
      upperBound: "A<Object?>",
    );
    checkUpperBound(
      type1: "E5<String>",
      type2: "A<Object>",
      upperBound: "A<Object>",
    );
    checkUpperBound(type1: "E5<String>", type2: "B", upperBound: "A<String>");

    checkUpperBound(
      type1: "E5<String>?",
      type2: "A<String?>",
      upperBound: "A<String?>?",
    );
    checkUpperBound(
      type1: "E5<String>?",
      type2: "A<String>",
      upperBound: "A<String>?",
    );
    checkUpperBound(
      type1: "E5<String>?",
      type2: "A<Object?>",
      upperBound: "A<Object?>?",
    );
    checkUpperBound(
      type1: "E5<String>?",
      type2: "A<Object>",
      upperBound: "A<Object>?",
    );
    checkUpperBound(type1: "E5<String>?", type2: "B", upperBound: "A<String>?");
  }

  void test_typeShapeCheckSufficiency() {
    parseTestLibrary("""
      class A<X>;
      class B extends A<int>;
      class C<Y> extends B;

      class D<X>;
      class E<Y> extends D<Y>;

      class F<X>;
      class G<Y, Z> extends F<Y>;
    """);

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "A<int>",
      checkTargetType: "C<int>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "A<int>",
      checkTargetType: "C<String>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "A<int>",
      checkTargetType: "C<dynamic>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "B",
      checkTargetType: "C<int>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "B",
      checkTargetType: "C<Object?>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int>",
      checkTargetType: "E<int>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int>",
      checkTargetType: "E<num>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int>",
      checkTargetType: "E<dynamic>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<num>",
      checkTargetType: "E<int>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<int, String>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<num, String>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<dynamic, Object?>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<int, Object?>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<num, Object?>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int,)",
      checkTargetType: "(dynamic,)",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.recordShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int,)",
      checkTargetType: "(num,)",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.recordShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int,)",
      checkTargetType: "(String,)",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int, {String foo})",
      checkTargetType: "(dynamic, {dynamic foo})",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.recordShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int, {String foo})",
      checkTargetType: "(dynamic, {String foo})",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.recordShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int, {String foo})",
      checkTargetType: "(dynamic, {bool foo})",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int, {String foo})",
      checkTargetType: "(dynamic, {String bar})",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int) -> void",
      checkTargetType: "(Never) -> void",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.functionShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(num) -> String",
      checkTargetType: "(int) -> Object",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.functionShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int) -> bool",
      checkTargetType: "(String) -> dynamic",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(dynamic, {dynamic foo}) -> void",
      checkTargetType: "(int, {String foo}) -> void",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.functionShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(dynamic, {String foo}) -> Object?",
      checkTargetType: "(bool, {String foo}) -> dynamic",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.functionShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(dynamic, {bool foo}) -> Never?",
      checkTargetType: "(int, {String foo}) -> Null",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(dynamic, {String foo}) -> Null",
      checkTargetType: "(int, {String bar}) -> Null",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "FutureOr<String>",
      checkTargetType: "FutureOr<Object?>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.futureOrShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "FutureOr<String>",
      checkTargetType: "FutureOr<Object>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.futureOrShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "FutureOr<int>",
      checkTargetType: "FutureOr<num>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.futureOrShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "FutureOr<bool>",
      checkTargetType: "FutureOr<String>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "int",
      checkTargetType: "(String,)",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "int",
      checkTargetType: "(num) -> void",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "bool",
      checkTargetType: "FutureOr<void>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int,)",
      checkTargetType: "String",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int,)",
      checkTargetType: "(num) -> void",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(bool,)",
      checkTargetType: "FutureOr<void>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int) -> void",
      checkTargetType: "String",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(int) -> void",
      checkTargetType: "(num,)",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "(bool) -> FutureOr<Object?>",
      checkTargetType: "FutureOr<void>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "A<int>",
      checkTargetType: "C<int>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "A<int>",
      checkTargetType: "C<String>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "A<int>",
      checkTargetType: "C<dynamic>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "A<int>?",
      checkTargetType: "C<dynamic>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "B",
      checkTargetType: "C<int>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "B?",
      checkTargetType: "C<Object?>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "B",
      checkTargetType: "C<Object?>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int>",
      checkTargetType: "E<int>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int>?",
      checkTargetType: "E<int>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int>",
      checkTargetType: "E<num>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int>?",
      checkTargetType: "E<num>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int>",
      checkTargetType: "E<dynamic>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int>?",
      checkTargetType: "E<dynamic>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<num>",
      checkTargetType: "E<int>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<num>?",
      checkTargetType: "E<int>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );

    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<int, String>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>?",
      checkTargetType: "G<int, String>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<num, String>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>?",
      checkTargetType: "G<num, String>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<dynamic, Object?>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>?",
      checkTargetType: "G<dynamic, Object?>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<int, Object?>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>?",
      checkTargetType: "G<int, Object?>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>",
      checkTargetType: "G<num, Object?>?",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "F<int>?",
      checkTargetType: "G<num, Object?>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.interfaceShape,
    );
    checkTypeShapeCheckSufficiency(
      expressionStaticType: "D<int?>",
      checkTargetType: "E<int>",
      typeParameters: "",
      sufficiency: TypeShapeCheckSufficiency.insufficient,
    );
  }

  void checkUpperBound({
    required String type1,
    required String type2,
    required String upperBound,
    String? typeParameters,
    bool nonNull1 = false,
    bool nonNull2 = false,
  }) {
    typeParserEnvironment.withTypeParameters(typeParameters, (
      List<TypeParameter> typeParameterNodes,
    ) {
      DartType dartType1 = parseType(type1);
      DartType dartType2 = parseType(type2);
      if (nonNull1) {
        dartType1 = dartType1.toNonNull();
      }
      if (nonNull2) {
        dartType2 = dartType2.toNonNull();
      }
      expect(
        typeSchemaEnvironment.getStandardUpperBound(dartType1, dartType2),
        parseType(upperBound),
      );
    });
  }
}
