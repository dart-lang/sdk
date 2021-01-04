// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/testing/type_parser_environment.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeSchemaEnvironmentTest);
  });
}

@reflectiveTest
class TypeSchemaEnvironmentTest {
  Env typeParserEnvironment;
  TypeSchemaEnvironment typeSchemaEnvironment;

  final Map<String, DartType Function()> additionalTypes = {
    "UNKNOWN": () => new UnknownType(),
    "BOTTOM": () => new BottomType(),
  };

  Library _coreLibrary;
  Library _testLibrary;

  Library get coreLibrary => _coreLibrary;
  Library get testLibrary => _testLibrary;

  Component get component => typeParserEnvironment.component;
  CoreTypes get coreTypes => typeParserEnvironment.coreTypes;

  void parseTestLibrary(String testLibraryText) {
    typeParserEnvironment =
        new Env(testLibraryText, isNonNullableByDefault: false);
    typeSchemaEnvironment = new TypeSchemaEnvironment(
        coreTypes, new ClassHierarchy(component, coreTypes));
    assert(
        typeParserEnvironment.component.libraries.length == 2,
        "The tests are supposed to have exactly two libraries: "
        "the core library and the test library.");
    Library firstLibrary = typeParserEnvironment.component.libraries.first;
    Library secondLibrary = typeParserEnvironment.component.libraries.last;
    if (firstLibrary.importUri.scheme == "dart" &&
        firstLibrary.importUri.path == "core") {
      _coreLibrary = firstLibrary;
      _testLibrary = secondLibrary;
    } else {
      assert(
          secondLibrary.importUri.scheme == "dart" &&
              secondLibrary.importUri.path == "core",
          "One of the libraries is expected to be 'dart:core'.");
      _coreLibrary == secondLibrary;
      _testLibrary = firstLibrary;
    }
  }

  void test_addLowerBound() {
    parseTestLibrary("class A; class B extends A; class C extends A;");
    checkConstraintLowerBound(constraint: "", bound: "UNKNOWN");
    checkConstraintLowerBound(constraint: ":> B*", bound: "B*");
    checkConstraintLowerBound(constraint: ":> B* :> C*", bound: "A*");
  }

  void test_addUpperBound() {
    parseTestLibrary("class A; class B extends A; class C extends A;");
    checkConstraintUpperBound(constraint: "", bound: "UNKNOWN");
    checkConstraintUpperBound(constraint: "<: A*", bound: "A*");
    checkConstraintUpperBound(constraint: "<: A* <: B*", bound: "B*");
    checkConstraintUpperBound(constraint: "<: A* <: B* <: C*", bound: "BOTTOM");
  }

  void test_glb_bottom() {
    parseTestLibrary("class A;");
    checkLowerBound(type1: "Null", type2: "A*", lowerBound: "Null");
    checkLowerBound(type1: "A*", type2: "Null", lowerBound: "Null");
  }

