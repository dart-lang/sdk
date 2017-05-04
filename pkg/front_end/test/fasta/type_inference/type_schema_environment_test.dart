// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/testing/mock_sdk_program.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeSchemaEnvironmentTest);
  });
}

@reflectiveTest
class TypeSchemaEnvironmentTest {
  static const UnknownType unknownType = const UnknownType();

  static const DynamicType dynamicType = const DynamicType();

  static const VoidType voidType = const VoidType();

  static const BottomType bottomType = const BottomType();

  final testLib = new Library(Uri.parse('org-dartlang:///test.dart'));

  Program program;

  CoreTypes coreTypes;

  TypeSchemaEnvironmentTest() {
    program = createMockSdkProgram();
    program.libraries.add(testLib..parent = program);
    coreTypes = new CoreTypes(program);
  }

  InterfaceType get doubleType => coreTypes.doubleClass.rawType;

  InterfaceType get functionType => coreTypes.functionClass.rawType;

  InterfaceType get intType => coreTypes.intClass.rawType;

  Class get iterableClass => coreTypes.iterableClass;

  Class get listClass => coreTypes.listClass;

  Class get mapClass => coreTypes.mapClass;

  InterfaceType get numType => coreTypes.numClass.rawType;

  Class get objectClass => coreTypes.objectClass;

  InterfaceType get objectType => objectClass.rawType;

