// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_constraint_gatherer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/testing/mock_sdk_component.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeConstraintGathererTest);
  });
}

@reflectiveTest
class TypeConstraintGathererTest {
  static const UnknownType unknownType = const UnknownType();

  static const DynamicType dynamicType = const DynamicType();

  static const VoidType voidType = const VoidType();

  final testLib =
      new Library(Uri.parse('org-dartlang:///test.dart'), name: 'lib')
        ..isNonNullableByDefault = true;

  Component component;

  CoreTypes coreTypes;

  TypeParameterType T1;
  TypeParameterType T2;
  TypeParameterType S1;
  TypeParameterType S2;
  TypeParameterType R1;
  TypeParameterType R2;

  Class classP;

  Class classQ;

  TypeConstraintGathererTest() {
    component = createMockSdkComponent();
    component.libraries.add(testLib..parent = component);
    coreTypes = new CoreTypes(component);
    T1 = new TypeParameterType(
        new TypeParameter('T1', coreTypes.objectLegacyRawType),
        Nullability.legacy);
    T2 = new TypeParameterType(
        new TypeParameter('T2', coreTypes.objectLegacyRawType),
        Nullability.legacy);
    S1 = new TypeParameterType(
        new TypeParameter('S1', coreTypes.objectNullableRawType),
        Nullability.undetermined);
    S2 = new TypeParameterType(
        new TypeParameter('S2', coreTypes.objectNullableRawType),
        Nullability.undetermined);
    R1 = new TypeParameterType(
        new TypeParameter('R1', coreTypes.objectNonNullableRawType),
        Nullability.nonNullable);
    R2 = new TypeParameterType(
        new TypeParameter('R2', coreTypes.objectNonNullableRawType),
        Nullability.nonNullable);
    classP = _addClass(_class('P'));
    classQ = _addClass(_class('Q'));
  }

  Class get functionClass => coreTypes.functionClass;

  InterfaceType get functionType => coreTypes.functionLegacyRawType;

  Class get iterableClass => coreTypes.iterableClass;

  Class get listClass => coreTypes.listClass;

  Class get mapClass => coreTypes.mapClass;

  InterfaceType get nullType => coreTypes.nullType;

  Class get objectClass => coreTypes.objectClass;

  InterfaceType get P => coreTypes.legacyRawType(classP);

  InterfaceType get Q => coreTypes.legacyRawType(classQ);

  void test_any_subtype_parameter() {
    DartType nullableQ = Q.withDeclaredNullability(Nullability.nullable);
    DartType nonNullableQ = Q.withDeclaredNullability(Nullability.nonNullable);

    _checkConstraintsLower(T1, nullableQ, testLib, ['lib::Q? <: T1']);
    _checkConstraintsLower(T1, nonNullableQ, testLib, ['lib::Q <: T1']);
    _checkConstraintsUpper(T1, nullableQ, testLib, ['T1 <: lib::Q?']);
    _checkConstraintsUpper(T1, nonNullableQ, testLib, ['T1 <: lib::Q']);

    DartType nullableS1 = S1.withDeclaredNullability(Nullability.nullable);
    _checkConstraintsLower(S1, nonNullableQ, testLib, ['lib::Q <: S1']);
    _checkConstraintsLower(S1, nullableQ, testLib, ['lib::Q? <: S1']);
    _checkConstraintsLower(nullableS1, nonNullableQ, testLib, ['lib::Q <: S1']);
    _checkConstraintsLower(nullableS1, nullableQ, testLib, ['lib::Q <: S1']);
    _checkConstraintsUpper(S1, nonNullableQ, testLib, ['S1 <: lib::Q']);
    _checkConstraintsUpper(S1, nullableQ, testLib, ['S1 <: lib::Q?']);
    _checkConstraintsUpper(nullableS1, nonNullableQ, testLib, null);
    _checkConstraintsUpper(nullableS1, nullableQ, testLib, ['S1 <: lib::Q']);
  }

  void test_any_subtype_top() {
    _checkConstraintsUpper(P, dynamicType, testLib, []);
    _checkConstraintsUpper(P, coreTypes.objectLegacyRawType, testLib, []);
    _checkConstraintsUpper(P, voidType, testLib, []);
  }

