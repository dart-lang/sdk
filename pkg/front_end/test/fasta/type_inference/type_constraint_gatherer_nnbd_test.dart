// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_constraint_gatherer.dart';
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
    defineReflectiveTests(TypeConstraintGathererTest);
  });
}

@reflectiveTest
class TypeConstraintGathererTest {
  Env env;

  final Map<String, DartType Function()> additionalTypes = {
    'UNKNOWN': () => new UnknownType()
  };

  Library _coreLibrary;

  Library _testLibrary;

  TypeConstraintGathererTest();

  Component get component => env.component;

  CoreTypes get coreTypes => env.coreTypes;

  Library get coreLibrary => _coreLibrary;

  Library get testLibrary => _testLibrary;

  void parseTestLibrary(String testLibraryText) {
    env = new Env(testLibraryText, isNonNullableByDefault: true);
    assert(
        env.component.libraries.length == 2,
        "The tests are supposed to have exactly two libraries: "
        "the core library and the test library.");
    Library firstLibrary = env.component.libraries.first;
    Library secondLibrary = env.component.libraries.last;
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

  void test_any_subtype_parameter() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsLower('T1*', 'Q?', ['lib::Q? <: T1'],
        typeParameters: 'T1 extends Object*');
    checkConstraintsLower('T1*', 'Q', ['lib::Q <: T1'],
        typeParameters: 'T1 extends Object*');
    checkConstraintsUpper('T1*', 'Q?', ['T1 <: lib::Q?'],
        typeParameters: 'T1 extends Object*');
    checkConstraintsUpper('T1*', 'Q', ['T1 <: lib::Q'],
        typeParameters: 'T1 extends Object*');

    checkConstraintsLower('S1', 'Q', ['lib::Q <: S1'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsLower('S1', 'Q?', ['lib::Q? <: S1'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsLower('S1?', 'Q', ['lib::Q <: S1'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsLower('S1?', 'Q?', ['lib::Q <: S1'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsUpper('S1', 'Q', ['S1 <: lib::Q'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsUpper('S1', 'Q?', ['S1 <: lib::Q?'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsUpper('S1?', 'Q', null,
        typeParameters: 'S1 extends Object?');
    checkConstraintsUpper('S1?', 'Q?', ['S1 <: lib::Q'],
        typeParameters: 'S1 extends Object?');
  }

  void test_any_subtype_top() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsUpper('P*', 'dynamic', []);
    checkConstraintsUpper('P*', 'Object*', []);
    checkConstraintsUpper('P*', 'void', []);
  }

  void test_any_subtype_unknown() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsUpper('P*', 'UNKNOWN', []);
    checkConstraintsUpper('T1*', 'UNKNOWN', [],
        typeParameters: 'T1 extends Object*');
    checkConstraintsUpper('S1', 'UNKNOWN', [],
        typeParameters: 'S1 extends Object?');
    checkConstraintsUpper('R1', 'UNKNOWN', [],
        typeParameters: 'R1 extends Object');
  }

  void test_different_classes() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsUpper('List<T1*>*', 'Iterable<Q*>*', ['T1 <: lib::Q*'],
        typeParameters: 'T1 extends Object*');
    checkConstraintsUpper('Iterable<T1*>*', 'List<Q*>*', null,
        typeParameters: 'T1 extends Object*');
    checkConstraintsUpper('List<S1>*', 'Iterable<Q*>*', ['S1 <: lib::Q*'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsUpper('Iterable<S1>*', 'List<Q*>*', null,
        typeParameters: 'S1 extends Object?');
    checkConstraintsUpper('List<R1>*', 'Iterable<Q*>*', ['R1 <: lib::Q*'],
        typeParameters: 'R1 extends Object');
    checkConstraintsUpper('Iterable<R1>*', 'List<Q*>*', null,
        typeParameters: 'R1 extends Object');
  }

  void test_equal_types() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsUpper('P*', 'P*', []);
  }

  void test_function_generic() {
    parseTestLibrary('');

    // <T>() -> dynamic <: () -> dynamic, never
    checkConstraintsUpper(
        '<T extends Object*>() ->* dynamic', '() ->* dynamic', null);
    // () -> dynamic <: <T>() -> dynamic, never
    checkConstraintsUpper(
        '() ->* dynamic', '<T extends Object*>() ->* dynamic', null);
    // <T>(T) -> T <: <U>(U) -> U, always
    checkConstraintsUpper(
        '<T extends Object*>(T*) ->* T*', '<U extends Object*>(U*) ->* U*', []);
  }

  void test_function_parameter_mismatch() {
    parseTestLibrary('class P; class Q;');

    // (P) -> dynamic <: () -> dynamic, never
    checkConstraintsUpper('(P*) ->* dynamic', '() ->* dynamic', null);
    // () -> dynamic <: (P) -> dynamic, never
    checkConstraintsUpper('() ->* dynamic', '(P*) ->* dynamic', null);
    // ([P]) -> dynamic <: () -> dynamic, always
    checkConstraintsUpper('([P*]) ->* dynamic', '() ->* dynamic', []);
    // () -> dynamic <: ([P]) -> dynamic, never
    checkConstraintsUpper('() ->* dynamic', '([P*]) ->* dynamic', null);
    // ({x: P}) -> dynamic <: () -> dynamic, always
    checkConstraintsUpper('({P* x}) ->* dynamic', '() ->* dynamic', []);
    // () -> dynamic !<: ({x: P}) -> dynamic, never
    checkConstraintsUpper('() ->* dynamic', '({P* x}) ->* dynamic', null);
  }

  void test_function_parameter_types() {
    parseTestLibrary('class P; class Q;');

    // (T1) -> dynamic <: (Q) -> dynamic, under constraint Q <: T1
    checkConstraintsUpper(
        '(T1*) ->* dynamic', '(Q*) ->* dynamic', ['lib::Q* <: T1'],
        typeParameters: 'T1 extends Object*');
    // ({x: T1}) -> dynamic <: ({x: Q}) -> dynamic, under constraint Q <: T1
    checkConstraintsUpper(
        '({T1* x}) ->* dynamic', '({Q* x}) ->* dynamic', ['lib::Q* <: T1'],
        typeParameters: 'T1 extends Object*');
    // (S1) -> S1? <: (P) -> P?
    checkConstraintsUpper(
        '(S1) -> S1?', '(P) -> P?', ['lib::P <: S1 <: lib::P'],
        typeParameters: 'S1 extends Object?');
    // (S1, List<S1?>) -> void <: (P, List<P?>) -> void
    checkConstraintsUpper(
        '(S1, List<S1?>*) -> void', '(P, List<P?>*) -> void', ['lib::P <: S1'],
        typeParameters: 'S1 extends Object?');
  }

  void test_function_return_type() {
    parseTestLibrary('class P; class Q;');

    // () -> T1 <: () -> Q, under constraint T1 <: Q
    checkConstraintsUpper('() ->* T1', '() ->* Q*', ['T1 <: lib::Q*'],
        typeParameters: 'T1 extends Object*');
    // () -> P <: () -> void, always
    checkConstraintsUpper('() ->* P*', '() ->* void', []);
    // () -> void <: () -> P, never
    checkConstraintsUpper('() ->* void', '() ->* P*', null);
  }

  void test_function_trivial_cases() {
    parseTestLibrary('');

    // () -> dynamic <: dynamic, always
    checkConstraintsUpper('() ->* dynamic', 'dynamic', []);
    // () -> dynamic <: Function, always
    checkConstraintsUpper('() ->* dynamic', 'Function*', []);
    // () -> dynamic <: Object, always
    checkConstraintsUpper('() ->* dynamic', 'Object*', []);
  }

  void test_nonInferredParameter_subtype_any() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsLower('List<T1*>*', 'U*', ['lib::P* <: T1'],
        typeParameters: 'T1 extends Object*, U extends List<P*>*',
        typeParametersToConstrain: 'T1');
  }

  void test_null_subtype_any() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsLower('T1*', 'Null', ['Null <: T1'],
        typeParameters: 'T1 extends Object*');
    checkConstraintsUpper('Null', 'Q*', []);
  }

  void test_parameter_subtype_any() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsUpper('T1*', 'Q*', ['T1 <: lib::Q*'],
        typeParameters: 'T1 extends Object*');
    checkConstraintsLower('T1*', 'Q*', ['lib::Q* <: T1'],
        typeParameters: 'T1 extends Object*');

    checkConstraintsUpper('S1', 'Q*', ['S1 <: lib::Q*'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsLower('S1', 'Q*', ['lib::Q* <: S1'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsUpper('S1*', 'Q*', ['S1 <: lib::Q*'],
        typeParameters: 'S1 extends Object?');
    checkConstraintsLower('S1*', 'Q*', ['lib::Q <: S1'],
        typeParameters: 'S1 extends Object?');

    checkConstraintsUpper('R1', 'Q*', ['R1 <: lib::Q*'],
        typeParameters: 'R1 extends Object');
    checkConstraintsLower('R1', 'Q*', ['lib::Q* <: R1'],
        typeParameters: 'R1 extends Object');
    checkConstraintsUpper('R1*', 'Q*', ['R1 <: lib::Q*'],
        typeParameters: 'R1 extends Object');
    checkConstraintsLower('R1*', 'Q*', ['lib::Q <: R1'],
        typeParameters: 'R1 extends Object');
  }

  void test_same_classes() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsUpper('List<T1*>*', 'List<Q*>*', ['T1 <: lib::Q*'],
        typeParameters: 'T1 extends Object*');
  }

  void test_typeParameters() {
    parseTestLibrary('class P; class Q; class Map<X, Y>;');

    checkConstraintsUpper(
        'Map<T1*, T2*>*', 'Map<P*, Q*>*', ['T1 <: lib::P*', 'T2 <: lib::Q*'],
        typeParameters: 'T1 extends Object*, T2 extends Object*');
    checkConstraintsLower(
        'Map<T1*, T2*>*', 'Map<P*, Q*>*', ['lib::P* <: T1', 'lib::Q* <: T2'],
        typeParameters: 'T1 extends Object*, T2 extends Object*');

    checkConstraintsUpper(
        'Map<S1, S2>*', 'Map<P*, Q*>*', ['S1 <: lib::P*', 'S2 <: lib::Q*'],
        typeParameters: 'S1 extends Object?, S2 extends Object?');
    checkConstraintsLower(
        'Map<S1, S2>*', 'Map<P*, Q*>*', ['lib::P* <: S1', 'lib::Q* <: S2'],
        typeParameters: 'S1 extends Object?, S2 extends Object?');
    checkConstraintsUpper(
        'Map<S1*, S2*>*', 'Map<P*, Q*>*', ['S1 <: lib::P*', 'S2 <: lib::Q*'],
        typeParameters: 'S1 extends Object?, S2 extends Object?');
    checkConstraintsLower(
        'Map<S1*, S2*>*', 'Map<P*, Q*>*', ['lib::P <: S1', 'lib::Q <: S2'],
        typeParameters: 'S1 extends Object?, S2 extends Object?');

    checkConstraintsUpper(
        'Map<R1, R2>*', 'Map<P*, Q*>*', ['R1 <: lib::P*', 'R2 <: lib::Q*'],
        typeParameters: 'R1 extends Object, R2 extends Object');
    checkConstraintsLower(
        'Map<R1, R2>*', 'Map<P*, Q*>*', ['lib::P* <: R1', 'lib::Q* <: R2'],
        typeParameters: 'R1 extends Object, R2 extends Object');
    checkConstraintsUpper(
        'Map<R1*, R2*>*', 'Map<P*, Q*>*', ['R1 <: lib::P*', 'R2 <: lib::Q*'],
        typeParameters: 'R1 extends Object, R2 extends Object');
    checkConstraintsLower(
        'Map<R1*, R2*>*', 'Map<P*, Q*>*', ['lib::P <: R1', 'lib::Q <: R2'],
        typeParameters: 'R1 extends Object, R2 extends Object');
  }

  void test_unknown_subtype_any() {
    parseTestLibrary('class P; class Q;');

    checkConstraintsLower('Q*', 'UNKNOWN', []);
    checkConstraintsLower('T1*', 'UNKNOWN', [],
        typeParameters: 'T1 extends Object*');
  }

  void checkConstraintsLower(String type, String bound, List<String> expected,
      {String typeParameters, String typeParametersToConstrain}) {
    env.withTypeParameters(typeParameters ?? '',
        (List<TypeParameter> typeParameterNodes) {
      List<TypeParameter> typeParameterNodesToConstrain;
      if (typeParametersToConstrain != null) {
        Set<String> namesToConstrain =
            typeParametersToConstrain.split(",").map((s) => s.trim()).toSet();
        typeParameterNodesToConstrain = typeParameterNodes
            .where((p) => namesToConstrain.contains(p.name))
            .toList();
      } else {
        typeParameterNodesToConstrain = typeParameterNodes;
      }
      _checkConstraintsLowerTypes(
          env.parseType(type, additionalTypes: additionalTypes),
          env.parseType(bound, additionalTypes: additionalTypes),
          testLibrary,
          expected,
          typeParameterNodesToConstrain);
    });
  }

  void _checkConstraintsLowerTypes(
      DartType type,
      DartType bound,
      Library clientLibrary,
      List<String> expectedConstraints,
      List<TypeParameter> typeParameterNodesToConstrain) {
    _checkConstraintsHelper(
        type,
        bound,
        clientLibrary,
        expectedConstraints,
        (gatherer, type, bound) => gatherer.tryConstrainLower(type, bound),
        typeParameterNodesToConstrain);
  }

  void checkConstraintsUpper(String type, String bound, List<String> expected,
      {String typeParameters, String typeParametersToConstrain}) {
    env.withTypeParameters(typeParameters ?? '',
        (List<TypeParameter> typeParameterNodes) {
      List<TypeParameter> typeParameterNodesToConstrain;
      if (typeParametersToConstrain != null) {
        Set<String> namesToConstrain =
            typeParametersToConstrain.split(",").map((s) => s.trim()).toSet();
        typeParameterNodesToConstrain = typeParameterNodes
            .where((p) => namesToConstrain.contains(p.name))
            .toList();
      } else {
        typeParameterNodesToConstrain = typeParameterNodes;
      }
      _checkConstraintsUpperTypes(
          env.parseType(type, additionalTypes: additionalTypes),
          env.parseType(bound, additionalTypes: additionalTypes),
          testLibrary,
          expected,
          typeParameterNodesToConstrain);
    });
  }

  void _checkConstraintsUpperTypes(
      DartType type,
      DartType bound,
      Library clientLibrary,
      List<String> expectedConstraints,
      List<TypeParameter> typeParameterNodesToConstrain) {
    _checkConstraintsHelper(
        type,
        bound,
        clientLibrary,
        expectedConstraints,
        (gatherer, type, bound) => gatherer.tryConstrainUpper(type, bound),
        typeParameterNodesToConstrain);
  }

  void _checkConstraintsHelper(
      DartType a,
      DartType b,
      Library clientLibrary,
      List<String> expectedConstraints,
      bool Function(TypeConstraintGatherer, DartType, DartType) tryConstrain,
      List<TypeParameter> typeParameterNodesToConstrain) {
    var typeSchemaEnvironment = new TypeSchemaEnvironment(
        coreTypes, new ClassHierarchy(component, coreTypes));
    var typeConstraintGatherer = new TypeConstraintGatherer(
        typeSchemaEnvironment, typeParameterNodesToConstrain, testLibrary);
    var constraints = tryConstrain(typeConstraintGatherer, a, b)
        ? typeConstraintGatherer.computeConstraints(clientLibrary)
        : null;
    if (expectedConstraints == null) {
      expect(constraints, isNull);
      return;
    }
    expect(constraints, isNotNull);
    var constraintStrings = <String>[];
    constraints.forEach((t, constraint) {
      if (constraint.lower is! UnknownType ||
          constraint.upper is! UnknownType) {
        var s = t.name;
        if (constraint.lower is! UnknownType) {
          s = '${typeSchemaToString(constraint.lower)} <: $s';
        }
        if (constraint.upper is! UnknownType) {
          s = '$s <: ${typeSchemaToString(constraint.upper)}';
        }
        constraintStrings.add(s);
      }
    });
    expect(constraintStrings, unorderedEquals(expectedConstraints));
  }
}