  void test_glb_bottom() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.getGreatestLowerBound(bottomType, A), same(bottomType));
    expect(env.getGreatestLowerBound(A, bottomType), same(bottomType));
  }

  void test_glb_function() {
    var A = _addClass(_class('A')).rawType;
    var B =
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)).rawType;
    var env = _makeEnv();
    // GLB(() -> A, () -> B) = () -> B
    expect(
        env.getGreatestLowerBound(
            new FunctionType([], A), new FunctionType([], B)),
        new FunctionType([], B));
    // GLB(() -> void, (A, B) -> void) = ([A, B]) -> void
    expect(
        env.getGreatestLowerBound(
            new FunctionType([], voidType), new FunctionType([A, B], voidType)),
        new FunctionType([A, B], voidType, requiredParameterCount: 0));
    expect(
        env.getGreatestLowerBound(
            new FunctionType([A, B], voidType), new FunctionType([], voidType)),
        new FunctionType([A, B], voidType, requiredParameterCount: 0));
    // GLB((A) -> void, (B) -> void) = (A) -> void
    expect(
        env.getGreatestLowerBound(
            new FunctionType([A], voidType), new FunctionType([B], voidType)),
        new FunctionType([A], voidType));
    expect(
        env.getGreatestLowerBound(
            new FunctionType([B], voidType), new FunctionType([A], voidType)),
        new FunctionType([A], voidType));
    // GLB(({a: A}) -> void, ({b: B}) -> void) = ({a: A, b: B}) -> void
    expect(
        env.getGreatestLowerBound(
            new FunctionType([], voidType,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([], voidType,
                namedParameters: [new NamedType('b', B)])),
        new FunctionType([], voidType,
            namedParameters: [new NamedType('a', A), new NamedType('b', B)]));
    expect(
        env.getGreatestLowerBound(
            new FunctionType([], voidType,
                namedParameters: [new NamedType('b', B)]),
            new FunctionType([], voidType,
                namedParameters: [new NamedType('a', A)])),
        new FunctionType([], voidType,
            namedParameters: [new NamedType('a', A), new NamedType('b', B)]));
    // GLB(({a: A, c: A}) -> void, ({b: B, d: B}) -> void)
    //     = ({a: A, b: B, c: A, d: B}) -> void
    expect(
        env.getGreatestLowerBound(
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('c', A)
                ]),
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('b', B),
                  new NamedType('d', B)
                ])),
        new FunctionType([], voidType,
            namedParameters: [
              new NamedType('a', A),
              new NamedType('b', B),
              new NamedType('c', A),
              new NamedType('d', B)
            ]));
    // GLB(({a: A, b: B}) -> void, ({a: B, b: A}) -> void)
    //     = ({a: A, b: A}) -> void
    expect(
        env.getGreatestLowerBound(
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('b', B)
                ]),
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', B),
                  new NamedType('b', A)
                ])),
        new FunctionType([], voidType,
            namedParameters: [new NamedType('a', A), new NamedType('b', A)]));
    expect(
        env.getGreatestLowerBound(
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', B),
                  new NamedType('b', A)
                ]),
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('b', B)
                ])),
        new FunctionType([], voidType,
            namedParameters: [new NamedType('a', A), new NamedType('b', A)]));
    // GLB((B, {a: A}) -> void, (B) -> void) = (B, {a: A}) -> void
    expect(
        env.getGreatestLowerBound(
            new FunctionType([B], voidType,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType)),
        new FunctionType([B], voidType,
            namedParameters: [new NamedType('a', A)]));
    // GLB(({a: A}) -> void, (B) -> void) = bottom
    expect(
        env.getGreatestLowerBound(
            new FunctionType([], voidType,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType)),
        same(bottomType));
    // GLB(({a: A}) -> void, ([B]) -> void) = bottom
    expect(
        env.getGreatestLowerBound(
            new FunctionType([], voidType,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType, requiredParameterCount: 0)),
        same(bottomType));
  }

  void test_glb_identical() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.getGreatestLowerBound(A, A), same(A));
    expect(env.getGreatestLowerBound(new InterfaceType(A.classNode), A), A);
  }

  void test_glb_subtype() {
    var A = _addClass(_class('A')).rawType;
    var B =
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)).rawType;
    var env = _makeEnv();
    expect(env.getGreatestLowerBound(A, B), same(B));
    expect(env.getGreatestLowerBound(B, A), same(B));
  }

  void test_glb_top() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.getGreatestLowerBound(dynamicType, A), same(A));
    expect(env.getGreatestLowerBound(A, dynamicType), same(A));
    expect(env.getGreatestLowerBound(objectType, A), same(A));
    expect(env.getGreatestLowerBound(A, objectType), same(A));
    expect(env.getGreatestLowerBound(voidType, A), same(A));
    expect(env.getGreatestLowerBound(A, voidType), same(A));
  }

  void test_glb_unknown() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.getGreatestLowerBound(A, unknownType), same(A));
    expect(env.getGreatestLowerBound(unknownType, A), same(A));
  }

  void test_glb_unrelated() {
    var A = _addClass(_class('A')).rawType;
    var B = _addClass(_class('B')).rawType;
    var env = _makeEnv();
    expect(env.getGreatestLowerBound(A, B), same(bottomType));
  }

  void test_lub_bottom() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.getLeastUpperBound(bottomType, A), same(A));
    expect(env.getLeastUpperBound(A, bottomType), same(A));
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
    var A = _addClass(_class('A')).rawType;
    var B =
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)).rawType;
    var C =
        _addClass(_class('C', supertype: A.classNode.asThisSupertype)).rawType;
    var D = _addClass(_class('D', implementedTypes: [
      B.classNode.asThisSupertype,
      C.classNode.asThisSupertype
    ])).rawType;
    var E = _addClass(_class('E', implementedTypes: [
      B.classNode.asThisSupertype,
      C.classNode.asThisSupertype
    ])).rawType;
    var env = _makeEnv();
    expect(env.getLeastUpperBound(D, E), A);
  }

  void test_lub_commonClass() {
    var env = _makeEnv();
    expect(env.getLeastUpperBound(_list(intType), _list(doubleType)),
        _list(numType));
  }

  void test_lub_function() {
    var A = _addClass(_class('A')).rawType;
    var B =
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)).rawType;
    var env = _makeEnv();
    // LUB(() -> A, () -> B) = () -> A
    expect(
        env.getLeastUpperBound(
            new FunctionType([], A), new FunctionType([], B)),
        new FunctionType([], A));
    // LUB(([A]) -> void, (A) -> void) = Function
    expect(
        env.getLeastUpperBound(
            new FunctionType([A], voidType, requiredParameterCount: 0),
            new FunctionType([A], voidType)),
        functionType);
    // LUB(() -> void, (A, B) -> void) = Function
    expect(
        env.getLeastUpperBound(
            new FunctionType([], voidType), new FunctionType([A, B], voidType)),
        functionType);
    expect(
        env.getLeastUpperBound(
            new FunctionType([A, B], voidType), new FunctionType([], voidType)),
        functionType);
    // LUB((A) -> void, (B) -> void) = (B) -> void
    expect(
        env.getLeastUpperBound(
            new FunctionType([A], voidType), new FunctionType([B], voidType)),
        new FunctionType([B], voidType));
    expect(
        env.getLeastUpperBound(
            new FunctionType([B], voidType), new FunctionType([A], voidType)),
        new FunctionType([B], voidType));
    // LUB(({a: A}) -> void, ({b: B}) -> void) = () -> void
    expect(
        env.getLeastUpperBound(
            new FunctionType([], voidType,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([], voidType,
                namedParameters: [new NamedType('b', B)])),
        new FunctionType([], voidType));
    expect(
        env.getLeastUpperBound(
            new FunctionType([], voidType,
                namedParameters: [new NamedType('b', B)]),
            new FunctionType([], voidType,
                namedParameters: [new NamedType('a', A)])),
        new FunctionType([], voidType));
    // LUB(({a: A, c: A}) -> void, ({b: B, d: B}) -> void) = () -> void
    expect(
        env.getLeastUpperBound(
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('c', A)
                ]),
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('b', B),
                  new NamedType('d', B)
                ])),
        new FunctionType([], voidType));
    // LUB(({a: A, b: B}) -> void, ({a: B, b: A}) -> void)
    //     = ({a: B, b: B}) -> void
    expect(
        env.getLeastUpperBound(
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('b', B)
                ]),
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', B),
                  new NamedType('b', A)
                ])),
        new FunctionType([], voidType,
            namedParameters: [new NamedType('a', B), new NamedType('b', B)]));
    expect(
        env.getLeastUpperBound(
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', B),
                  new NamedType('b', A)
                ]),
            new FunctionType([], voidType,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('b', B)
                ])),
        new FunctionType([], voidType,
            namedParameters: [new NamedType('a', B), new NamedType('b', B)]));
    // LUB((B, {a: A}) -> void, (B) -> void) = (B) -> void
    expect(
        env.getLeastUpperBound(
            new FunctionType([B], voidType,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType)),
        new FunctionType([B], voidType));
    // LUB(({a: A}) -> void, (B) -> void) = Function
    expect(
        env.getLeastUpperBound(
            new FunctionType([], voidType,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType)),
        functionType);
    // GLB(({a: A}) -> void, ([B]) -> void) = () -> void
    expect(
        env.getLeastUpperBound(
            new FunctionType([], voidType,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType, requiredParameterCount: 0)),
        new FunctionType([], voidType));
  }

  void test_lub_identical() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.getLeastUpperBound(A, A), same(A));
    expect(env.getLeastUpperBound(new InterfaceType(A.classNode), A), A);
  }

  void test_lub_sameClass() {
    var A = _addClass(_class('A')).rawType;
    var B =
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)).rawType;
    var env = _makeEnv();
    expect(env.getLeastUpperBound(_map(A, B), _map(B, A)), _map(A, A));
  }

  void test_lub_subtype() {
    var env = _makeEnv();
    expect(env.getLeastUpperBound(_list(intType), _iterable(numType)),
        _iterable(numType));
    expect(env.getLeastUpperBound(_iterable(numType), _list(intType)),
        _iterable(numType));
  }

  void test_lub_top() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.getLeastUpperBound(dynamicType, A), same(dynamicType));
    expect(env.getLeastUpperBound(A, dynamicType), same(dynamicType));
    expect(env.getLeastUpperBound(objectType, A), same(objectType));
    expect(env.getLeastUpperBound(A, objectType), same(objectType));
    expect(env.getLeastUpperBound(voidType, A), same(voidType));
    expect(env.getLeastUpperBound(A, voidType), same(voidType));
    expect(env.getLeastUpperBound(dynamicType, objectType), same(dynamicType));
    // TODO(paulberry): see dartbug.com/28513.
    expect(env.getLeastUpperBound(objectType, dynamicType), same(objectType));
    expect(env.getLeastUpperBound(dynamicType, voidType), same(dynamicType));
    expect(env.getLeastUpperBound(voidType, dynamicType), same(dynamicType));
    expect(env.getLeastUpperBound(objectType, voidType), same(voidType));
    expect(env.getLeastUpperBound(voidType, objectType), same(voidType));
  }

  void test_lub_typeParameter() {
    var T = new TypeParameterType(new TypeParameter('T'));
    T.parameter.bound = _list(T);
    var U = new TypeParameterType(new TypeParameter('U'));
    U.parameter.bound = _list(bottomType);
    var env = _makeEnv();
    // LUB(T, T) = T
    expect(env.getLeastUpperBound(T, T), same(T));
    // LUB(T, List<Bottom>) = LUB(List<Object>, List<Bottom>) = List<Object>
    expect(env.getLeastUpperBound(T, _list(bottomType)), _list(objectType));
    expect(env.getLeastUpperBound(_list(bottomType), T), _list(objectType));
    // LUB(T, U) = LUB(List<Object>, U) = LUB(List<Object>, List<Bottom>)
    // = List<Object>
    expect(env.getLeastUpperBound(T, U), _list(objectType));
    expect(env.getLeastUpperBound(U, T), _list(objectType));
  }

  void test_lub_unknown() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.getGreatestLowerBound(A, unknownType), same(A));
    expect(env.getGreatestLowerBound(unknownType, A), same(A));
  }

  void test_unknown_at_bottom() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.isSubtypeOf(unknownType, A), isTrue);
  }

  void test_unknown_at_top() {
    var A = _addClass(_class('A')).rawType;
    var env = _makeEnv();
    expect(env.isSubtypeOf(A, unknownType), isTrue);
  }

  Class _addClass(Class c) {
    testLib.addClass(c);
    return c;
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

  DartType _iterable(DartType elementType) =>
      new InterfaceType(iterableClass, [elementType]);

  DartType _list(DartType elementType) =>
      new InterfaceType(listClass, [elementType]);

  TypeSchemaEnvironment _makeEnv() {
    return new TypeSchemaEnvironment(coreTypes, new ClassHierarchy(program));
  }

  DartType _map(DartType key, DartType value) =>
      new InterfaceType(mapClass, [key, value]);
}
