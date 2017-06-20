// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_substitution_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'compiler_helper.dart';
import 'type_test_helper.dart';

ResolutionDartType getType(compiler, String name) {
  dynamic clazz = findElement(compiler, "Class");
  clazz.ensureResolved(compiler.resolution);
  dynamic element = clazz.buildScope().lookup(name);
  Expect.isNotNull(element);
  Expect.equals(element.kind, ElementKind.FUNCTION);
  element.computeType(compiler.resolution);
  FunctionSignature signature = element.functionSignature;

  // Function signatures are used to be to provide void types (only occurring as
  // as return types) and (inlined) function types (only occurring as method
  // parameter types).
  //
  // Only a single type is used from each signature. That is, it is not the
  // intention to check the whole signatures against eachother.
  if (signature.requiredParameterCount == 0) {
    // If parameters is empty, use return type.
    return signature.type.returnType;
  } else {
    // Otherwise use the first argument type.
    return signature.requiredParameters.first.type;
  }
}

void main() {
  testAsInstanceOf();
  testTypeSubstitution();
}

void testAsInstanceOf() {
  asyncTest(() => TypeEnvironment.create('''
      class A<T> {}
      class B<T> {}
      class C<T> extends A<T> {}
      class D<T> extends A<int> {}
      class E<T> extends A<A<T>> {}
      class F<T, U> extends B<F<T, String>> implements A<F<B<U>, int>> {}
      ''').then((env) {
        ClassElement A = env.getElement("A");
        ClassElement B = env.getElement("B");
        ClassElement C = env.getElement("C");
        ClassElement D = env.getElement("D");
        ClassElement E = env.getElement("E");
        ClassElement F = env.getElement("F");

        ResolutionDartType intType = env['int'];
        ResolutionDartType stringType = env['String'];

        ResolutionInterfaceType C_int = instantiate(C, [intType]);
        Expect.equals(instantiate(C, [intType]), C_int);
        Expect.equals(instantiate(A, [intType]), C_int.asInstanceOf(A));

        ResolutionInterfaceType D_int = instantiate(D, [stringType]);
        Expect.equals(instantiate(A, [intType]), D_int.asInstanceOf(A));

        ResolutionInterfaceType E_int = instantiate(E, [intType]);
        Expect.equals(
            instantiate(A, [
              instantiate(A, [intType])
            ]),
            E_int.asInstanceOf(A));

        ResolutionInterfaceType F_int_string =
            instantiate(F, [intType, stringType]);
        Expect.equals(
            instantiate(B, [
              instantiate(F, [intType, stringType])
            ]),
            F_int_string.asInstanceOf(B));
        Expect.equals(
            instantiate(A, [
              instantiate(F, [
                instantiate(B, [stringType]),
                intType
              ])
            ]),
            F_int_string.asInstanceOf(A));
      }));
}

/**
 * Test that substitution of [parameters] by [arguments] in the type found
 * through [name1] is the same as the type found through [name2].
 */
void testSubstitution(
    compiler, arguments, parameters, String name1, String name2) {
  ResolutionDartType type1 = getType(compiler, name1);
  ResolutionDartType type2 = getType(compiler, name2);
  ResolutionDartType subst = type1.subst(arguments, parameters);
  Expect.equals(
      type2, subst, "$type1.subst($arguments,$parameters)=$subst != $type2");
}