  void test_any_subtype_unknown() {
    _checkConstraintsUpper(P, unknownType, testLib, []);
    _checkConstraintsUpper(T1, unknownType, testLib, []);
    _checkConstraintsUpper(S1, unknownType, testLib, []);
    _checkConstraintsUpper(R1, unknownType, testLib, []);
  }

  void test_different_classes() {
    _checkConstraintsUpper(_list(T1), _iterable(Q), testLib, ['T1 <: lib::Q*']);
    _checkConstraintsUpper(_iterable(T1), _list(Q), testLib, null);
    _checkConstraintsUpper(_list(S1), _iterable(Q), testLib, ['S1 <: lib::Q*']);
    _checkConstraintsUpper(_iterable(S1), _list(Q), testLib, null);
    _checkConstraintsUpper(_list(R1), _iterable(Q), testLib, ['R1 <: lib::Q*']);
    _checkConstraintsUpper(_iterable(R1), _list(Q), testLib, null);
  }

  void test_equal_types() {
    _checkConstraintsUpper(P, P, testLib, []);
  }

  void test_function_generic() {
    var T = new TypeParameterType(
        new TypeParameter('T', coreTypes.objectLegacyRawType),
        Nullability.legacy);
    var U = new TypeParameterType(
        new TypeParameter('U', coreTypes.objectLegacyRawType),
        Nullability.legacy);
    // <T>() -> dynamic <: () -> dynamic, never
    _checkConstraintsUpper(
        new FunctionType([], dynamicType, Nullability.legacy,
            typeParameters: [T.parameter]),
        new FunctionType([], dynamicType, Nullability.legacy),
        testLib,
        null);
    // () -> dynamic <: <T>() -> dynamic, never
    _checkConstraintsUpper(
        new FunctionType([], dynamicType, Nullability.legacy),
        new FunctionType([], dynamicType, Nullability.legacy,
            typeParameters: [T.parameter]),
        testLib,
        null);
    // <T>(T) -> T <: <U>(U) -> U, always
    _checkConstraintsUpper(
        new FunctionType([T], T, Nullability.legacy,
            typeParameters: [T.parameter]),
        new FunctionType([U], U, Nullability.legacy,
            typeParameters: [U.parameter]),
        testLib,
        []);
  }

  void test_function_parameter_mismatch() {
    // (P) -> dynamic <: () -> dynamic, never
    _checkConstraintsUpper(
        new FunctionType([P], dynamicType, Nullability.legacy),
        new FunctionType([], dynamicType, Nullability.legacy),
        testLib,
        null);
    // () -> dynamic <: (P) -> dynamic, never
    _checkConstraintsUpper(
        new FunctionType([], dynamicType, Nullability.legacy),
        new FunctionType([P], dynamicType, Nullability.legacy),
        testLib,
        null);
    // ([P]) -> dynamic <: () -> dynamic, always
    _checkConstraintsUpper(
        new FunctionType([P], dynamicType, Nullability.legacy,
            requiredParameterCount: 0),
        new FunctionType([], dynamicType, Nullability.legacy),
        testLib,
        []);
    // () -> dynamic <: ([P]) -> dynamic, never
    _checkConstraintsUpper(
        new FunctionType([], dynamicType, Nullability.legacy),
        new FunctionType([P], dynamicType, Nullability.legacy,
            requiredParameterCount: 0),
        testLib,
        null);
    // ({x: P}) -> dynamic <: () -> dynamic, always
    _checkConstraintsUpper(
        new FunctionType([], dynamicType, Nullability.legacy,
            namedParameters: [new NamedType('x', P)]),
        new FunctionType([], dynamicType, Nullability.legacy),
        testLib,
        []);
    // () -> dynamic !<: ({x: P}) -> dynamic, never
    _checkConstraintsUpper(
        new FunctionType([], dynamicType, Nullability.legacy),
        new FunctionType([], dynamicType, Nullability.legacy,
            namedParameters: [new NamedType('x', P)]),
        testLib,
        null);
  }