  void test_glb_function() {
    parseTestLibrary("class A; class B extends A;");

    // GLB(() -> A, () -> B) = () -> B
    checkLowerBound(
        type1: "() ->* A*", type2: "() ->* B*", lowerBound: "() ->* B*");

    // GLB(() -> void, (A, B) -> void) = ([A, B]) -> void
    checkLowerBound(
        type1: "() ->* void",
        type2: "(A*, B*) ->* void",
        lowerBound: "([A*, B*]) ->* void");
    checkLowerBound(
        type1: "(A*, B*) ->* void",
        type2: "() ->* void",
        lowerBound: "([A*, B*]) ->* void");

    // GLB((A) -> void, (B) -> void) = (A) -> void
    checkLowerBound(
        type1: "(A*) ->* void",
        type2: "(B*) ->* void",
        lowerBound: "(A*) ->* void");
    checkLowerBound(
        type1: "(B*) ->* void",
        type2: "(A*) ->* void",
        lowerBound: "(A*) ->* void");

    // GLB(({a: A}) -> void, ({b: B}) -> void) = ({a: A, b: B}) -> void
    checkLowerBound(
        type1: "({A* a}) ->* void",
        type2: "({B* b}) ->* void",
        lowerBound: "({A* a, B* b}) ->* void");
    checkLowerBound(
        type1: "({B* b}) ->* void",
        type2: "({A* a}) ->* void",
        lowerBound: "({A* a, B* b}) ->* void");

    // GLB(({a: A, c: A}) -> void, ({b: B, d: B}) -> void)
    //     = ({a: A, b: B, c: A, d: B}) -> void
    checkLowerBound(
        type1: "({A* a, A* c}) ->* void",
        type2: "({B* b, B* d}) ->* void",
        lowerBound: "({A* a, B* b, A* c, B* d}) ->* void");

    // GLB(({a: A, b: B}) -> void, ({a: B, b: A}) -> void)
    //     = ({a: A, b: A}) -> void
    checkLowerBound(
        type1: "({A* a, B* b}) ->* void",
        type2: "({B* a, A* b}) ->* void",
        lowerBound: "({A* a, A* b}) ->* void");
    checkLowerBound(
        type1: "({B* a, A* b}) ->* void",
        type2: "({A* a, B* b}) ->* void",
        lowerBound: "({A* a, A* b}) ->* void");

    // GLB((B, {a: A}) -> void, (B) -> void) = (B, {a: A}) -> void
    checkLowerBound(
        type1: "(B*, {A* a}) ->* void",
        type2: "(B*) ->* void",
        lowerBound: "(B*, {A* a}) ->* void");

    // GLB(({a: A}) -> void, (B) -> void) = bottom
    checkLowerBound(
        type1: "({A* a}) ->* void",
        type2: "(B*) ->* void",
        lowerBound: "BOTTOM");

    // GLB(({a: A}) -> void, ([B]) -> void) = bottom
    checkLowerBound(
        type1: "({A* a}) ->* void",
        type2: "([B*]) ->* void",
        lowerBound: "BOTTOM");
  }

  void test_glb_identical() {
    parseTestLibrary("class A;");
    checkLowerBound(type1: "A*", type2: "A*", lowerBound: "A*");
  }

  void test_glb_subtype() {
    parseTestLibrary("class A; class B extends A;");

    checkLowerBound(type1: "A*", type2: "B*", lowerBound: "B*");
    checkLowerBound(type1: "B*", type2: "A*", lowerBound: "B*");
  }

  void test_glb_top() {
    parseTestLibrary("class A;");
    checkLowerBound(type1: "dynamic", type2: "A*", lowerBound: "A*");
    checkLowerBound(type1: "A*", type2: "dynamic", lowerBound: "A*");
    checkLowerBound(type1: "Object*", type2: "A*", lowerBound: "A*");
    checkLowerBound(type1: "A*", type2: "Object*", lowerBound: "A*");
    checkLowerBound(type1: "void", type2: "A*", lowerBound: "A*");
    checkLowerBound(type1: "A*", type2: "void", lowerBound: "A*");
  }

  void test_glb_unknown() {
    parseTestLibrary("class A;");
    checkLowerBound(type1: "A*", type2: "UNKNOWN", lowerBound: "A*");
    checkLowerBound(type1: "UNKNOWN", type2: "A*", lowerBound: "A*");
  }

  void test_glb_unrelated() {
    parseTestLibrary("class A; class B;");
    checkLowerBound(type1: "A*", type2: "B*", lowerBound: "BOTTOM");
  }

