// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_substitution_test;

import "../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart";
import "../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart";
import "../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart";
import "../../../sdk/lib/_internal/compiler/implementation/util/util.dart";
import "compiler_helper.dart";
import "parser_helper.dart";
import "dart:uri";

DartType getElementType(compiler, String name) {
  var element = findElement(compiler, name);
  Expect.isNotNull(element);
  if (identical(element.kind, ElementKind.CLASS)) {
    element.ensureResolved(compiler);
  }
  return element.computeType(compiler);
}

DartType getType(compiler, String name) {
  var clazz = findElement(compiler, "Class");
  clazz.ensureResolved(compiler);
  var element = clazz.buildScope().lookup(buildSourceString(name));
  Expect.isNotNull(element);
  Expect.equals(element.kind, ElementKind.FUNCTION);
  FunctionSignature signature = element.computeSignature(compiler);

  // Function signatures are used to be to provide void types (only occuring as
  // as return types) and (inlined) function types (only occuring as method
  // parameter types).
  //
  // Only a single type is used from each signature. That is, it is not the
  // intention to check the whole signatures against eachother.
  if (signature.requiredParameterCount == 0) {
    // If parameters is empty, use return type.
    return signature.returnType;
  } else {
    // Otherwise use the first argument type.
    return signature.requiredParameters.head.computeType(compiler);
  }
}

int length(Link link) {
  int count = 0;
  while (!link.isEmpty) {
    count++;
    link = link.tail;
  }
  return count;
}

/**
 * Test that substitution of [parameters] by [arguments] in the type found
 * through [name1] is the same as the type found through [name2].
 */
bool test(compiler, arguments, parameters,
          String name1, String name2) {
  DartType type1 = getType(compiler, name1);
  DartType type2 = getType(compiler, name2);
  DartType subst = type1.subst(arguments, parameters);
  print('$type1.subst($arguments,$parameters)=$subst');
  Expect.equals(type2, subst,
      "$type1.subst($arguments,$parameters)=$subst != $type2");
}


void main() {
  var uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(
      r"""
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

      void main() {}
      """,
      uri);
  compiler.runCompiler(uri);

  DartType Class_T_S = getElementType(compiler, "Class");
  Expect.isNotNull(Class_T_S);
  Expect.identical(Class_T_S.kind, TypeKind.INTERFACE);
  Expect.equals(2, length(Class_T_S.typeArguments));

  DartType T = Class_T_S.typeArguments.head;
  Expect.isNotNull(T);
  Expect.identical(T.kind, TypeKind.TYPE_VARIABLE);

  DartType S = Class_T_S.typeArguments.tail.head;
  Expect.isNotNull(S);
  Expect.identical(S.kind, TypeKind.TYPE_VARIABLE);

  DartType intType = getType(compiler, "int1");
  Expect.isNotNull(intType);
  Expect.identical(intType.kind, TypeKind.INTERFACE);

  DartType StringType = getType(compiler, "String1");
  Expect.isNotNull(StringType);
  Expect.identical(StringType.kind, TypeKind.INTERFACE);

  var parameters = new Link<DartType>.fromList(<DartType>[T, S]);
  var arguments = new Link<DartType>.fromList(<DartType>[intType, StringType]);

  // TODO(johnniwinther): Create types directly from strings to improve test
  // readability.

  test(compiler, arguments, parameters, "void1", "void2");
  test(compiler, arguments, parameters, "dynamic1", "dynamic2");
  test(compiler, arguments, parameters, "int1", "int2");
  test(compiler, arguments, parameters, "String1", "String2");
  test(compiler, arguments, parameters, "ListInt1", "ListInt2");
  test(compiler, arguments, parameters, "ListT1", "ListT2");
  test(compiler, arguments, parameters, "ListS1", "ListS2");
  test(compiler, arguments, parameters, "ListListT1", "ListListT2");
  test(compiler, arguments, parameters, "ListRaw1", "ListRaw2");
  test(compiler, arguments, parameters, "ListDynamic1", "ListDynamic2");
  test(compiler, arguments, parameters, "MapIntString1", "MapIntString2");
  test(compiler, arguments, parameters, "MapTString1", "MapTString2");
  test(compiler, arguments, parameters,
    "MapDynamicString1", "MapDynamicString2");
  test(compiler, arguments, parameters, "TypeVarT1", "TypeVarT2");
  test(compiler, arguments, parameters, "TypeVarS1", "TypeVarS2");
  test(compiler, arguments, parameters, "Function1a", "Function2a");
  test(compiler, arguments, parameters, "Function1b", "Function2b");
  test(compiler, arguments, parameters, "Function1c", "Function2c");
  test(compiler, arguments, parameters, "Typedef1a", "Typedef2a");
  test(compiler, arguments, parameters, "Typedef1b", "Typedef2b");
  test(compiler, arguments, parameters, "Typedef1c", "Typedef2c");
  test(compiler, arguments, parameters, "Typedef1d", "Typedef2d");
  test(compiler, arguments, parameters, "Typedef1e", "Typedef2e");
}