  void test_function_parameter_types() {
    // (T1) -> dynamic <: (Q) -> dynamic, under constraint Q <: T1
    _checkConstraintsUpper(
        new FunctionType([T1], dynamicType, Nullability.legacy),
        new FunctionType([Q], dynamicType, Nullability.legacy),
        testLib,
        ['lib::Q* <: T1']);
    // ({x: T1}) -> dynamic <: ({x: Q}) -> dynamic, under constraint Q <: T1
    _checkConstraintsUpper(
        new FunctionType([], dynamicType, Nullability.legacy,
            namedParameters: [new NamedType('x', T1)]),
        new FunctionType([], dynamicType, Nullability.legacy,
            namedParameters: [new NamedType('x', Q)]),
        testLib,
        ['lib::Q* <: T1']);
    // (S1) -> S1? <: (P) -> P?
    _checkConstraintsUpper(
        new FunctionType([S1], S1.withDeclaredNullability(Nullability.nullable),
            Nullability.nonNullable),
        new FunctionType(
            [P.withDeclaredNullability(Nullability.nonNullable)],
            P.withDeclaredNullability(Nullability.nullable),
            Nullability.nonNullable),
        testLib,
        ['lib::P <: S1 <: lib::P']);
    // (S1, List<S1?>) -> void <: (P, List<P?>) -> void
    _checkConstraintsUpper(
        new FunctionType(
            [S1, _list(S1.withDeclaredNullability(Nullability.nullable))],
            voidType,
            Nullability.nonNullable),
        new FunctionType([
          P.withDeclaredNullability(Nullability.nonNullable),
          _list(P.withDeclaredNullability(Nullability.nullable))
        ], voidType, Nullability.nonNullable),
        testLib,
        ['lib::P <: S1']);
  }

  void test_function_return_type() {
    // () -> T1 <: () -> Q, under constraint T1 <: Q
    _checkConstraintsUpper(
        new FunctionType([], T1, Nullability.legacy),
        new FunctionType([], Q, Nullability.legacy),
        testLib,
        ['T1 <: lib::Q*']);
    // () -> P <: () -> void, always
    _checkConstraintsUpper(new FunctionType([], P, Nullability.legacy),
        new FunctionType([], voidType, Nullability.legacy), testLib, []);
    // () -> void <: () -> P, never
    _checkConstraintsUpper(new FunctionType([], voidType, Nullability.legacy),
        new FunctionType([], P, Nullability.legacy), testLib, null);
  }

  void test_function_trivial_cases() {
    var F = new FunctionType([], dynamicType, Nullability.legacy);
    // () -> dynamic <: dynamic, always
    _checkConstraintsUpper(F, dynamicType, testLib, []);
    // () -> dynamic <: Function, always
    _checkConstraintsUpper(F, functionType, testLib, []);
    // () -> dynamic <: Object, always
    _checkConstraintsUpper(F, coreTypes.objectLegacyRawType, testLib, []);
  }

  void test_nonInferredParameter_subtype_any() {
    var U = new TypeParameterType(
        new TypeParameter('U', _list(P)), Nullability.legacy);
    _checkConstraintsLower(_list(T1), U, testLib, ['lib::P* <: T1']);
  }

  void test_null_subtype_any() {
    _checkConstraintsLower(T1, nullType, testLib, ['dart.core::Null? <: T1']);
    _checkConstraintsUpper(nullType, Q, testLib, []);
  }

  void test_parameter_subtype_any() {
    _checkConstraintsUpper(T1, Q, testLib, ['T1 <: lib::Q*']);
    _checkConstraintsLower(T1, Q, testLib, ['lib::Q* <: T1']);

    _checkConstraintsUpper(S1, Q, testLib, ['S1 <: lib::Q*']);
    _checkConstraintsLower(S1, Q, testLib, ['lib::Q* <: S1']);
    _checkConstraintsUpper(S1.withDeclaredNullability(Nullability.legacy), Q,
        testLib, ['S1 <: lib::Q*']);
    _checkConstraintsLower(S1.withDeclaredNullability(Nullability.legacy), Q,
        testLib, ['lib::Q <: S1']);

    _checkConstraintsUpper(R1, Q, testLib, ['R1 <: lib::Q*']);
    _checkConstraintsLower(R1, Q, testLib, ['lib::Q* <: R1']);
    _checkConstraintsUpper(R1.withDeclaredNullability(Nullability.legacy), Q,
        testLib, ['R1 <: lib::Q*']);
    _checkConstraintsLower(R1.withDeclaredNullability(Nullability.legacy), Q,
        testLib, ['lib::Q <: R1']);
  }

  void test_same_classes() {
    _checkConstraintsUpper(_list(T1), _list(Q), testLib, ['T1 <: lib::Q*']);
  }