  void test_inferGenericFunctionOrType() {
    parseTestLibrary("");

    // Test an instantiation of [1, 2.0] with no context.  This should infer
    // as List<?> during downwards inference.
    checkInference(
        typeParametersToInfer: "T extends Object*",
        functionType: "() ->* List<T*>*",
        actualParameterTypes: null,
        returnContextType: null,
        expectedTypes: "UNKNOWN");
    // And upwards inference should refine it to List<num>.
    checkInference(
        typeParametersToInfer: "T extends Object*",
        functionType: "(T*, T*) ->* List<T*>*",
        actualParameterTypes: "int*, double*",
        returnContextType: null,
        inferredTypesFromDownwardPhase: "UNKNOWN",
        expectedTypes: "num*");

    // Test an instantiation of [1, 2.0] with a context of List<Object>.  This
    // should infer as List<Object> during downwards inference.
    checkInference(
        typeParametersToInfer: "T extends Object*",
        functionType: "() ->* List<T*>*",
        actualParameterTypes: null,
        returnContextType: "List<Object*>*",
        expectedTypes: "Object*");
    // And upwards inference should preserve the type.
    checkInference(
        typeParametersToInfer: "T extends Object*",
        functionType: "(T*, T*) ->* List<T>",
        actualParameterTypes: "int*, double*",
        returnContextType: "List<Object*>*",
        inferredTypesFromDownwardPhase: "Object*",
        expectedTypes: "Object*");
  }

  void test_inferTypeFromConstraints_applyBound() {
    parseTestLibrary("");

    // With no constraints:
    // Downward inference should infer '?'
    checkInferenceFromConstraints(
        typeParameter: "T extends num*",
        constraints: "",
        downwardsInferPhase: true,
        expected: "UNKNOWN");
    // Upward inference should infer num
    checkInferenceFromConstraints(
        typeParameter: "T extends num*",
        constraints: "",
        downwardsInferPhase: false,
        inferredTypeFromDownwardPhase: "UNKNOWN",
        expected: "num*");

    // With an upper bound of Object:
    // Downward inference should infer num.
    checkInferenceFromConstraints(
        typeParameter: "T extends num*",
        constraints: "<: Object*",
        downwardsInferPhase: true,
        expected: "num*");
    // Upward inference should infer num.
    checkInferenceFromConstraints(
        typeParameter: "T extends num*",
        constraints: "<: Object*",
        downwardsInferPhase: false,
        inferredTypeFromDownwardPhase: "num*",
        expected: "num*");
    // Upward inference should still infer num even if there are more
    // constraints now, because num was finalized during downward inference.
    checkInferenceFromConstraints(
        typeParameter: "T extends num*",
        constraints: ":> int* <: int*",
        downwardsInferPhase: false,
        inferredTypeFromDownwardPhase: "num*",
        expected: "num*");
  }

  void test_inferTypeFromConstraints_simple() {
    parseTestLibrary("");

    // With an upper bound of List<?>:
    // Downwards inference should infer List<List<?>>
    checkInferenceFromConstraints(
        typeParameter: "T extends Object*",
        constraints: "<: List<UNKNOWN>*",
        downwardsInferPhase: true,
        expected: "List<UNKNOWN>*");
    // Upwards inference should refine that to List<List<dynamic>>
    checkInferenceFromConstraints(
        typeParameter: "T extends Object*",
        constraints: "<: List<UNKNOWN>*",
        downwardsInferPhase: false,
        inferredTypeFromDownwardPhase: "List<UNKNOWN>*",
        expected: "List<dynamic>*");
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

    checkUpperBound(type1: "D*", type2: "E*", upperBound: "A*");
  }

  void test_lub_commonClass() {
    parseTestLibrary("");
    checkUpperBound(
        type1: "List<int*>*",
        type2: "List<double*>*",
        upperBound: "List<num*>*");
  }

