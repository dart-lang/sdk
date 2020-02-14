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
  ClassEntity A = env.getElement("A");
  ClassEntity B = env.getElement("B");
  ClassEntity C = env.getElement("C");
  ClassEntity D = env.getElement("D");
  ClassEntity E = env.getElement("E");
  ClassEntity F = env.getElement("F");

  DartType intType = env['int'];
  DartType stringType = env['String'];

  InterfaceType C_int = instantiate(C, [intType]);
  Expect.equals(instantiate(C, [intType]), C_int);
  Expect.equals(instantiate(A, [intType]), env.types.asInstanceOf(C_int, A));

  InterfaceType D_int = instantiate(D, [stringType]);
  Expect.equals(instantiate(A, [intType]), env.types.asInstanceOf(D_int, A));

  InterfaceType E_int = instantiate(E, [intType]);
  Expect.equals(
      instantiate(A, [
        instantiate(A, [intType])
      ]),
      env.types.asInstanceOf(E_int, A));

  InterfaceType F_int_string = instantiate(F, [intType, stringType]);
  Expect.equals(
      instantiate(B, [
        instantiate(F, [intType, stringType])
      ]),
      env.types.asInstanceOf(F_int_string, B));
  Expect.equals(
      instantiate(A, [
        instantiate(F, [
          instantiate(B, [stringType]),
          intType
        ])
      ]),
      env.types.asInstanceOf(F_int_string, A));
}

/**
 * Test that substitution of [parameters] by [arguments] in the type found
 * through [name1] is the same as the type found through [name2].
 */
void testSubstitution(
    ElementEnvironment elementEnvironment,
    List<DartType> arguments,
    List<DartType> parameters,
    DartType type1,
    DartType type2) {
  DartType subst = type1.subst(arguments, parameters);
  Expect.equals(
      type2, subst, "$type1.subst($arguments,$parameters)=$subst != $type2");
}

testTypeSubstitution() async {
  var env = await TypeEnvironment.create(r"""
      class Class<T,S> {}

      main() => new Class();
      """);
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

  testSubstitution(
      env.elementEnvironment, arguments, parameters, VoidType(), VoidType());
  testSubstitution(env.elementEnvironment, arguments, parameters, DynamicType(),
      DynamicType());
  testSubstitution(
      env.elementEnvironment, arguments, parameters, intType, intType);
  testSubstitution(
      env.elementEnvironment, arguments, parameters, StringType, StringType);
  testSubstitution(env.elementEnvironment, arguments, parameters,
      instantiate(ListClass, [intType]), instantiate(ListClass, [intType]));
  testSubstitution(env.elementEnvironment, arguments, parameters,
      instantiate(ListClass, [T]), instantiate(ListClass, [intType]));
  testSubstitution(env.elementEnvironment, arguments, parameters,
      instantiate(ListClass, [S]), instantiate(ListClass, [StringType]));
  testSubstitution(
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(ListClass, [
        instantiate(ListClass, [T])
      ]),
      instantiate(ListClass, [
        instantiate(ListClass, [intType])
      ]));
  testSubstitution(
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(ListClass, [DynamicType()]),
      instantiate(ListClass, [DynamicType()]));
  testSubstitution(
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(MapClass, [intType, StringType]),
      instantiate(MapClass, [intType, StringType]));
  testSubstitution(
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(MapClass, [T, StringType]),
      instantiate(MapClass, [intType, StringType]));
  testSubstitution(
      env.elementEnvironment,
      arguments,
      parameters,
      instantiate(MapClass, [DynamicType(), StringType]),
      instantiate(MapClass, [DynamicType(), StringType]));
  testSubstitution(env.elementEnvironment, arguments, parameters, T, intType);
  testSubstitution(
      env.elementEnvironment, arguments, parameters, S, StringType);
  testSubstitution(
      env.elementEnvironment,
      arguments,
      parameters,
      new FunctionType(
          intType, [StringType], [], [], [], [], env.types.defaultNullability),
      new FunctionType(
          intType, [StringType], [], [], [], [], env.types.defaultNullability));
  testSubstitution(
      env.elementEnvironment,
      arguments,
      parameters,
      new FunctionType(
          VoidType(), [T, S], [], [], [], [], env.types.defaultNullability),
      new FunctionType(VoidType(), [intType, StringType], [], [], [], [],
          env.types.defaultNullability));
  testSubstitution(
      env.elementEnvironment,
      arguments,
      parameters,
      new FunctionType(VoidType(), [DynamicType()], [], [], [], [],
          env.types.defaultNullability),
      new FunctionType(VoidType(), [DynamicType()], [], [], [], [],
          env.types.defaultNullability));
}
