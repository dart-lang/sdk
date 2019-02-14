// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/matchers_lite.dart";

import "package:kernel/ast.dart";

import "package:kernel/class_hierarchy.dart";

import "package:kernel/core_types.dart";

import "package:kernel/library_index.dart";

import "kernel_type_parser.dart";

import "mock_sdk.dart" show mockSdk;

final Uri libraryUri = Uri.parse("org-dartlang-test:///library.dart");

main() {
  new LegacyUpperBoundTest().test_getLegacyLeastUpperBound_expansive();

  new LegacyUpperBoundTest().test_getLegacyLeastUpperBound_generic();

  new LegacyUpperBoundTest().test_getLegacyLeastUpperBound_nonGeneric();
}

class LegacyUpperBoundTest {
  Component component;

  CoreTypes coreTypes;

  LibraryIndex index;

  ClassHierarchy _hierarchy;

  Class get objectClass => coreTypes.objectClass;

  Supertype get objectSuper => coreTypes.objectClass.asThisSupertype;

  ClassHierarchy get hierarchy {
    return _hierarchy ??= createClassHierarchy(component);
  }

  void parseComponent(String source) {
    Uri coreUri = Uri.parse("dart:core");
    KernelEnvironment coreEnvironment = new KernelEnvironment(coreUri, coreUri);
    Library coreLibrary =
        parseLibrary(coreUri, mockSdk, environment: coreEnvironment);
    KernelEnvironment libraryEnvironment =
        new KernelEnvironment(libraryUri, libraryUri)
            .extend(coreEnvironment.declarations);
    Library library =
        parseLibrary(libraryUri, source, environment: libraryEnvironment);

    component = new Component(libraries: <Library>[coreLibrary, library]);
    index = new LibraryIndex.all(component);
    coreTypes = new CoreTypes(component);
  }

  Class getClass(String name) {
    return index.getClass("$libraryUri", name);
  }

  ClassHierarchy createClassHierarchy(Component component) {
    return new ClassHierarchy(component);
  }

  /// Copy of the tests/language/least_upper_bound_expansive_test.dart test.
  void test_getLegacyLeastUpperBound_expansive() {
    parseComponent("""
class N<T>;
class C1<T> extends N<N<C1<T>>>;
class C2<T> extends N<N<C2<N<C2<T>>>>>;
""");
    DartType int = coreTypes.intClass.rawType;
    DartType string = coreTypes.stringClass.rawType;

    Class N = getClass("N");
    Class C1 = getClass("C1");
    Class C2 = getClass("C2");

    // The least upper bound of C1<int> and N<C1<String>> is Object since the
    // supertypes are
    //     {C1<int>, N<N<C1<int>>>, Object} for C1<int> and
    //     {N<C1<String>>, Object} for N<C1<String>> and
    // Object is the most specific type in the intersection of the supertypes.
    expect(
        hierarchy.getLegacyLeastUpperBound(
            new InterfaceType(C1, [int]),
            new InterfaceType(N, [
              new InterfaceType(C1, [string])
            ])),
        objectClass.thisType);

    // The least upper bound of C2<int> and N<C2<String>> is Object since the
    // supertypes are
    //     {C2<int>, N<N<C2<N<C2<int>>>>>, Object} for C2<int> and
    //     {N<C2<String>>, Object} for N<C2<String>> and
    // Object is the most specific type in the intersection of the supertypes.
    expect(
        hierarchy.getLegacyLeastUpperBound(
            new InterfaceType(C2, [int]),
            new InterfaceType(N, [
              new InterfaceType(C2, [string])
            ])),
        objectClass.thisType);
  }

  void test_getLegacyLeastUpperBound_generic() {
    parseComponent("""
class A;
class B<T> implements A;
class C<U> implements A;
class D<T, U> implements B<T>, C<U>;
class E implements D<int, double>;
class F implements D<int, bool>;
""");

    DartType int = coreTypes.intClass.rawType;
    DartType double = coreTypes.doubleClass.rawType;
    DartType bool = coreTypes.boolClass.rawType;

    Class a = getClass("A");
    Class b = getClass("B");
    Class c = getClass("C");
    Class d = getClass("D");
    Class e = getClass("E");
    Class f = getClass("F");

    expect(
        hierarchy.getLegacyLeastUpperBound(new InterfaceType(d, [int, double]),
            new InterfaceType(d, [int, double])),
        new InterfaceType(d, [int, double]));
    expect(
        hierarchy.getLegacyLeastUpperBound(new InterfaceType(d, [int, double]),
            new InterfaceType(d, [int, bool])),
        new InterfaceType(b, [int]));
    expect(
        hierarchy.getLegacyLeastUpperBound(new InterfaceType(d, [int, double]),
            new InterfaceType(d, [bool, double])),
        new InterfaceType(c, [double]));
    expect(
        hierarchy.getLegacyLeastUpperBound(new InterfaceType(d, [int, double]),
            new InterfaceType(d, [bool, int])),
        a.rawType);
    expect(hierarchy.getLegacyLeastUpperBound(e.rawType, f.rawType),
        new InterfaceType(b, [int]));
  }

  void test_getLegacyLeastUpperBound_nonGeneric() {
    parseComponent("""
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

    expect(hierarchy.getLegacyLeastUpperBound(a.rawType, b.rawType),
        objectClass.rawType);
    expect(hierarchy.getLegacyLeastUpperBound(a.rawType, objectClass.rawType),
        objectClass.rawType);
    expect(hierarchy.getLegacyLeastUpperBound(objectClass.rawType, b.rawType),
        objectClass.rawType);
    expect(hierarchy.getLegacyLeastUpperBound(c.rawType, d.rawType), a.rawType);
    expect(hierarchy.getLegacyLeastUpperBound(c.rawType, a.rawType), a.rawType);
    expect(hierarchy.getLegacyLeastUpperBound(a.rawType, d.rawType), a.rawType);
    expect(hierarchy.getLegacyLeastUpperBound(f.rawType, g.rawType), a.rawType);
    expect(hierarchy.getLegacyLeastUpperBound(h.rawType, i.rawType), a.rawType);
  }
}