  void test_lub_function() {
    parseTestLibrary("class A; class B extends A;");

    // LUB(() -> A, () -> B) = () -> A
    checkUpperBound(
        type1: "() ->* A*", type2: "() ->* B*", upperBound: "() ->* A*");

    // LUB(([A]) -> void, (A) -> void) = Function
    checkUpperBound(
        type1: "([A*]) ->* void",
        type2: "(A*) ->* void",
        upperBound: "Function*");

    // LUB(() -> void, (A, B) -> void) = Function
    checkUpperBound(
        type1: "() ->* void",
        type2: "(A*, B*) ->* void",
        upperBound: "Function*");
    checkUpperBound(
        type1: "(A*, B*) ->* void",
        type2: "() ->* void",
        upperBound: "Function*");

    // LUB((A) -> void, (B) -> void) = (B) -> void
    checkUpperBound(
        type1: "(A*) ->* void",
        type2: "(B*) ->* void",
        upperBound: "(B*) ->* void");
    checkUpperBound(
        type1: "(B*) ->* void",
        type2: "(A*) ->* void",
        upperBound: "(B*) ->* void");

    // LUB(({a: A}) -> void, ({b: B}) -> void) = () -> void
    checkUpperBound(
        type1: "({A* a}) ->* void",
        type2: "({B* b}) ->* void",
        upperBound: "() ->* void");
    checkUpperBound(
        type1: "({B* b}) ->* void",
        type2: "({A* a}) ->* void",
        upperBound: "() ->* void");

    // LUB(({a: A, c: A}) -> void, ({b: B, d: B}) -> void) = () -> void
    checkUpperBound(
        type1: "({A* a, A* c}) ->* void",
        type2: "({B* b, B* d}) ->* void",
        upperBound: "() ->* void");

    // LUB(({a: A, b: B}) -> void, ({a: B, b: A}) -> void)
    //     = ({a: B, b: B}) -> void
    checkUpperBound(
        type1: "({A* a, B* b}) ->* void",
        type2: "({B* a, A* b}) ->* void",
        upperBound: "({B* a, B* b}) ->* void");
    checkUpperBound(
        type1: "({B* a, A* b}) ->* void",
        type2: "({A* a, B* b}) ->* void",
        upperBound: "({B* a, B* b}) ->* void");

    // LUB((B, {a: A}) -> void, (B) -> void) = (B) -> void
    checkUpperBound(
        type1: "(B*, {A* a}) ->* void",
        type2: "(B*) ->* void",
        upperBound: "(B*) ->* void");

    // LUB(({a: A}) -> void, (B) -> void) = Function
    checkUpperBound(
        type1: "({A* a}) ->* void",
        type2: "(B*) ->* void",
        upperBound: "Function*");

    // GLB(({a: A}) -> void, ([B]) -> void) = () -> void
    checkUpperBound(
        type1: "({A* a}) ->* void",
        type2: "([B*]) ->* void",
        upperBound: "() ->* void");
  }

  void test_lub_identical() {
    parseTestLibrary("class A;");
    checkUpperBound(type1: "A*", type2: "A*", upperBound: "A*");
  }

  void test_lub_sameClass() {
    parseTestLibrary("class A; class B extends A; class Map<X, Y>;");
    checkUpperBound(
        type1: "Map<A*, B*>*",
        type2: "Map<B*, A*>*",
        upperBound: "Map<A*, A*>*");
  }

  void test_lub_subtype() {
    parseTestLibrary("");
    checkUpperBound(
        type1: "List<int*>*",
        type2: "Iterable<num*>*",
        upperBound: "Iterable<num*>*");
    checkUpperBound(
        type1: "Iterable<num*>*",
        type2: "List<int*>*",
        upperBound: "Iterable<num*>*");
  }

  void test_lub_top() {
    parseTestLibrary("class A;");

    checkUpperBound(type1: "dynamic", type2: "A*", upperBound: "dynamic");
    checkUpperBound(type1: "A*", type2: "dynamic", upperBound: "dynamic");
    checkUpperBound(type1: "Object*", type2: "A*", upperBound: "Object*");
    checkUpperBound(type1: "A*", type2: "Object*", upperBound: "Object*");
    checkUpperBound(type1: "void", type2: "A*", upperBound: "void");
    checkUpperBound(type1: "A*", type2: "void", upperBound: "void");
    checkUpperBound(type1: "dynamic", type2: "Object*", upperBound: "dynamic");
    checkUpperBound(type1: "Object*", type2: "dynamic", upperBound: "dynamic");
    checkUpperBound(type1: "dynamic", type2: "void", upperBound: "void");
    checkUpperBound(type1: "void", type2: "dynamic", upperBound: "void");
    checkUpperBound(type1: "Object*", type2: "void", upperBound: "void");
    checkUpperBound(type1: "void", type2: "Object*", upperBound: "void");
  }

