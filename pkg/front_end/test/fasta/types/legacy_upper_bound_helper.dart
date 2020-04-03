// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart" show asyncTest;

import "package:expect/expect.dart" show Expect;

import "package:kernel/ast.dart"
    show Class, Component, DartType, InterfaceType, Library, Nullability;

import "package:kernel/core_types.dart";

import "package:kernel/library_index.dart" show LibraryIndex;

import 'package:kernel/testing/type_parser_environment.dart'
    as kernel_type_parser show parseComponent;

final Uri libraryUri = Uri.parse("org-dartlang-test:///library.dart");

abstract class LegacyUpperBoundTest {
  Component component;

  CoreTypes coreTypes;

  LibraryIndex index;

  DartType get objectType => coreTypes.objectLegacyRawType;

  DartType get intType => coreTypes.intLegacyRawType;

  DartType get stringType => coreTypes.intLegacyRawType;

  DartType get doubleType => coreTypes.doubleLegacyRawType;

  DartType get boolType => coreTypes.boolLegacyRawType;

  void parseComponent(String source) {
    component = kernel_type_parser.parseComponent(source, libraryUri);
    coreTypes = new CoreTypes(component);
    index = new LibraryIndex.all(component);
  }

  Class getClass(String name) {
    return index.getClass("$libraryUri", name);
  }

  Class getCoreClass(String name) {
    return index.getClass("dart:core", name);
  }

  DartType getLegacyLeastUpperBound(
      DartType a, DartType b, Library clientLibrary, CoreTypes coreTypes);

  void checkGetLegacyLeastUpperBound(
      DartType a, DartType b, Library clientLibrary, DartType expected) {
    DartType actual = getLegacyLeastUpperBound(a, b, clientLibrary, coreTypes);
    Expect.equals(expected, actual);
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

    Class N = getClass("N");
    Class C1 = getClass("C1");
    Class C2 = getClass("C2");
    Library testLib = N.enclosingLibrary;

    // The least upper bound of C1<int> and N<C1<String>> is Object since the
    // supertypes are
    //     {C1<int>, N<N<C1<int>>>, Object} for C1<int> and
    //     {N<C1<String>>, Object} for N<C1<String>> and
    // Object is the most specific type in the intersection of the supertypes.
    checkGetLegacyLeastUpperBound(
        new InterfaceType(C1, Nullability.legacy, [intType]),
        new InterfaceType(N, Nullability.legacy, [
          new InterfaceType(C1, Nullability.legacy, [stringType])
        ]),
        testLib,
        objectType);

    // The least upper bound of C2<int> and N<C2<String>> is Object since the
    // supertypes are
    //     {C2<int>, N<N<C2<N<C2<int>>>>>, Object} for C2<int> and
    //     {N<C2<String>>, Object} for N<C2<String>> and
    // Object is the most specific type in the intersection of the supertypes.
    checkGetLegacyLeastUpperBound(
        new InterfaceType(C2, Nullability.legacy, [intType]),
        new InterfaceType(N, Nullability.legacy, [
          new InterfaceType(C2, Nullability.legacy, [stringType])
        ]),
        testLib,
        objectType);
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

    Class a = getClass("A");
    Class b = getClass("B");
    Class c = getClass("C");
    Class d = getClass("D");
    Class e = getClass("E");
    Class f = getClass("F");
    Library testLib = a.enclosingLibrary;

    checkGetLegacyLeastUpperBound(
        new InterfaceType(d, Nullability.legacy, [intType, doubleType]),
        new InterfaceType(d, Nullability.legacy, [intType, doubleType]),
        testLib,
        new InterfaceType(d, Nullability.legacy, [intType, doubleType]));
    checkGetLegacyLeastUpperBound(
        new InterfaceType(d, Nullability.legacy, [intType, doubleType]),
        new InterfaceType(d, Nullability.legacy, [intType, boolType]),
        testLib,
        new InterfaceType(b, Nullability.legacy, [intType]));
    checkGetLegacyLeastUpperBound(
        new InterfaceType(d, Nullability.legacy, [intType, doubleType]),
        new InterfaceType(d, Nullability.legacy, [boolType, doubleType]),
        testLib,
        new InterfaceType(c, Nullability.legacy, [doubleType]));
    checkGetLegacyLeastUpperBound(
        new InterfaceType(d, Nullability.legacy, [intType, doubleType]),
        new InterfaceType(d, Nullability.legacy, [boolType, intType]),
        testLib,
        coreTypes.legacyRawType(a));
    checkGetLegacyLeastUpperBound(
        coreTypes.legacyRawType(e),
        coreTypes.legacyRawType(f),
        testLib,
        new InterfaceType(b, Nullability.legacy, [intType]));
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

    Class a = getClass("A");
    Class b = getClass("B");
    Class c = getClass("C");
    Class d = getClass("D");
    Class f = getClass("F");
    Class g = getClass("G");
    Class h = getClass("H");
    Class i = getClass("I");
    Library testLib = a.enclosingLibrary;

    checkGetLegacyLeastUpperBound(coreTypes.legacyRawType(a),
        coreTypes.legacyRawType(b), testLib, objectType);
    checkGetLegacyLeastUpperBound(
        coreTypes.legacyRawType(a), objectType, testLib, objectType);
    checkGetLegacyLeastUpperBound(
        objectType, coreTypes.legacyRawType(b), testLib, objectType);
    checkGetLegacyLeastUpperBound(coreTypes.legacyRawType(c),
        coreTypes.legacyRawType(d), testLib, coreTypes.legacyRawType(a));
    checkGetLegacyLeastUpperBound(coreTypes.legacyRawType(c),
        coreTypes.legacyRawType(a), testLib, coreTypes.legacyRawType(a));
    checkGetLegacyLeastUpperBound(coreTypes.legacyRawType(a),
        coreTypes.legacyRawType(d), testLib, coreTypes.legacyRawType(a));
    checkGetLegacyLeastUpperBound(coreTypes.legacyRawType(f),
        coreTypes.legacyRawType(g), testLib, coreTypes.legacyRawType(a));
    checkGetLegacyLeastUpperBound(coreTypes.legacyRawType(h),
        coreTypes.legacyRawType(i), testLib, coreTypes.legacyRawType(a));
  }
}
