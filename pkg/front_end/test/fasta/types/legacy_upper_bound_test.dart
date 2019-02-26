// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/matchers_lite.dart";

import "package:kernel/ast.dart";
import "package:kernel/class_hierarchy.dart";
import "package:kernel/core_types.dart";
import "package:kernel/testing/mock_sdk_component.dart";
import "package:kernel/text/ast_to_text.dart";
import "package:kernel/type_algebra.dart";

main() {
  new LegacyUpperBoundTest().test_getLegacyLeastUpperBound_expansive();

  new LegacyUpperBoundTest().test_getLegacyLeastUpperBound_generic();

  new LegacyUpperBoundTest().test_getLegacyLeastUpperBound_nonGeneric();
}

class LegacyUpperBoundTest {
  final Component component = createMockSdkComponent();

  CoreTypes coreTypes;

  final Library library =
      new Library(Uri.parse('org-dartlang:///test.dart'), name: 'test');

  ClassHierarchy _hierarchy;

  LegacyUpperBoundTest() {
    coreTypes = new CoreTypes(component);
    library.parent = component;
    component.libraries.add(library);
  }

  Class get objectClass => coreTypes.objectClass;

  Supertype get objectSuper => coreTypes.objectClass.asThisSupertype;

  ClassHierarchy get hierarchy {
    return _hierarchy ??= createClassHierarchy(component);
  }

  Class addClass(Class c) {
    if (_hierarchy != null) {
      fail('The classs hierarchy has already been created.');
    }
    library.addClass(c);
    return c;
  }

  /// Assert that the test [library] has the [expectedText] presentation.
  /// The presentation is close, but not identical to the normal Kernel one.
  void _assertTestLibraryText(String expectedText) {
    _assertLibraryText(library, expectedText);
  }

  void _assertLibraryText(Library lib, String expectedText) {
    StringBuffer sb = new StringBuffer();
    Printer printer = new Printer(sb);
    printer.writeLibraryFile(lib);

    String actualText = sb.toString();

    // Clean up the text a bit.
    const oftenUsedPrefix = '''
library test;
import self as self;
import "dart:core" as core;

''';
    if (actualText.startsWith(oftenUsedPrefix)) {
      actualText = actualText.substring(oftenUsedPrefix.length);
    }
    actualText = actualText.replaceAll('{\n}', '{}');
    actualText = actualText.replaceAll(' extends core::Object', '');

    if (actualText != expectedText) {
      print('-------- Actual --------');
      print(actualText + '------------------------');
    }

    expect(actualText, expectedText);
  }

  ClassHierarchy createClassHierarchy(Component component) {
    return new ClassHierarchy(component);
  }

  /// Add a new generic class with the given [name] and [typeParameterNames].
  /// The [TypeParameterType]s corresponding to [typeParameterNames] are
  /// passed to optional [extends_] and [implements_] callbacks.
  Class addGenericClass(String name, List<String> typeParameterNames,
      {Supertype extends_(List<DartType> typeParameterTypes),
      List<Supertype> implements_(List<DartType> typeParameterTypes)}) {
    var typeParameters = typeParameterNames
        .map((name) => new TypeParameter(name, objectClass.rawType))
        .toList();
    var typeParameterTypes = typeParameters
        .map((parameter) => new TypeParameterType(parameter))
        .toList();
    var supertype =
        extends_ != null ? extends_(typeParameterTypes) : objectSuper;
    var implementedTypes =
        implements_ != null ? implements_(typeParameterTypes) : <Supertype>[];
    return addClass(new Class(
        name: name,
        typeParameters: typeParameters,
        supertype: supertype,
        implementedTypes: implementedTypes));
  }

  /// Add a new class with the given [name] that extends `Object` and
  /// [implements_] the given classes.
  Class addImplementsClass(String name, List<Class> implements_) {
    return addClass(new Class(
        name: name,
        supertype: objectSuper,
        implementedTypes: implements_.map((c) => c.asThisSupertype).toList()));
  }