  void test_lub_typeParameter() {
    parseTestLibrary("");

    // LUB(T, T) = T
    checkUpperBound(
        type1: "T*",
        type2: "T*",
        upperBound: "T*",
        typeParameters: "T extends List<T*>*");

    // LUB(T, List<Bottom>) = LUB(List<Object>, List<Bottom>) = List<Object>
    checkUpperBound(
        type1: "T*",
        type2: "List<Null>*",
        upperBound: "List<Object*>*",
        typeParameters: "T extends List<T*>*");
    checkUpperBound(
        type1: "List<Null>*",
        type2: "T*",
        upperBound: "List<Object*>*",
        typeParameters: "T extends List<T*>*");

    // LUB(T, U) = LUB(List<Object>, U) = LUB(List<Object>, List<Bottom>)
    // = List<Object>
    checkUpperBound(
        type1: "T*",
        type2: "U*",
        upperBound: "List<Object*>*",
        typeParameters: "T extends List<T*>*, U extends List<Null>*");
    checkUpperBound(
        type1: "U*",
        type2: "T*",
        upperBound: "List<Object*>*",
        typeParameters: "T extends List<T*>*, U extends List<Null>*");
  }

  void test_lub_unknown() {
    parseTestLibrary("class A;");
    checkUpperBound(type1: "A*", type2: "UNKNOWN", upperBound: "A*");
    checkUpperBound(type1: "UNKNOWN", type2: "A*", upperBound: "A*");
  }

  void test_solveTypeConstraint() {
    parseTestLibrary("""
      class A;
      class B extends A;
      
      class C<T extends Object*>;
      class D<T extends Object*> extends C<T*>;
    """);

    // Solve(? <: T <: ?) => ?
    checkConstraintSolving("", "UNKNOWN", grounded: false);

    // Solve(? <: T <: ?, grounded) => dynamic
    checkConstraintSolving("", "dynamic", grounded: true);

    // Solve(A <: T <: ?) => A
    checkConstraintSolving(":> A*", "A*", grounded: false);

    // Solve(A <: T <: ?, grounded) => A
    checkConstraintSolving(":> A*", "A*", grounded: true);

    // Solve(A<?> <: T <: ?) => A<?>
    checkConstraintSolving(":> C<UNKNOWN>*", "C<UNKNOWN>*", grounded: false);

    // Solve(A<?> <: T <: ?, grounded) => A<Null>
    checkConstraintSolving(":> C<UNKNOWN>*", "C<Null>*", grounded: true);

    // Solve(? <: T <: A) => A
    checkConstraintSolving("<: A*", "A*", grounded: false);

    // Solve(? <: T <: A, grounded) => A
    checkConstraintSolving("<: A*", "A*", grounded: true);

    // Solve(? <: T <: A<?>) => A<?>
    checkConstraintSolving("<: C<UNKNOWN>*", "C<UNKNOWN>*", grounded: false);

    // Solve(? <: T <: A<?>, grounded) => A<dynamic>
    checkConstraintSolving("<: C<UNKNOWN>*", "C<dynamic>*", grounded: true);

    // Solve(B <: T <: A) => B
    checkConstraintSolving(":> B* <: A*", "B*", grounded: false);

    // Solve(B <: T <: A, grounded) => B
    checkConstraintSolving(":> B* <: A*", "B*", grounded: true);

    // Solve(B<?> <: T <: A) => A
    checkConstraintSolving(":> D<UNKNOWN>* <: C<dynamic>*", "C<dynamic>*",
        grounded: false);

    // Solve(B<?> <: T <: A, grounded) => A
    checkConstraintSolving(":> D<UNKNOWN>* <: C<dynamic>*", "C<dynamic>*",
        grounded: true);

    // Solve(B <: T <: A<?>) => B
    checkConstraintSolving(":> D<Null>* <: C<UNKNOWN>*", "D<Null>*",
        grounded: false);

    // Solve(B <: T <: A<?>, grounded) => B
    checkConstraintSolving(":> D<Null>* <: C<UNKNOWN>*", "D<Null>*",
        grounded: true);

    // Solve(B<?> <: T <: A<?>) => B<?>
    checkConstraintSolving(":> D<UNKNOWN>* <: C<UNKNOWN>*", "D<UNKNOWN>*",
        grounded: false);

    // Solve(B<?> <: T <: A<?>) => B<Null>
    checkConstraintSolving(":> D<UNKNOWN>* <: C<UNKNOWN>*", "D<Null>*",
        grounded: true);
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

    checkTypeDoesntSatisfyConstraint("A*", ":> D* <: B*");
    checkTypeSatisfiesConstraint("B*", ":> D* <: B*");
    checkTypeSatisfiesConstraint("C*", ":> D* <: B*");
    checkTypeSatisfiesConstraint("D*", ":> D* <: B*");
    checkTypeDoesntSatisfyConstraint("E*", ":> D* <: B*");
  }

