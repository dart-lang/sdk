// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/dart_types.dart';
import "compiler_helper.dart";
import "parser_helper.dart";

bool test(compiler, String name1, String name2, {bool expect}) {
  Expect.isTrue((expect != null), 'required parameter "expect" not given');
  var clazz = findElement(compiler, "Class");
  clazz.ensureResolved(compiler);
  var element1 = clazz.buildScope().lookup(name1);
  var element2 = clazz.buildScope().lookup(name2);
  Expect.isNotNull(element1);
  Expect.isNotNull(element2);
  Expect.equals(element1.kind, ElementKind.FUNCTION);
  Expect.equals(element2.kind, ElementKind.FUNCTION);
  FunctionSignature signature1 = element1.computeSignature(compiler);
  FunctionSignature signature2 = element2.computeSignature(compiler);

  // Function signatures are used to be to provide void types (only occuring as
  // as return types) and (inlined) function types (only occuring as method
  // parameter types).
  //
  // Only a single type is used from each signature. That is, it is not the
  // intention to check the whole signatures against eachother.
  DartType type1;
  DartType type2;
  if (signature1.requiredParameterCount == 0) {
    // If parameters is empty, use return type.
    type1 = signature1.type.returnType;
  } else {
    // Otherwise use the first argument type.
    type1 = signature1.requiredParameters.head.computeType(compiler);
  }
  if (signature2.requiredParameterCount == 0) {
    // If parameters is empty, use return type.
    type2 = signature2.type.returnType;
  } else {
    // Otherwise use the first argument type.
    type2 = signature2.requiredParameters.head.computeType(compiler);
  }
  if (expect) {
    Expect.equals(type1, type2, "$type1 != $type2");
  } else {
    Expect.notEquals(type1, type2, "$type1 == $type2");
  }
}

void main() {
  var uri = new Uri(scheme: 'source');
  var compiler = compilerFor(
      r"""
      typedef int Typedef1<X,Y>(String s1);
      typedef void Typedef2<Z>(T t1, S s1);

      class Class<T,S> {
        void void1() {}
        void void2() {}
        void int1(int a) {}
        void int2(int b) {}
        void String1(String a) {}
        void String2(String b) {}
        void ListInt1(List<int> a) {}
        void ListInt2(List<int> b) {}
        void ListString1(List<String> a) {}
        void ListString2(List<String> b) {}
        void MapIntString1(Map<int,String> a) {}
        void MapIntString2(Map<int,String> b) {}
        void TypeVar1(T t1, S s1) {}
        void TypeVar2(T t2, S s2) {}
        void Function1a(int a(String s1)) {}
        void Function2a(int b(String s2)) {}
        void Function1b(void a(T t1, S s1)) {}
        void Function2b(void b(T t2, S s2)) {}
        void Typedef1a(Typedef1<int,String> a) {}
        void Typedef2a(Typedef1<int,String> b) {}
        void Typedef1b(Typedef2<T> a) {}
        void Typedef2b(Typedef2<T> b) {}
        void Typedef1c(Typedef2<S> a) {}
        void Typedef2c(Typedef2<S> b) {}
      }

      void main() {}
      """,
      uri,
      analyzeAll: true, analyzeOnly: true);
  asyncTest(() => compiler.runCompiler(uri).then((_) {
    test(compiler, "void1", "void2", expect: true);
    test(compiler, "int1", "int2", expect: true);
    test(compiler, "String1", "String2", expect: true);
    test(compiler, "ListInt1", "ListInt2", expect: true);
    test(compiler, "ListString1", "ListString2", expect: true);
    test(compiler, "MapIntString1", "MapIntString2", expect: true);
    test(compiler, "TypeVar1", "TypeVar2", expect: true);
    test(compiler, "Function1a", "Function2a", expect: true);
    test(compiler, "Function1b", "Function2b", expect: true);
    test(compiler, "Typedef1a", "Typedef2a", expect: true);
    test(compiler, "Typedef1b", "Typedef2b", expect: true);
    test(compiler, "Typedef1c", "Typedef2c", expect: true);

    test(compiler, "void1", "int1", expect: false);
    test(compiler, "int1", "String1", expect: false);
    test(compiler, "String1", "ListInt1", expect: false);
    test(compiler, "ListInt1", "ListString1", expect: false);
    test(compiler, "ListString1", "MapIntString1", expect: false);
    test(compiler, "MapIntString1", "TypeVar1", expect: false);
    test(compiler, "TypeVar1", "Function1a", expect: false);
    test(compiler, "Function1a", "Function1b", expect: false);
    test(compiler, "Function1b", "Typedef1a", expect: false);
    test(compiler, "Typedef1a", "Typedef1b", expect: false);
    test(compiler, "Typedef1b", "Typedef1c", expect: false);
  }));
}