  void test_typeParameters() {
    _checkConstraintsUpper(
        _map(T1, T2), _map(P, Q), testLib, ['T1 <: lib::P*', 'T2 <: lib::Q*']);
    _checkConstraintsLower(
        _map(T1, T2), _map(P, Q), testLib, ['lib::P* <: T1', 'lib::Q* <: T2']);

    _checkConstraintsUpper(
        _map(S1, S2), _map(P, Q), testLib, ['S1 <: lib::P*', 'S2 <: lib::Q*']);
    _checkConstraintsLower(
        _map(S1, S2), _map(P, Q), testLib, ['lib::P* <: S1', 'lib::Q* <: S2']);
    _checkConstraintsUpper(
        _map(S1.withDeclaredNullability(Nullability.legacy),
            S2.withDeclaredNullability(Nullability.legacy)),
        _map(P, Q),
        testLib,
        ['S1 <: lib::P*', 'S2 <: lib::Q*']);
    _checkConstraintsLower(
        _map(S1.withDeclaredNullability(Nullability.legacy),
            S2.withDeclaredNullability(Nullability.legacy)),
        _map(P, Q),
        testLib,
        ['lib::P <: S1', 'lib::Q <: S2']);

    _checkConstraintsUpper(
        _map(R1, R2), _map(P, Q), testLib, ['R1 <: lib::P*', 'R2 <: lib::Q*']);
    _checkConstraintsLower(
        _map(R1, R2), _map(P, Q), testLib, ['lib::P* <: R1', 'lib::Q* <: R2']);
    _checkConstraintsUpper(
        _map(R1.withDeclaredNullability(Nullability.legacy),
            R2.withDeclaredNullability(Nullability.legacy)),
        _map(P, Q),
        testLib,
        ['R1 <: lib::P*', 'R2 <: lib::Q*']);
    _checkConstraintsLower(
        _map(R1.withDeclaredNullability(Nullability.legacy),
            R2.withDeclaredNullability(Nullability.legacy)),
        _map(P, Q),
        testLib,
        ['lib::P <: R1', 'lib::Q <: R2']);
  }

  void test_unknown_subtype_any() {
    _checkConstraintsLower(Q, unknownType, testLib, []);
    _checkConstraintsLower(T1, unknownType, testLib, []);
  }

  Class _addClass(Class c) {
    testLib.addClass(c);
    return c;
  }

  void _checkConstraintsLower(DartType type, DartType bound,
      Library clientLibrary, List<String> expectedConstraints) {
    _checkConstraintsHelper(type, bound, clientLibrary, expectedConstraints,
        (gatherer, type, bound) => gatherer.tryConstrainLower(type, bound));
  }

  void _checkConstraintsUpper(DartType type, DartType bound,
      Library clientLibrary, List<String> expectedConstraints) {
    _checkConstraintsHelper(type, bound, clientLibrary, expectedConstraints,
        (gatherer, type, bound) => gatherer.tryConstrainUpper(type, bound));
  }

  void _checkConstraintsHelper(
      DartType a,
      DartType b,
      Library clientLibrary,
      List<String> expectedConstraints,
      bool Function(TypeConstraintGatherer, DartType, DartType) tryConstrain) {
    var typeSchemaEnvironment = new TypeSchemaEnvironment(
        coreTypes, new ClassHierarchy(component, coreTypes));
    var typeConstraintGatherer = new TypeConstraintGatherer(
        typeSchemaEnvironment,
        [
          T1.parameter,
          T2.parameter,
          S1.parameter,
          S2.parameter,
          R1.parameter,
          R2.parameter
        ],
        testLib);
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

  Class _class(String name,
      {Supertype supertype,
      List<TypeParameter> typeParameters,
      List<Supertype> implementedTypes}) {
    return new Class(
        name: name,
        supertype: supertype ?? objectClass.asThisSupertype,
        typeParameters: typeParameters,
        implementedTypes: implementedTypes);
  }

  DartType _iterable(DartType element) =>
      new InterfaceType(iterableClass, Nullability.legacy, [element]);

  DartType _list(DartType element) =>
      new InterfaceType(listClass, Nullability.legacy, [element]);

  DartType _map(DartType key, DartType value) =>
      new InterfaceType(mapClass, Nullability.legacy, [key, value]);
}