  void test_unknown_at_bottom() {
    parseTestLibrary("class A;");
    checkIsLegacySubtype("UNKNOWN", "A*");
  }

  void test_unknown_at_top() {
    parseTestLibrary("class A; class Map<X, Y>;");
    checkIsLegacySubtype("A*", "UNKNOWN");
    checkIsLegacySubtype("Map<A*, A*>*", "Map<UNKNOWN, UNKNOWN>*");
  }

  void checkConstraintSolving(String constraint, String expected,
      {bool grounded}) {
    assert(grounded != null);
    expect(
        typeSchemaEnvironment.solveTypeConstraint(
            parseConstraint(constraint), new DynamicType(), new NullType(),
            grounded: grounded),
        parseType(expected));
  }

  void checkConstraintUpperBound({String constraint, String bound}) {
    assert(constraint != null);
    assert(bound != null);

    expect(parseConstraint(constraint).upper, parseType(bound));
  }

  void checkConstraintLowerBound({String constraint, String bound}) {
    assert(constraint != null);
    assert(bound != null);

    expect(parseConstraint(constraint).lower, parseType(bound));
  }

  void checkTypeSatisfiesConstraint(String type, String constraint) {
    expect(
        typeSchemaEnvironment.typeSatisfiesConstraint(
            parseType(type), parseConstraint(constraint)),
        isTrue);
  }

  void checkTypeDoesntSatisfyConstraint(String type, String constraint) {
    expect(
        typeSchemaEnvironment.typeSatisfiesConstraint(
            parseType(type), parseConstraint(constraint)),
        isFalse);
  }

  void checkIsSubtype(String subtype, String supertype) {
    expect(
        typeSchemaEnvironment
            .performNullabilityAwareSubtypeCheck(
                parseType(subtype), parseType(supertype))
            .isSubtypeWhenUsingNullabilities(),
        isTrue);
  }

  void checkIsLegacySubtype(String subtype, String supertype) {
    expect(
        typeSchemaEnvironment
            .performNullabilityAwareSubtypeCheck(
                parseType(subtype), parseType(supertype))
            .isSubtypeWhenIgnoringNullabilities(),
        isTrue);
  }

  void checkIsNotSubtype(String subtype, String supertype) {
    expect(
        typeSchemaEnvironment
            .performNullabilityAwareSubtypeCheck(
                parseType(subtype), parseType(supertype))
            .isSubtypeWhenIgnoringNullabilities(),
        isFalse);
  }

  void checkUpperBound(
      {String type1, String type2, String upperBound, String typeParameters}) {
    assert(type1 != null);
    assert(type2 != null);
    assert(upperBound != null);

    typeParserEnvironment.withTypeParameters(typeParameters,
        (List<TypeParameter> typeParameterNodes) {
      expect(
          typeSchemaEnvironment.getStandardUpperBound(
              parseType(type1), parseType(type2), testLibrary),
          parseType(upperBound));
    });
  }

  void checkLowerBound(
      {String type1, String type2, String lowerBound, String typeParameters}) {
    assert(type1 != null);
    assert(type2 != null);
    assert(lowerBound != null);

    typeParserEnvironment.withTypeParameters(typeParameters,
        (List<TypeParameter> typeParameterNodes) {
      expect(
          typeSchemaEnvironment.getStandardLowerBound(
              parseType(type1), parseType(type2), testLibrary),
          parseType(lowerBound));
    });
  }

