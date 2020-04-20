// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/testing/mock_sdk_component.dart';
import 'package:kernel/type_environment.dart';
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

  final testLib = new Library(Uri.parse('org-dartlang:///test.dart'));

  Component component;

  CoreTypes coreTypes;

  TypeSchemaEnvironmentTest() {
    component = createMockSdkComponent();
    component.libraries.add(testLib..parent = component);
    coreTypes = new CoreTypes(component);
  }

  InterfaceType get doubleType => coreTypes.doubleLegacyRawType;

  InterfaceType get functionType => coreTypes.functionLegacyRawType;

  InterfaceType get intType => coreTypes.intLegacyRawType;

  Class get iterableClass => coreTypes.iterableClass;

  Class get listClass => coreTypes.listClass;

  Class get mapClass => coreTypes.mapClass;

  InterfaceType get nullType => coreTypes.nullType;

  InterfaceType get numType => coreTypes.numLegacyRawType;

  Class get objectClass => coreTypes.objectClass;

  InterfaceType get objectType => coreTypes.objectLegacyRawType;

  DartType get bottomType => nullType;

  void test_addLowerBound() {
    var A = coreTypes.legacyRawType(_addClass(_class('A')));
    var B = coreTypes.legacyRawType(
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)));
    var C = coreTypes.legacyRawType(
        _addClass(_class('C', supertype: A.classNode.asThisSupertype)));
    var env = _makeEnv();
    var typeConstraint = new TypeConstraint();
    expect(typeConstraint.lower, same(unknownType));
    env.addLowerBound(typeConstraint, B, testLib);
    expect(typeConstraint.lower, same(B));
    env.addLowerBound(typeConstraint, C, testLib);
    expect(typeConstraint.lower, same(A));
  }

  void test_addUpperBound() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var B = coreTypes.rawType(
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var C = coreTypes.rawType(
        _addClass(_class('C', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var env = _makeEnv();
    var typeConstraint = new TypeConstraint();
    expect(typeConstraint.upper, same(unknownType));
    env.addUpperBound(typeConstraint, A, testLib);
    expect(typeConstraint.upper, same(A));
    env.addUpperBound(typeConstraint, B, testLib);
    expect(typeConstraint.upper, same(B));
    env.addUpperBound(typeConstraint, C, testLib);
    expect(typeConstraint.upper, new BottomType());
  }

  void test_glb_bottom() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var env = _makeEnv();
    expect(env.getStandardLowerBound(new BottomType(), A, testLib),
        new BottomType());
    expect(env.getStandardLowerBound(A, new BottomType(), testLib),
        new BottomType());
  }

  void test_glb_function() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var B = coreTypes.rawType(
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var env = _makeEnv();
    // GLB(() -> A, () -> B) = () -> B
    expect(
        env.getStandardLowerBound(new FunctionType([], A, Nullability.legacy),
            new FunctionType([], B, Nullability.legacy), testLib),
        new FunctionType([], B, Nullability.legacy));
    // GLB(() -> void, (A, B) -> void) = ([A, B]) -> void
    expect(
        env.getStandardLowerBound(
            new FunctionType([], voidType, Nullability.legacy),
            new FunctionType([A, B], voidType, Nullability.legacy),
            testLib),
        new FunctionType([A, B], voidType, Nullability.legacy,
            requiredParameterCount: 0));
    expect(
        env.getStandardLowerBound(
            new FunctionType([A, B], voidType, Nullability.legacy),
            new FunctionType([], voidType, Nullability.legacy),
            testLib),
        new FunctionType([A, B], voidType, Nullability.legacy,
            requiredParameterCount: 0));
    // GLB((A) -> void, (B) -> void) = (A) -> void
    expect(
        env.getStandardLowerBound(
            new FunctionType([A], voidType, Nullability.legacy),
            new FunctionType([B], voidType, Nullability.legacy),
            testLib),
        new FunctionType([A], voidType, Nullability.legacy));
    expect(
        env.getStandardLowerBound(
            new FunctionType([B], voidType, Nullability.legacy),
            new FunctionType([A], voidType, Nullability.legacy),
            testLib),
        new FunctionType([A], voidType, Nullability.legacy));
    // GLB(({a: A}) -> void, ({b: B}) -> void) = ({a: A, b: B}) -> void
    expect(
        env.getStandardLowerBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('b', B)]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy,
            namedParameters: [new NamedType('a', A), new NamedType('b', B)]));
    expect(
        env.getStandardLowerBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('b', B)]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy,
            namedParameters: [new NamedType('a', A), new NamedType('b', B)]));
    // GLB(({a: A, c: A}) -> void, ({b: B, d: B}) -> void)
    //     = ({a: A, b: B, c: A, d: B}) -> void
    expect(
        env.getStandardLowerBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('c', A)
                ]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('b', B),
                  new NamedType('d', B)
                ]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy,
            namedParameters: [
              new NamedType('a', A),
              new NamedType('b', B),
              new NamedType('c', A),
              new NamedType('d', B)
            ]));
    // GLB(({a: A, b: B}) -> void, ({a: B, b: A}) -> void)
    //     = ({a: A, b: A}) -> void
    expect(
        env.getStandardLowerBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('b', B)
                ]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', B),
                  new NamedType('b', A)
                ]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy,
            namedParameters: [new NamedType('a', A), new NamedType('b', A)]));
    expect(
        env.getStandardLowerBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', B),
                  new NamedType('b', A)
                ]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('b', B)
                ]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy,
            namedParameters: [new NamedType('a', A), new NamedType('b', A)]));
    // GLB((B, {a: A}) -> void, (B) -> void) = (B, {a: A}) -> void
    expect(
        env.getStandardLowerBound(
            new FunctionType([B], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType, Nullability.legacy),
            testLib),
        new FunctionType([B], voidType, Nullability.legacy,
            namedParameters: [new NamedType('a', A)]));
    // GLB(({a: A}) -> void, (B) -> void) = bottom
    expect(
        env.getStandardLowerBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType, Nullability.legacy),
            testLib),
        new BottomType());
    // GLB(({a: A}) -> void, ([B]) -> void) = bottom
    expect(
        env.getStandardLowerBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType, Nullability.legacy,
                requiredParameterCount: 0),
            testLib),
        new BottomType());
  }

  void test_glb_identical() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var env = _makeEnv();
    expect(env.getStandardLowerBound(A, A, testLib), same(A));
    expect(
        env.getStandardLowerBound(
            new InterfaceType(A.classNode, Nullability.legacy), A, testLib),
        A);
  }

  void test_glb_subtype() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var B = coreTypes.rawType(
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var env = _makeEnv();
    expect(env.getStandardLowerBound(A, B, testLib), same(B));
    expect(env.getStandardLowerBound(B, A, testLib), same(B));
  }

  void test_glb_top() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var env = _makeEnv();
    expect(env.getStandardLowerBound(dynamicType, A, testLib), same(A));
    expect(env.getStandardLowerBound(A, dynamicType, testLib), same(A));
    expect(env.getStandardLowerBound(objectType, A, testLib), same(A));
    expect(env.getStandardLowerBound(A, objectType, testLib), same(A));
    expect(env.getStandardLowerBound(voidType, A, testLib), same(A));
    expect(env.getStandardLowerBound(A, voidType, testLib), same(A));
  }

  void test_glb_unknown() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var env = _makeEnv();
    expect(env.getStandardLowerBound(A, unknownType, testLib), same(A));
    expect(env.getStandardLowerBound(unknownType, A, testLib), same(A));
  }

  void test_glb_unrelated() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var B = coreTypes.rawType(_addClass(_class('B')), Nullability.legacy);
    var env = _makeEnv();
    expect(env.getStandardLowerBound(A, B, testLib), new BottomType());
  }

  void test_inferGenericFunctionOrType() {
    var env = _makeEnv();
    InterfaceType listClassThisType =
        coreTypes.thisInterfaceType(listClass, testLib.nonNullable);
    {
      // Test an instantiation of [1, 2.0] with no context.  This should infer
      // as List<?> during downwards inference.
      var inferredTypes = <DartType>[unknownType];
      TypeParameterType T = listClassThisType.typeArguments[0];
      env.inferGenericFunctionOrType(listClassThisType, [T.parameter], null,
          null, null, inferredTypes, testLib);
      expect(inferredTypes[0], unknownType);
      // And upwards inference should refine it to List<num>.
      env.inferGenericFunctionOrType(listClassThisType, [T.parameter], [T, T],
          [intType, doubleType], null, inferredTypes, testLib);
      expect(inferredTypes[0], numType);
    }
    {
      // Test an instantiation of [1, 2.0] with a context of List<Object>.  This
      // should infer as List<Object> during downwards inference.
      var inferredTypes = <DartType>[unknownType];
      TypeParameterType T = listClassThisType.typeArguments[0];
      env.inferGenericFunctionOrType(listClassThisType, [T.parameter], null,
          null, _list(objectType), inferredTypes, testLib);
      expect(inferredTypes[0], objectType);
      // And upwards inference should preserve the type.
      env.inferGenericFunctionOrType(listClassThisType, [T.parameter], [T, T],
          [intType, doubleType], _list(objectType), inferredTypes, testLib);
      expect(inferredTypes[0], objectType);
    }
  }

  void test_inferTypeFromConstraints_applyBound() {
    // class A<T extends num> {}
    var T = new TypeParameter('T', numType);
    coreTypes.thisInterfaceType(
        _addClass(_class('A', typeParameters: [T])), testLib.nonNullable);
    var env = _makeEnv();
    {
      // With no constraints:
      var constraints = {T: new TypeConstraint()};
      // Downward inference should infer A<?>
      var inferredTypes = <DartType>[unknownType];
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib,
          downwardsInferPhase: true);
      expect(inferredTypes[0], unknownType);
      // Upward inference should infer A<num>
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib);
      expect(inferredTypes[0], numType);
    }
    {
      // With an upper bound of Object:
      var constraints = {T: _makeConstraint(upper: objectType)};
      // Downward inference should infer A<num>
      var inferredTypes = <DartType>[unknownType];
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib,
          downwardsInferPhase: true);
      expect(inferredTypes[0], numType);
      // Upward inference should infer A<num>
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib);
      expect(inferredTypes[0], numType);
      // Upward inference should still infer A<num> even if there are more
      // constraints now, because num was finalized during downward inference.
      constraints = {T: _makeConstraint(lower: intType, upper: intType)};
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib);
      expect(inferredTypes[0], numType);
    }
  }

  void test_inferTypeFromConstraints_simple() {
    var env = _makeEnv();
    var T = listClass.typeParameters[0];
    // With an upper bound of List<?>:
    var constraints = {T: _makeConstraint(upper: _list(unknownType))};
    // Downwards inference should infer List<List<?>>
    var inferredTypes = <DartType>[unknownType];
    env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib,
        downwardsInferPhase: true);
    expect(inferredTypes[0], _list(unknownType));
    // Upwards inference should refine that to List<List<dynamic>>
    env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib);
    expect(inferredTypes[0], _list(dynamicType));
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
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var B = coreTypes.rawType(
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var C = coreTypes.rawType(
        _addClass(_class('C', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var D = coreTypes.rawType(
        _addClass(_class('D', implementedTypes: [
          B.classNode.asThisSupertype,
          C.classNode.asThisSupertype
        ])),
        Nullability.legacy);
    var E = coreTypes.rawType(
        _addClass(_class('E', implementedTypes: [
          B.classNode.asThisSupertype,
          C.classNode.asThisSupertype
        ])),
        Nullability.legacy);
    var env = _makeEnv();
    expect(env.getStandardUpperBound(D, E, testLib), A);
  }

  void test_lub_commonClass() {
    var env = _makeEnv();
    expect(
        env.getStandardUpperBound(_list(intType), _list(doubleType), testLib),
        _list(numType));
  }

  void test_lub_function() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var B = coreTypes.rawType(
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var env = _makeEnv();
    // LUB(() -> A, () -> B) = () -> A
    expect(
        env.getStandardUpperBound(new FunctionType([], A, Nullability.legacy),
            new FunctionType([], B, Nullability.legacy), testLib),
        new FunctionType([], A, Nullability.legacy));
    // LUB(([A]) -> void, (A) -> void) = Function
    expect(
        env.getStandardUpperBound(
            new FunctionType([A], voidType, Nullability.legacy,
                requiredParameterCount: 0),
            new FunctionType([A], voidType, Nullability.legacy),
            testLib),
        functionType);
    // LUB(() -> void, (A, B) -> void) = Function
    expect(
        env.getStandardUpperBound(
            new FunctionType([], voidType, Nullability.legacy),
            new FunctionType([A, B], voidType, Nullability.legacy),
            testLib),
        functionType);
    expect(
        env.getStandardUpperBound(
            new FunctionType([A, B], voidType, Nullability.legacy),
            new FunctionType([], voidType, Nullability.legacy),
            testLib),
        functionType);
    // LUB((A) -> void, (B) -> void) = (B) -> void
    expect(
        env.getStandardUpperBound(
            new FunctionType([A], voidType, Nullability.legacy),
            new FunctionType([B], voidType, Nullability.legacy),
            testLib),
        new FunctionType([B], voidType, Nullability.legacy));
    expect(
        env.getStandardUpperBound(
            new FunctionType([B], voidType, Nullability.legacy),
            new FunctionType([A], voidType, Nullability.legacy),
            testLib),
        new FunctionType([B], voidType, Nullability.legacy));
    // LUB(({a: A}) -> void, ({b: B}) -> void) = () -> void
    expect(
        env.getStandardUpperBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('b', B)]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy));
    expect(
        env.getStandardUpperBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('b', B)]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy));
    // LUB(({a: A, c: A}) -> void, ({b: B, d: B}) -> void) = () -> void
    expect(
        env.getStandardUpperBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('c', A)
                ]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('b', B),
                  new NamedType('d', B)
                ]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy));
    // LUB(({a: A, b: B}) -> void, ({a: B, b: A}) -> void)
    //     = ({a: B, b: B}) -> void
    expect(
        env.getStandardUpperBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('b', B)
                ]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', B),
                  new NamedType('b', A)
                ]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy,
            namedParameters: [new NamedType('a', B), new NamedType('b', B)]));
    expect(
        env.getStandardUpperBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', B),
                  new NamedType('b', A)
                ]),
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [
                  new NamedType('a', A),
                  new NamedType('b', B)
                ]),
            testLib),
        new FunctionType([], voidType, Nullability.legacy,
            namedParameters: [new NamedType('a', B), new NamedType('b', B)]));
    // LUB((B, {a: A}) -> void, (B) -> void) = (B) -> void
    expect(
        env.getStandardUpperBound(
            new FunctionType([B], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType, Nullability.legacy),
            testLib),
        new FunctionType([B], voidType, Nullability.legacy));
    // LUB(({a: A}) -> void, (B) -> void) = Function
    expect(
        env.getStandardUpperBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType, Nullability.legacy),
            testLib),
        functionType);
    // GLB(({a: A}) -> void, ([B]) -> void) = () -> void
    expect(
        env.getStandardUpperBound(
            new FunctionType([], voidType, Nullability.legacy,
                namedParameters: [new NamedType('a', A)]),
            new FunctionType([B], voidType, Nullability.legacy,
                requiredParameterCount: 0),
            testLib),
        new FunctionType([], voidType, Nullability.legacy));
  }

  void test_lub_identical() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var env = _makeEnv();
    expect(env.getStandardUpperBound(A, A, testLib), same(A));
    expect(
        env.getStandardUpperBound(
            new InterfaceType(A.classNode, Nullability.legacy), A, testLib),
        A);
  }

  void test_lub_sameClass() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var B = coreTypes.rawType(
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var env = _makeEnv();
    expect(
        env.getStandardUpperBound(_map(A, B), _map(B, A), testLib), _map(A, A));
  }

  void test_lub_subtype() {
    var env = _makeEnv();
    expect(
        env.getStandardUpperBound(_list(intType), _iterable(numType), testLib),
        _iterable(numType));
    expect(
        env.getStandardUpperBound(_iterable(numType), _list(intType), testLib),
        _iterable(numType));
  }

  void test_lub_top() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var env = _makeEnv();
    expect(
        env.getStandardUpperBound(dynamicType, A, testLib), same(dynamicType));
    expect(
        env.getStandardUpperBound(A, dynamicType, testLib), same(dynamicType));
    expect(env.getStandardUpperBound(objectType, A, testLib), same(objectType));
    expect(env.getStandardUpperBound(A, objectType, testLib), same(objectType));
    expect(env.getStandardUpperBound(voidType, A, testLib), same(voidType));
    expect(env.getStandardUpperBound(A, voidType, testLib), same(voidType));
    expect(env.getStandardUpperBound(dynamicType, objectType, testLib),
        same(dynamicType));
    expect(env.getStandardUpperBound(objectType, dynamicType, testLib),
        same(dynamicType));
    expect(env.getStandardUpperBound(dynamicType, voidType, testLib),
        same(voidType));
    expect(env.getStandardUpperBound(voidType, dynamicType, testLib),
        same(voidType));
    expect(env.getStandardUpperBound(objectType, voidType, testLib),
        same(voidType));
    expect(env.getStandardUpperBound(voidType, objectType, testLib),
        same(voidType));
  }

  void test_lub_typeParameter() {
    var T = new TypeParameterType(new TypeParameter('T'), Nullability.legacy);
    T.parameter.bound = _list(T);
    var U = new TypeParameterType(new TypeParameter('U'), Nullability.legacy);
    U.parameter.bound = _list(new BottomType());
    var env = _makeEnv();
    // LUB(T, T) = T
    expect(env.getStandardUpperBound(T, T, testLib), same(T));
    // LUB(T, List<Bottom>) = LUB(List<Object>, List<Bottom>) = List<Object>
    expect(env.getStandardUpperBound(T, _list(new BottomType()), testLib),
        _list(objectType));
    expect(env.getStandardUpperBound(_list(new BottomType()), T, testLib),
        _list(objectType));
    // LUB(T, U) = LUB(List<Object>, U) = LUB(List<Object>, List<Bottom>)
    // = List<Object>
    expect(env.getStandardUpperBound(T, U, testLib), _list(objectType));
    expect(env.getStandardUpperBound(U, T, testLib), _list(objectType));
  }

  void test_lub_unknown() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var env = _makeEnv();
    expect(env.getStandardLowerBound(A, unknownType, testLib), same(A));
    expect(env.getStandardLowerBound(unknownType, A, testLib), same(A));
  }

  void test_solveTypeConstraint() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var B = coreTypes.rawType(
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var env = _makeEnv();
    // Solve(? <: T <: ?) => ?
    expect(env.solveTypeConstraint(_makeConstraint(), bottomType),
        same(unknownType));
    // Solve(? <: T <: ?, grounded) => dynamic
    expect(
        env.solveTypeConstraint(_makeConstraint(), bottomType, grounded: true),
        dynamicType);
    // Solve(A <: T <: ?) => A
    expect(env.solveTypeConstraint(_makeConstraint(lower: A), bottomType), A);
    // Solve(A <: T <: ?, grounded) => A
    expect(
        env.solveTypeConstraint(_makeConstraint(lower: A), bottomType,
            grounded: true),
        A);
    // Solve(A<?> <: T <: ?) => A<?>
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: new InterfaceType(
                    A.classNode, Nullability.legacy, [unknownType])),
            bottomType),
        new InterfaceType(A.classNode, Nullability.legacy, [unknownType]));
    // Solve(A<?> <: T <: ?, grounded) => A<Null>
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: new InterfaceType(
                    A.classNode, Nullability.legacy, [unknownType])),
            bottomType,
            grounded: true),
        new InterfaceType(A.classNode, Nullability.legacy, [nullType]));
    // Solve(? <: T <: A) => A
    expect(env.solveTypeConstraint(_makeConstraint(upper: A), bottomType), A);
    // Solve(? <: T <: A, grounded) => A
    expect(
        env.solveTypeConstraint(_makeConstraint(upper: A), bottomType,
            grounded: true),
        A);
    // Solve(? <: T <: A<?>) => A<?>
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                upper: new InterfaceType(
                    A.classNode, Nullability.legacy, [unknownType])),
            bottomType),
        new InterfaceType(A.classNode, Nullability.legacy, [unknownType]));
    // Solve(? <: T <: A<?>, grounded) => A<dynamic>
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                upper: new InterfaceType(
                    A.classNode, Nullability.legacy, [unknownType])),
            bottomType,
            grounded: true),
        new InterfaceType(A.classNode, Nullability.legacy, [dynamicType]));
    // Solve(B <: T <: A) => B
    expect(
        env.solveTypeConstraint(
            _makeConstraint(lower: B, upper: A), bottomType),
        B);
    // Solve(B <: T <: A, grounded) => B
    expect(
        env.solveTypeConstraint(_makeConstraint(lower: B, upper: A), bottomType,
            grounded: true),
        B);
    // Solve(B<?> <: T <: A) => A
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: new InterfaceType(
                    B.classNode, Nullability.legacy, [unknownType]),
                upper: A),
            bottomType),
        A);
    // Solve(B<?> <: T <: A, grounded) => A
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: new InterfaceType(
                    B.classNode, Nullability.legacy, [unknownType]),
                upper: A),
            bottomType,
            grounded: true),
        A);
    // Solve(B <: T <: A<?>) => B
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: B,
                upper: new InterfaceType(
                    A.classNode, Nullability.legacy, [unknownType])),
            bottomType),
        B);
    // Solve(B <: T <: A<?>, grounded) => B
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: B,
                upper: new InterfaceType(
                    A.classNode, Nullability.legacy, [unknownType])),
            bottomType,
            grounded: true),
        B);
    // Solve(B<?> <: T <: A<?>) => B<?>
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: new InterfaceType(
                    B.classNode, Nullability.legacy, [unknownType]),
                upper: new InterfaceType(
                    A.classNode, Nullability.legacy, [unknownType])),
            bottomType),
        new InterfaceType(B.classNode, Nullability.legacy, [unknownType]));
    // Solve(B<?> <: T <: A<?>) => B<Null>
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: new InterfaceType(
                    B.classNode, Nullability.legacy, [unknownType]),
                upper: new InterfaceType(
                    A.classNode, Nullability.legacy, [unknownType])),
            bottomType,
            grounded: true),
        new InterfaceType(B.classNode, Nullability.legacy, [nullType]));
  }

  void test_typeConstraint_default() {
    var typeConstraint = new TypeConstraint();
    expect(typeConstraint.lower, same(unknownType));
    expect(typeConstraint.upper, same(unknownType));
  }

  void test_typeSatisfiesConstraint() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var B = coreTypes.rawType(
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)),
        Nullability.legacy);
    var C = coreTypes.rawType(
        _addClass(_class('C', supertype: B.classNode.asThisSupertype)),
        Nullability.legacy);
    var D = coreTypes.rawType(
        _addClass(_class('D', supertype: C.classNode.asThisSupertype)),
        Nullability.legacy);
    var E = coreTypes.rawType(
        _addClass(_class('E', supertype: D.classNode.asThisSupertype)),
        Nullability.legacy);
    var env = _makeEnv();
    var typeConstraint = _makeConstraint(upper: B, lower: D);
    expect(env.typeSatisfiesConstraint(A, typeConstraint), isFalse);
    expect(env.typeSatisfiesConstraint(B, typeConstraint), isTrue);
    expect(env.typeSatisfiesConstraint(C, typeConstraint), isTrue);
    expect(env.typeSatisfiesConstraint(D, typeConstraint), isTrue);
    expect(env.typeSatisfiesConstraint(E, typeConstraint), isFalse);
  }

  void test_unknown_at_bottom() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var env = _makeEnv();
    expect(
        env.isSubtypeOf(unknownType, A, SubtypeCheckMode.ignoringNullabilities),
        isTrue);
  }

  void test_unknown_at_top() {
    var A = coreTypes.rawType(_addClass(_class('A')), Nullability.legacy);
    var env = _makeEnv();
    expect(
        env.isSubtypeOf(A, unknownType, SubtypeCheckMode.ignoringNullabilities),
        isTrue);
    expect(
        env.isSubtypeOf(_map(A, A), _map(unknownType, unknownType),
            SubtypeCheckMode.ignoringNullabilities),
        isTrue);
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
      new InterfaceType(iterableClass, Nullability.legacy, [elementType]);

  DartType _list(DartType elementType) =>
      new InterfaceType(listClass, Nullability.legacy, [elementType]);

  TypeConstraint _makeConstraint(
      {DartType lower: const UnknownType(),
      DartType upper: const UnknownType()}) {
    return new TypeConstraint()
      ..lower = lower
      ..upper = upper;
  }

  TypeSchemaEnvironment _makeEnv() {
    return new TypeSchemaEnvironment(
        coreTypes, new ClassHierarchy(component, coreTypes));
  }

  DartType _map(DartType key, DartType value) =>
      new InterfaceType(mapClass, Nullability.legacy, [key, value]);
}