  /// Copy of the tests/language/least_upper_bound_expansive_test.dart test.
  void test_getLegacyLeastUpperBound_expansive() {
    var int = coreTypes.intClass.rawType;
    var string = coreTypes.stringClass.rawType;

    // class N<T> {}
    var NT = new TypeParameter('T', objectClass.rawType);
    var N = addClass(
        new Class(name: 'N', typeParameters: [NT], supertype: objectSuper));

    // class C1<T> extends N<N<C1<T>>> {}
    Class C1;
    {
      var T = new TypeParameter('T', objectClass.rawType);
      C1 = addClass(
          new Class(name: 'C1', typeParameters: [T], supertype: objectSuper));
      DartType C1_T = Substitution.fromMap({T: new TypeParameterType(T)})
          .substituteType(C1.thisType);
      DartType N_C1_T =
          Substitution.fromMap({NT: C1_T}).substituteType(N.thisType);
      Supertype N_N_C1_T = Substitution.fromMap({NT: N_C1_T})
          .substituteSupertype(N.asThisSupertype);
      C1.supertype = N_N_C1_T;
    }

    // class C2<T> extends N<N<C2<N<C2<T>>>>> {}
    Class C2;
    {
      var T = new TypeParameter('T', objectClass.rawType);
      C2 = addClass(
          new Class(name: 'C2', typeParameters: [T], supertype: objectSuper));
      DartType C2_T = Substitution.fromMap({T: new TypeParameterType(T)})
          .substituteType(C2.thisType);
      DartType N_C2_T =
          Substitution.fromMap({NT: C2_T}).substituteType(N.thisType);
      DartType C2_N_C2_T =
          Substitution.fromMap({T: N_C2_T}).substituteType(C2.thisType);
      DartType N_C2_N_C2_T =
          Substitution.fromMap({NT: C2_N_C2_T}).substituteType(N.thisType);
      Supertype N_N_C2_N_C2_T = Substitution.fromMap({NT: N_C2_N_C2_T})
          .substituteSupertype(N.asThisSupertype);
      C2.supertype = N_N_C2_N_C2_T;
    }

    _assertTestLibraryText('''
class N<T> {}
class C1<T> extends self::N<self::N<self::C1<self::C1::T>>> {}
class C2<T> extends self::N<self::N<self::C2<self::N<self::C2<self::C2::T>>>>> {}
''');

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
    var int = coreTypes.intClass.rawType;
    var double = coreTypes.doubleClass.rawType;
    var bool = coreTypes.boolClass.rawType;

    var a = addGenericClass('A', []);
    var b =
        addGenericClass('B', ['T'], implements_: (_) => [a.asThisSupertype]);
    var c =
        addGenericClass('C', ['U'], implements_: (_) => [a.asThisSupertype]);
    var d = addGenericClass('D', ['T', 'U'], implements_: (typeParameterTypes) {
      var t = typeParameterTypes[0];
      var u = typeParameterTypes[1];
      return [
        new Supertype(b, [t]),
        new Supertype(c, [u])
      ];
    });
    var e = addGenericClass('E', [],
        implements_: (_) => [
              new Supertype(d, [int, double])
            ]);
    var f = addGenericClass('F', [],
        implements_: (_) => [
              new Supertype(d, [int, bool])
            ]);

    _assertTestLibraryText('''
class A {}
class B<T> implements self::A {}
class C<U> implements self::A {}
class D<T, U> implements self::B<self::D::T>, self::C<self::D::U> {}
class E implements self::D<core::int, core::double> {}
class F implements self::D<core::int, core::bool> {}
''');

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
    var a = addImplementsClass('A', []);
    var b = addImplementsClass('B', []);
    var c = addImplementsClass('C', [a]);
    var d = addImplementsClass('D', [a]);
    var e = addImplementsClass('E', [a]);
    var f = addImplementsClass('F', [c, d]);
    var g = addImplementsClass('G', [c, d]);
    var h = addImplementsClass('H', [c, d, e]);
    var i = addImplementsClass('I', [c, d, e]);

    _assertTestLibraryText('''
class A {}
class B {}
class C implements self::A {}
class D implements self::A {}
class E implements self::A {}
class F implements self::C, self::D {}
class G implements self::C, self::D {}
class H implements self::C, self::D, self::E {}
class I implements self::C, self::D, self::E {}
''');

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