  void checkInference(
      {String typeParametersToInfer,
      String functionType,
      String actualParameterTypes,
      String returnContextType,
      String inferredTypesFromDownwardPhase,
      String expectedTypes}) {
    assert(typeParametersToInfer != null);
    assert(functionType != null);
    assert(expectedTypes != null);

    typeParserEnvironment.withTypeParameters(typeParametersToInfer,
        (List<TypeParameter> typeParameterNodesToInfer) {
      FunctionType functionTypeNode = parseType(functionType);
      DartType returnContextTypeNode =
          returnContextType == null ? null : parseType(returnContextType);
      List<DartType> actualTypeNodes = actualParameterTypes == null
          ? null
          : parseTypes(actualParameterTypes);
      List<DartType> expectedTypeNodes =
          expectedTypes == null ? null : parseTypes(expectedTypes);
      DartType declaredReturnTypeNode = functionTypeNode.returnType;
      List<DartType> formalTypeNodes = actualParameterTypes == null
          ? null
          : functionTypeNode.positionalParameters;

      List<DartType> inferredTypeNodes;
      if (inferredTypesFromDownwardPhase == null) {
        inferredTypeNodes = new List<DartType>.generate(
            typeParameterNodesToInfer.length, (_) => new UnknownType());
      } else {
        inferredTypeNodes = parseTypes(inferredTypesFromDownwardPhase);
      }

      typeSchemaEnvironment.inferGenericFunctionOrType(
          declaredReturnTypeNode,
          typeParameterNodesToInfer,
          formalTypeNodes,
          actualTypeNodes,
          returnContextTypeNode,
          inferredTypeNodes,
          testLibrary);

      assert(
          inferredTypeNodes.length == expectedTypeNodes.length,
          "The numbers of expected types and type parameters to infer "
          "mismatch.");
      for (int i = 0; i < inferredTypeNodes.length; ++i) {
        expect(inferredTypeNodes[i], expectedTypeNodes[i]);
      }
    });
  }

  void checkInferenceFromConstraints(
      {String typeParameter,
      String constraints,
      String inferredTypeFromDownwardPhase,
      bool downwardsInferPhase,
      String expected}) {
    assert(typeParameter != null);
    assert(expected != null);
    assert(downwardsInferPhase != null);
    assert(inferredTypeFromDownwardPhase == null || !downwardsInferPhase);

    typeParserEnvironment.withTypeParameters(typeParameter,
        (List<TypeParameter> typeParameterNodes) {
      assert(typeParameterNodes.length == 1);

      TypeConstraint typeConstraint = parseConstraint(constraints);
      DartType expectedTypeNode = parseType(expected);
      TypeParameter typeParameterNode = typeParameterNodes.single;
      List<DartType> inferredTypeNodes = <DartType>[
        inferredTypeFromDownwardPhase == null
            ? new UnknownType()
            : parseType(inferredTypeFromDownwardPhase)
      ];

      typeSchemaEnvironment.inferTypeFromConstraints(
          {typeParameterNode: typeConstraint},
          [typeParameterNode],
          inferredTypeNodes,
          testLibrary,
          downwardsInferPhase: downwardsInferPhase);

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
  TypeConstraint parseConstraint(String constraint) {
    TypeConstraint result = new TypeConstraint();
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
            typeSchemaEnvironment.addUpperBound(
                result, parseType(segment), testLibrary);
          }
        } else {
          typeSchemaEnvironment.addLowerBound(
              result, parseType(segment), testLibrary);
        }
      }
    }
    return result;
  }

  DartType parseType(String type) {
    return typeParserEnvironment.parseType(type,
        additionalTypes: additionalTypes);
  }

  List<DartType> parseTypes(String types) {
    return typeParserEnvironment.parseTypes(types,
        additionalTypes: additionalTypes);
  }
}
