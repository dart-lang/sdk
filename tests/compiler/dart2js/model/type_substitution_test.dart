// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_substitution_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import '../helpers/type_test_helper.dart';

DartType getType(ElementEnvironment elementEnvironment, String name) {
  ClassEntity cls =
      elementEnvironment.lookupClass(elementEnvironment.mainLibrary, 'Class');
  FunctionEntity element = elementEnvironment.lookupClassMember(cls, name);
  Expect.isNotNull(element);
  FunctionType type = elementEnvironment.getFunctionType(element);

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
        new A();
        new B();
        new C();
        new D();
        new E();
        new F();
      }
      ''');
  var types = env.types;
  ClassEntity A = env.getElement("A");
  ClassEntity B = env.getElement("B");
  ClassEntity C = env.getElement("C");
  ClassEntity D = env.getElement("D");
  ClassEntity E = env.getElement("E");
  ClassEntity F = env.getElement("F");

  DartType intType = env['int'];
  DartType stringType = env['String'];

  InterfaceType C_int = instantiate(types, C, [intType]);
  Expect.equals(instantiate(types, C, [intType]), C_int);
  Expect.equals(instantiate(types, A, [intType]), types.asInstanceOf(C_int, A));

  InterfaceType D_int = instantiate(types, D, [stringType]);
  Expect.equals(instantiate(types, A, [intType]), types.asInstanceOf(D_int, A));

  InterfaceType E_int = instantiate(types, E, [intType]);
  Expect.equals(
      instantiate(types, A, [
        instantiate(types, A, [intType])
      ]),
      types.asInstanceOf(E_int, A));

  InterfaceType F_int_string = instantiate(types, F, [intType, stringType]);
  Expect.equals(
      instantiate(types, B, [
        instantiate(types, F, [intType, stringType])
      ]),
      types.asInstanceOf(F_int_string, B));
  Expect.equals(
      instantiate(types, A, [
        instantiate(types, F, [
          instantiate(types, B, [stringType]),
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

      main() => new Class();
      """);
  var types = env.types;
  InterfaceType Class_T_S = env["Class"];
  Expect.isNotNull(Class_T_S);
  Expect.isTrue(Class_T_S is InterfaceType);
  Expect.equals(2, Class_T_S.typeArguments.length);

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

  ClassEntity ListClass = env.getElement('List');
  ClassEntity MapClass = env.getElement('Map');

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
      instantiate(types, ListClass, [intType]),
      instantiate(types, ListClass, [intType]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(types, ListClass, [T]),
      instantiate(types, ListClass, [intType]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(types, ListClass, [S]),
      instantiate(types, ListClass, [StringType]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(types, ListClass, [
        instantiate(types, ListClass, [T])
      ]),
      instantiate(types, ListClass, [
        instantiate(types, ListClass, [intType])
      ]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(types, ListClass, [types.dynamicType()]),
      instantiate(types, ListClass, [types.dynamicType()]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(types, MapClass, [intType, StringType]),
      instantiate(types, MapClass, [intType, StringType]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(types, MapClass, [T, StringType]),
      instantiate(types, MapClass, [intType, StringType]));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(types, MapClass, [types.dynamicType(), StringType]),
      instantiate(types, MapClass, [types.dynamicType(), StringType]));
  testSubstitution(
      types, env.elementEnvironment, arguments, parameters, T, intType);
  testSubstitution(
      types, env.elementEnvironment, arguments, parameters, S, StringType);
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      types.functionType(
          intType, [StringType], [], [], [], [], types.defaultNullability),
      types.functionType(
          intType, [StringType], [], [], [], [], types.defaultNullability));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      types.functionType(
          types.voidType(), [T, S], [], [], [], [], types.defaultNullability),
      types.functionType(types.voidType(), [intType, StringType], [], [], [],
          [], types.defaultNullability));
  testSubstitution(
      types,
      env.elementEnvironment,
      arguments,
      parameters,
      types.functionType(types.voidType(), [types.dynamicType()], [], [], [],
          [], types.defaultNullability),
      types.functionType(types.voidType(), [types.dynamicType()], [], [], [],
          [], types.defaultNullability));
}
