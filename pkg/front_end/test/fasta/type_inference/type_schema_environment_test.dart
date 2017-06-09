// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/incremental_class_hierarchy.dart';
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

  InterfaceType get nullType => coreTypes.nullClass.rawType;

  InterfaceType get numType => coreTypes.numClass.rawType;

  Class get objectClass => coreTypes.objectClass;

  InterfaceType get objectType => objectClass.rawType;

  void test_addLowerBound() {
    var A = _addClass(_class('A')).rawType;
    var B =
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)).rawType;
    var C =
        _addClass(_class('C', supertype: A.classNode.asThisSupertype)).rawType;
    var env = _makeEnv();
    var typeConstraint = new TypeConstraint();
    expect(typeConstraint.lower, same(unknownType));
    env.addLowerBound(typeConstraint, B);
    expect(typeConstraint.lower, same(B));
    env.addLowerBound(typeConstraint, C);
    expect(typeConstraint.lower, same(A));
  }

  void test_addUpperBound() {
    var A = _addClass(_class('A')).rawType;
    var B =
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)).rawType;
    var C =
        _addClass(_class('C', supertype: A.classNode.asThisSupertype)).rawType;
    var env = _makeEnv();
    var typeConstraint = new TypeConstraint();
    expect(typeConstraint.upper, same(unknownType));
    env.addUpperBound(typeConstraint, A);
    expect(typeConstraint.upper, same(A));
    env.addUpperBound(typeConstraint, B);
    expect(typeConstraint.upper, same(B));
    env.addUpperBound(typeConstraint, C);
    expect(typeConstraint.upper, same(bottomType));
  }

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

  void test_inferGenericFunctionOrType() {
    var env = _makeEnv();
    {
      // Test an instantiation of [1, 2.0] with no context.  This should infer
      // as List<?> during downwards inference.
      var inferredTypes = <DartType>[unknownType];
      TypeParameterType T = listClass.thisType.typeArguments[0];
      env.inferGenericFunctionOrType(
          listClass.thisType, [T.parameter], null, null, null, inferredTypes);
      expect(inferredTypes[0], unknownType);
      // And upwards inference should refine it to List<num>.
      env.inferGenericFunctionOrType(listClass.thisType, [T.parameter], [T, T],
          [intType, doubleType], null, inferredTypes);
      expect(inferredTypes[0], numType);
    }
    {
      // Test an instantiation of [1, 2.0] with a context of List<Object>.  This
      // should infer as List<Object> during downwards inference.
      var inferredTypes = <DartType>[unknownType];
      TypeParameterType T = listClass.thisType.typeArguments[0];
      env.inferGenericFunctionOrType(listClass.thisType, [T.parameter], null,
          null, _list(objectType), inferredTypes);
      expect(inferredTypes[0], objectType);
      // And upwards inference should preserve the type.
      env.inferGenericFunctionOrType(listClass.thisType, [T.parameter], [T, T],
          [intType, doubleType], _list(objectType), inferredTypes);
      expect(inferredTypes[0], objectType);
    }
  }

  void test_inferTypeFromConstraints_applyBound() {
    // class A<T extends num> {}
    var T = new TypeParameter('T', numType);
    _addClass(_class('A', typeParameters: [T])).thisType;
    var env = _makeEnv();
    {
      // With no constraints:
      var constraints = {T: new TypeConstraint()};
      // Downward inference should infer A<?>
      var inferredTypes = <DartType>[unknownType];
      env.inferTypeFromConstraints(constraints, [T], inferredTypes,
          downwardsInferPhase: true);
      expect(inferredTypes[0], unknownType);
      // Upward inference should infer A<num>
      env.inferTypeFromConstraints(constraints, [T], inferredTypes);
      expect(inferredTypes[0], numType);
    }
    {
      // With an upper bound of Object:
      var constraints = {T: _makeConstraint(upper: objectType)};
      // Downward inference should infer A<num>
      var inferredTypes = <DartType>[unknownType];
      env.inferTypeFromConstraints(constraints, [T], inferredTypes,
          downwardsInferPhase: true);
      expect(inferredTypes[0], numType);
      // Upward inference should infer A<num>
      env.inferTypeFromConstraints(constraints, [T], inferredTypes);
      expect(inferredTypes[0], numType);
      // Upward inference should still infer A<num> even if there are more
      // constraints now, because num was finalized during downward inference.
      constraints = {T: _makeConstraint(lower: intType, upper: intType)};
      env.inferTypeFromConstraints(constraints, [T], inferredTypes);
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
    env.inferTypeFromConstraints(constraints, [T], inferredTypes,
        downwardsInferPhase: true);
    expect(inferredTypes[0], _list(unknownType));
    // Upwards inference should refine that to List<List<dynamic>>
    env.inferTypeFromConstraints(constraints, [T], inferredTypes);
    expect(inferredTypes[0], _list(dynamicType));
  }

  void test_instantiateToBounds_noTypesKnown() {
    // class A {}
    var A = _addClass(_class('A')).rawType;
    // class B<T extends int> {}
    var B = _addClass(
            _class('B', typeParameters: [new TypeParameter('T', intType)]))
        .thisType;
    // class C<T extends int, S extends B<T>> {}
    var C = () {
      var T = new TypeParameter('T', intType);
      var S = new TypeParameter(
          'S', new InterfaceType(B.classNode, [new TypeParameterType(T)]));
      return _addClass(_class('C', typeParameters: [T, S])).thisType;
    }();
    // class D<T extends B<T>> {}
    var D = () {
      var T = new TypeParameter('T');
      T.bound = new InterfaceType(B.classNode, [new TypeParameterType(T)]);
      return _addClass(_class('D', typeParameters: [T])).thisType;
    }();
    // typedef T E<T extends int>();
    var E = () {
      var T = new TypeParameter('T', intType);
      var typedefNode = new Typedef(
          'E', new FunctionType([], new TypeParameterType(T)),
          typeParameters: [T]);
      return new TypedefType(typedefNode, [new TypeParameterType(T)]);
    }();
    // class F<T> {}
    var F = _addClass(
            _class('F', typeParameters: [new TypeParameter('T', objectType)]))
        .thisType;
    var env = _makeEnv();
    // A => A
    expect(env.instantiateToBounds(A), same(A));
    // B => B<int>
    expect(
        env.instantiateToBounds(B), new InterfaceType(B.classNode, [intType]));
    // C => C<int, A<int>>
    expect(
        env.instantiateToBounds(C),
        new InterfaceType(C.classNode, [
          intType,
          new InterfaceType(B.classNode, [intType])
        ]));
    // D => error
    // However to allow analysis to continue D => D<dynamic>
    // TODO(paulberry): check that an error is reported.
    expect(env.instantiateToBounds(D), D.classNode.rawType);
    // E => E<int> => () -> int
    expect(
        env.instantiateToBounds(E), new TypedefType(E.typedefNode, [intType]));
    // F => F<dynamic>
    expect(env.instantiateToBounds(F), F.classNode.rawType);
  }

  void test_instantiateToBounds_typesKnown() {
    // class A<T extends num> {}
    var A = _addClass(
            _class('A', typeParameters: [new TypeParameter('T', numType)]))
        .thisType;
    // class B<T extends A<T>> {}
    var B = () {
      var T = new TypeParameter('T');
      T.bound = new InterfaceType(A.classNode, [new TypeParameterType(T)]);
      return _addClass(_class('B', typeParameters: [T])).thisType;
    }();
    var env = _makeEnv();
    // A => A<int> (if T known to be `int`)
    expect(
        env.instantiateToBounds(A,
            knownTypes: {A.classNode.typeParameters[0]: intType}),
        new InterfaceType(A.classNode, [intType]));
    // Check that known types can be used to break circularities
    // B => B<int> (if T known to be `int`)
    expect(
        env.instantiateToBounds(B,
            knownTypes: {B.classNode.typeParameters[0]: intType}),
        new InterfaceType(B.classNode, [intType]));
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

  void test_solveTypeConstraint() {
    var A = _addClass(_class('A')).rawType;
    var B =
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)).rawType;
    var env = _makeEnv();
    // Solve(? <: T <: ?) => ?
    expect(env.solveTypeConstraint(_makeConstraint()), same(unknownType));
    // Solve(? <: T <: ?, grounded) => dynamic
    expect(env.solveTypeConstraint(_makeConstraint(), grounded: true),
        dynamicType);
    // Solve(A <: T <: ?) => A
    expect(env.solveTypeConstraint(_makeConstraint(lower: A)), A);
    // Solve(A <: T <: ?, grounded) => A
    expect(
        env.solveTypeConstraint(_makeConstraint(lower: A), grounded: true), A);
    // Solve(A<?> <: T <: ?) => A<?>
    expect(
        env.solveTypeConstraint(_makeConstraint(
            lower: new InterfaceType(A.classNode, [unknownType]))),
        new InterfaceType(A.classNode, [unknownType]));
    // Solve(A<?> <: T <: ?, grounded) => A<Null>
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: new InterfaceType(A.classNode, [unknownType])),
            grounded: true),
        new InterfaceType(A.classNode, [nullType]));
    // Solve(? <: T <: A) => A
    expect(env.solveTypeConstraint(_makeConstraint(upper: A)), A);
    // Solve(? <: T <: A, grounded) => A
    expect(
        env.solveTypeConstraint(_makeConstraint(upper: A), grounded: true), A);
    // Solve(? <: T <: A<?>) => A<?>
    expect(
        env.solveTypeConstraint(_makeConstraint(
            upper: new InterfaceType(A.classNode, [unknownType]))),
        new InterfaceType(A.classNode, [unknownType]));
    // Solve(? <: T <: A<?>, grounded) => A<dynamic>
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                upper: new InterfaceType(A.classNode, [unknownType])),
            grounded: true),
        new InterfaceType(A.classNode, [dynamicType]));
    // Solve(B <: T <: A) => B
    expect(env.solveTypeConstraint(_makeConstraint(lower: B, upper: A)), B);
    // Solve(B <: T <: A, grounded) => B
    expect(
        env.solveTypeConstraint(_makeConstraint(lower: B, upper: A),
            grounded: true),
        B);
    // Solve(B<?> <: T <: A) => A
    expect(
        env.solveTypeConstraint(_makeConstraint(
            lower: new InterfaceType(B.classNode, [unknownType]), upper: A)),
        A);
    // Solve(B<?> <: T <: A, grounded) => A
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: new InterfaceType(B.classNode, [unknownType]), upper: A),
            grounded: true),
        A);
    // Solve(B <: T <: A<?>) => B
    expect(
        env.solveTypeConstraint(_makeConstraint(
            lower: B, upper: new InterfaceType(A.classNode, [unknownType]))),
        B);
    // Solve(B <: T <: A<?>, grounded) => B
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: B, upper: new InterfaceType(A.classNode, [unknownType])),
            grounded: true),
        B);
    // Solve(B<?> <: T <: A<?>) => B<?>
    expect(
        env.solveTypeConstraint(_makeConstraint(
            lower: new InterfaceType(B.classNode, [unknownType]),
            upper: new InterfaceType(A.classNode, [unknownType]))),
        new InterfaceType(B.classNode, [unknownType]));
    // Solve(B<?> <: T <: A<?>) => B<Null>
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: new InterfaceType(B.classNode, [unknownType]),
                upper: new InterfaceType(A.classNode, [unknownType])),
            grounded: true),
        new InterfaceType(B.classNode, [nullType]));
  }

  void test_typeConstraint_default() {
    var typeConstraint = new TypeConstraint();
    expect(typeConstraint.lower, same(unknownType));
    expect(typeConstraint.upper, same(unknownType));
  }

  void test_typeSatisfiesConstraint() {
    var A = _addClass(_class('A')).rawType;
    var B =
        _addClass(_class('B', supertype: A.classNode.asThisSupertype)).rawType;
    var C =
        _addClass(_class('C', supertype: B.classNode.asThisSupertype)).rawType;
    var D =
        _addClass(_class('D', supertype: C.classNode.asThisSupertype)).rawType;
    var E =
        _addClass(_class('E', supertype: D.classNode.asThisSupertype)).rawType;
    var env = _makeEnv();
    var typeConstraint = _makeConstraint(upper: B, lower: D);
    expect(env.typeSatisfiesConstraint(A, typeConstraint), isFalse);
    expect(env.typeSatisfiesConstraint(B, typeConstraint), isTrue);
    expect(env.typeSatisfiesConstraint(C, typeConstraint), isTrue);
    expect(env.typeSatisfiesConstraint(D, typeConstraint), isTrue);
    expect(env.typeSatisfiesConstraint(E, typeConstraint), isFalse);
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

  TypeConstraint _makeConstraint(
      {DartType lower: const UnknownType(),
      DartType upper: const UnknownType()}) {
    return new TypeConstraint()
      ..lower = lower
      ..upper = upper;
  }

  TypeSchemaEnvironment _makeEnv() {
    return new TypeSchemaEnvironment(
        coreTypes, new IncrementalClassHierarchy(), true);
  }

  DartType _map(DartType key, DartType value) =>
      new InterfaceType(mapClass, [key, value]);
}