void testTypeSubstitution() {
  asyncTest(() => TypeEnvironment.create(r"""
      typedef void Typedef1<X,Y>(X x1, Y y2);
      typedef void Typedef2<Z>(Z z1);

      class Class<T,S> {
        void void1() {}
        void void2() {}
        void dynamic1(dynamic a) {}
        void dynamic2(dynamic b) {}
        void int1(int a) {}
        void int2(int a) {}
        void String1(String a) {}
        void String2(String a) {}
        void ListInt1(List<int> a) {}
        void ListInt2(List<int> b) {}
        void ListT1(List<T> a) {}
        void ListT2(List<int> b) {}
        void ListS1(List<S> a) {}
        void ListS2(List<String> b) {}
        void ListListT1(List<List<T>> a) {}
        void ListListT2(List<List<int>> b) {}
        void ListRaw1(List a) {}
        void ListRaw2(List b) {}
        void ListDynamic1(List<dynamic> a) {}
        void ListDynamic2(List<dynamic> b) {}
        void MapIntString1(Map<T,S> a) {}
        void MapIntString2(Map<int,String> b) {}
        void MapTString1(Map<T,String> a) {}
        void MapTString2(Map<int,String> b) {}
        void MapDynamicString1(Map<dynamic,String> a) {}
        void MapDynamicString2(Map<dynamic,String> b) {}
        void TypeVarT1(T t1) {}
        void TypeVarT2(int t2) {}
        void TypeVarS1(S s1) {}
        void TypeVarS2(String s2) {}
        void Function1a(int a(String s1)) {}
        void Function2a(int b(String s2)) {}
        void Function1b(void a(T t1, S s1)) {}
        void Function2b(void b(int t2, String s2)) {}
        void Function1c(void a(dynamic t1, dynamic s1)) {}
        void Function2c(void b(dynamic t2, dynamic s2)) {}
        void Typedef1a(Typedef1<T,S> a) {}
        void Typedef2a(Typedef1<int,String> b) {}
        void Typedef1b(Typedef1<dynamic,dynamic> a) {}
        void Typedef2b(Typedef1<dynamic,dynamic> b) {}
        void Typedef1c(Typedef1 a) {}
        void Typedef2c(Typedef1 b) {}
        void Typedef1d(Typedef2<T> a) {}
        void Typedef2d(Typedef2<int> b) {}
        void Typedef1e(Typedef2<S> a) {}
        void Typedef2e(Typedef2<String> b) {}
      }
      """).then((env) {
        var compiler = env.compiler;

        ResolutionInterfaceType Class_T_S = env["Class"];
        Expect.isNotNull(Class_T_S);
        Expect.identical(Class_T_S.kind, ResolutionTypeKind.INTERFACE);
        Expect.equals(2, Class_T_S.typeArguments.length);

        ResolutionDartType T = Class_T_S.typeArguments[0];
        Expect.isNotNull(T);
        Expect.identical(T.kind, ResolutionTypeKind.TYPE_VARIABLE);

        ResolutionDartType S = Class_T_S.typeArguments[1];
        Expect.isNotNull(S);
        Expect.identical(S.kind, ResolutionTypeKind.TYPE_VARIABLE);

        ResolutionDartType intType = env['int']; //getType(compiler, "int1");
        Expect.isNotNull(intType);
        Expect.identical(intType.kind, ResolutionTypeKind.INTERFACE);

        ResolutionDartType StringType =
            env['String']; //getType(compiler, "String1");
        Expect.isNotNull(StringType);
        Expect.identical(StringType.kind, ResolutionTypeKind.INTERFACE);

        List<ResolutionDartType> parameters = <ResolutionDartType>[T, S];
        List<ResolutionDartType> arguments = <ResolutionDartType>[
          intType,
          StringType
        ];

        // TODO(johnniwinther): Create types directly from strings to improve test
        // readability.

        testSubstitution(compiler, arguments, parameters, "void1", "void2");
        testSubstitution(
            compiler, arguments, parameters, "dynamic1", "dynamic2");
        testSubstitution(compiler, arguments, parameters, "int1", "int2");
        testSubstitution(compiler, arguments, parameters, "String1", "String2");
        testSubstitution(
            compiler, arguments, parameters, "ListInt1", "ListInt2");
        testSubstitution(compiler, arguments, parameters, "ListT1", "ListT2");
        testSubstitution(compiler, arguments, parameters, "ListS1", "ListS2");
        testSubstitution(
            compiler, arguments, parameters, "ListListT1", "ListListT2");
        testSubstitution(
            compiler, arguments, parameters, "ListRaw1", "ListRaw2");
        testSubstitution(
            compiler, arguments, parameters, "ListDynamic1", "ListDynamic2");
        testSubstitution(
            compiler, arguments, parameters, "MapIntString1", "MapIntString2");
        testSubstitution(
            compiler, arguments, parameters, "MapTString1", "MapTString2");
        testSubstitution(compiler, arguments, parameters, "MapDynamicString1",
            "MapDynamicString2");
        testSubstitution(
            compiler, arguments, parameters, "TypeVarT1", "TypeVarT2");
        testSubstitution(
            compiler, arguments, parameters, "TypeVarS1", "TypeVarS2");
        testSubstitution(
            compiler, arguments, parameters, "Function1a", "Function2a");
        testSubstitution(
            compiler, arguments, parameters, "Function1b", "Function2b");
        testSubstitution(
            compiler, arguments, parameters, "Function1c", "Function2c");
        testSubstitution(
            compiler, arguments, parameters, "Typedef1a", "Typedef2a");
        testSubstitution(
            compiler, arguments, parameters, "Typedef1b", "Typedef2b");
        testSubstitution(
            compiler, arguments, parameters, "Typedef1c", "Typedef2c");
        testSubstitution(
            compiler, arguments, parameters, "Typedef1d", "Typedef2d");
        testSubstitution(
            compiler, arguments, parameters, "Typedef1e", "Typedef2e");

        // Substitution in unalias.
        ResolutionDartType Typedef2_int_String = getType(compiler, "Typedef2a");
        Expect.isNotNull(Typedef2_int_String);
        ResolutionDartType Function_int_String =
            getType(compiler, "Function2b");
        Expect.isNotNull(Function_int_String);
        ResolutionDartType unalias1 = Typedef2_int_String.unaliased;
        Expect.equals(Function_int_String, unalias1,
            '$Typedef2_int_String.unalias=$unalias1 != $Function_int_String');

        ResolutionDartType Typedef1 = getType(compiler, "Typedef1c");
        Expect.isNotNull(Typedef1);
        ResolutionDartType Function_dynamic_dynamic =
            getType(compiler, "Function1c");
        Expect.isNotNull(Function_dynamic_dynamic);
        ResolutionDartType unalias2 = Typedef1.unaliased;
        Expect.equals(Function_dynamic_dynamic, unalias2,
            '$Typedef1.unalias=$unalias2 != $Function_dynamic_dynamic');
      }));
}
