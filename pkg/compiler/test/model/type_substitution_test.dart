// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_substitution_test;

import 'package:compiler/src/elements/names.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import '../helpers/type_test_helper.dart';

DartType getType(ElementEnvironment elementEnvironment, String name) {
  ClassEntity cls =
      elementEnvironment.lookupClass(elementEnvironment.mainLibrary!, 'Class')!;
  final element = elementEnvironment.lookupClassMember(
      cls, Name(name, cls.library.canonicalUri)) as FunctionEntity?;
  Expect.isNotNull(element);
  FunctionType type = elementEnvironment.getFunctionType(element!);

  // Function signatures are used to be to provide void types (only occurring as
  // as return types) and (inlined) function types (only occurring as method
  // parameter types).
  //
  // Only a single type is used from each signature. That is, it is not the
  // intention to check the whole signatures against eachother.
  if (type.parameterTypes.isEmpty) {
    // If parameters is empty, use return type.
    return type.returnType;
  } else {
    // Otherwise use the first argument type.
    return type.parameterTypes.first;
  }
}

void main() {
  asyncTest(() async {
    await testAsInstanceOf();
    await testTypeSubstitution();
  });
}

testAsInstanceOf() async {
  var env = await TypeEnvironment.create('''
      class A<T> {}
      class B<T> {}
      class C<T> extends A<T> {}
      class D<T> extends A<int> {}
      class E<T> extends A<A<T>> {}
      class F<T, U> extends B<F<T, String>> implements A<F<B<U>, int>> {}

      main() {
        A();
        B();
        C();
        D();
        E();
        F();
      }
      ''');
  var types = env.types;
  final A = env.getElement("A") as ClassEntity;
  final B = env.getElement("B") as ClassEntity;
  final C = env.getElement("C") as ClassEntity;
  final D = env.getElement("D") as ClassEntity;
  final E = env.getElement("E") as ClassEntity;
  final F = env.getElement("F") as ClassEntity;

  DartType intType = env['int'];
  DartType stringType = env['String'];

  final C_int = env.instantiate(C, [intType]) as InterfaceType;
  Expect.equals(env.instantiate(C, [intType]), C_int);
  Expect.equals(env.instantiate(A, [intType]), types.asInstanceOf(C_int, A));

  final D_int = env.instantiate(D, [stringType]) as InterfaceType;
  Expect.equals(env.instantiate(A, [intType]), types.asInstanceOf(D_int, A));

  final E_int = env.instantiate(E, [intType]) as InterfaceType;
  Expect.equals(
      env.instantiate(A, [
        env.instantiate(A, [intType])
      ]),
      types.asInstanceOf(E_int, A));

  final F_int_string =
      env.instantiate(F, [intType, stringType]) as InterfaceType;
  Expect.equals(
      env.instantiate(B, [
        env.instantiate(F, [intType, stringType])
      ]),
      types.asInstanceOf(F_int_string, B));
  Expect.equals(
      env.instantiate(A, [
        env.instantiate(F, [
          env.instantiate(B, [stringType]),
          intType
        ])
      ]),
      types.asInstanceOf(F_int_string, A));
}

/**
 * Test that substitution of [parameters] by [arguments] in the type found
 * through [name1] is the same as the type found through [name2].
 */
void testSubstitution(
    DartTypes dartTypes,
    ElementEnvironment elementEnvironment,
    List<DartType> arguments,
    List<DartType> parameters,
    DartType type1,
    DartType type2) {
  DartType subst = dartTypes.subst(arguments, parameters, type1);
  Expect.equals(
      type2, subst, "$type1.subst($arguments,$parameters)=$subst != $type2");
}

testTypeSubstitution() async {
  var env = await TypeEnvironment.create(r"""
      class Class<T,S> {}

      main() => Class();
      """);
  var types = env.types;
  final Class_T_S = env["Class"];
  Expect.isNotNull(Class_T_S);
  Expect.isTrue(Class_T_S is InterfaceType);
  Expect.equals(2, (Class_T_S as InterfaceType).typeArguments.length);

  DartType T = Class_T_S.typeArguments[0];
  Expect.isNotNull(T);
  Expect.isTrue(T is TypeVariableType);

  DartType S = Class_T_S.typeArguments[1];
  Expect.isNotNull(S);
  Expect.isTrue(S is TypeVariableType);

  DartType intType = env['int'];
  Expect.isNotNull(intType);
  Expect.isTrue(intType is InterfaceType);

  DartType StringType = env['String'];
  Expect.isNotNull(StringType);
  Expect.isTrue(StringType is InterfaceType);

  final ListClass = env.getElement('List') as ClassEntity;
  final MapClass = env.getElement('Map') as ClassEntity;

  List<DartType> parameters = <DartType>[T, S];
  List<DartType> arguments = <DartType>[intType, StringType];

  testSubstitution(types, env.elementEnvironment, arguments, parameters,
      types.voidType(), types.voidType());
  testSubstitution(types, env.elementEnvironment, arguments, parameters,
      types.dynamicType(), types.dynamicType());
  testSubstitution(
      types, env.elementEnvironment, arguments, parameters, intType, intType);
  testSubstitution(types, env.elementEnvironment, arguments, parameters,
      StringType, StringType);
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      env.instantiate(ListClass, [intType]),
      env.instantiate(ListClass, [intType]));
  testSubstitution(types, env.elementEnvironment, arguments, parameters,
      env.instantiate(ListClass, [T]), env.instantiate(ListClass, [intType]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      env.instantiate(ListClass, [S]),
      env.instantiate(ListClass, [StringType]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      env.instantiate(ListClass, [
        env.instantiate(ListClass, [T])
      ]),
      env.instantiate(ListClass, [
        env.instantiate(ListClass, [intType])
      ]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      env.instantiate(ListClass, [types.dynamicType()]),
      env.instantiate(ListClass, [types.dynamicType()]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      env.instantiate(MapClass, [intType, StringType]),
      env.instantiate(MapClass, [intType, StringType]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      env.instantiate(MapClass, [T, StringType]),
      env.instantiate(MapClass, [intType, StringType]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      env.instantiate(MapClass, [types.dynamicType(), StringType]),
      env.instantiate(MapClass, [types.dynamicType(), StringType]));
  testSubstitution(
      types, env.elementEnvironment, arguments, parameters, T, intType);
  testSubstitution(
      types, env.elementEnvironment, arguments, parameters, S, StringType);
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      types.functionType(intType, [StringType], [], [], {}, [], []),
      types.functionType(intType, [StringType], [], [], {}, [], []));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      types.functionType(types.voidType(), [T, S], [], [], {}, [], []),
      types.functionType(
          types.voidType(), [intType, StringType], [], [], {}, [], []));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      types.functionType(
          types.voidType(), [types.dynamicType()], [], [], {}, [], []),
      types.functionType(
          types.voidType(), [types.dynamicType()], [], [], {}, [], []));
}
