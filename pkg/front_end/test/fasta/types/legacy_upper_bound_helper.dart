// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart" show asyncTest;

import "package:expect/expect.dart" show Expect;

import "package:kernel/ast.dart";

import 'package:kernel/testing/type_parser_environment.dart' as parser;

final Uri libraryUri = Uri.parse("org-dartlang-test:///library.dart");

abstract class LegacyUpperBoundTest {
  parser.Env env;
  Library coreLibrary;
  Library testLibrary;

  bool get isNonNullableByDefault;

  void parseComponent(String source) {
    env =
        new parser.Env(source, isNonNullableByDefault: isNonNullableByDefault);
    assert(
        env.component.libraries.length == 2,
        "The test component is expected to have exactly two libraries: "
        "the core library and the test library.");
    Library firstLibrary = env.component.libraries.first;
    Library secondLibrary = env.component.libraries.last;
    if (firstLibrary.importUri.scheme == "dart" &&
        firstLibrary.importUri.path == "core") {
      coreLibrary = firstLibrary;
      testLibrary = secondLibrary;
    } else {
      assert(
          secondLibrary.importUri.scheme == "dart" &&
              secondLibrary.importUri.path == "core",
          "One of the libraries is expected to be 'dart:core'.");
      coreLibrary = secondLibrary;
      testLibrary = firstLibrary;
    }
  }

  DartType getLegacyLeastUpperBound(
      DartType a, DartType b, Library clientLibrary);

  void checkLegacyUpTypes(
      DartType a, DartType b, DartType expected, Library clientLibrary) {
    DartType actual = getLegacyLeastUpperBound(a, b, clientLibrary);
    Expect.equals(expected, actual);
  }

  void checkLegacyUp(String type1, String type2, String expectedType) {
    checkLegacyUpTypes(env.parseType(type1), env.parseType(type2),
        env.parseType(expectedType), testLibrary);
  }

  Future<void> test() {
    return asyncTest(() async {
      await test_getLegacyLeastUpperBound_expansive();
      await test_getLegacyLeastUpperBound_generic();
      await test_getLegacyLeastUpperBound_nonGeneric();
    });
  }

  /// Copy of the tests/language/least_upper_bound_expansive_test.dart test.
  Future<void> test_getLegacyLeastUpperBound_expansive() async {
    await parseComponent("""
class N<T>;
class C1<T> extends N<N<C1<T*>*>*>;
class C2<T> extends N<N<C2<N<C2<T*>*>*>*>*>;
""");

    // The least upper bound of C1<int> and N<C1<String>> is Object since the
    // supertypes are
    //     {C1<int>, N<N<C1<int>>>, Object} for C1<int> and
    //     {N<C1<String>>, Object} for N<C1<String>> and
    // Object is the most specific type in the intersection of the supertypes.
    checkLegacyUp("C1<int*>*", "N<C1<String*>*>*", "Object*");

    // The least upper bound of C2<int> and N<C2<String>> is Object since the
    // supertypes are
    //     {C2<int>, N<N<C2<N<C2<int>>>>>, Object} for C2<int> and
    //     {N<C2<String>>, Object} for N<C2<String>> and
    // Object is the most specific type in the intersection of the supertypes.
    checkLegacyUp("C2<int*>*", "N<C2<String*>*>*", "Object*");
  }

  Future<void> test_getLegacyLeastUpperBound_generic() async {
    await parseComponent("""
class A;
class B<T> implements A;
class C<U> implements A;
class D<T, U> implements B<T*>, C<U*>;
class E implements D<int*, double*>;
class F implements D<int*, bool*>;
""");

    checkLegacyUp(
        "D<int*, double*>*", "D<int*, double*>*", "D<int*, double*>*");
    checkLegacyUp("D<int*, double*>*", "D<int*, bool*>*", "B<int*>*");
    checkLegacyUp("D<int*, double*>*", "D<bool*, double*>*", "C<double*>*");
    checkLegacyUp("D<int*, double*>*", "D<bool*, int*>*", "A*");
    checkLegacyUp("E*", "F*", "B<int*>*");
  }

  Future<void> test_getLegacyLeastUpperBound_nonGeneric() async {
    await parseComponent("""
class A;
class B;
class C implements A;
class D implements A;
class E implements A;
class F implements C, D;
class G implements C, D;
class H implements C, D, E;
class I implements C, D, E;
""");

    checkLegacyUp("A*", "B*", "Object*");
    checkLegacyUp("A*", "Object*", "Object*");
    checkLegacyUp("Object*", "B*", "Object*");
    checkLegacyUp("C*", "D*", "A*");
    checkLegacyUp("C*", "A*", "A*");
    checkLegacyUp("A*", "D*", "A*");
    checkLegacyUp("F*", "G*", "A*");
    checkLegacyUp("H*", "I*", "A*");
  }
}
