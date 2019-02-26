// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/testing/mock_sdk_component.dart';
import 'package:test/test.dart';
import 'package:vm/bytecode/generics.dart';

main() {
  Library lib;
  Supertype objectSuper;
  DartType intType;
  Class base;

  Class addClass(String name, List<TypeParameter> typeParameters) {
    Class cls = new Class(
        name: name, supertype: objectSuper, typeParameters: typeParameters);
    lib.addClass(cls);
    return cls;
  }

  setUp(() {
    // Start with mock SDK libraries.
    Component component = createMockSdkComponent();
    CoreTypes coreTypes = new CoreTypes(component);
    objectSuper = coreTypes.objectClass.asThisSupertype;
    intType = new InterfaceType(coreTypes.intClass);

    // Add the test library.
    lib = new Library(Uri.parse('org-dartlang:///test.dart'), name: 'lib');
    lib.parent = component;
    component.libraries.add(lib);

    // class Base<T>
    base = addClass('Base', [new TypeParameter('T')]);
  });

  tearDown(() {});

  test('isRecursiveAfterFlattening-00', () async {
    // class Derived<T> extends Base<Derived<T>>
    TypeParameter t = new TypeParameter('T');
    Class derived = addClass('Derived', [t]);
    DartType derivedOfT =
        new InterfaceType(derived, [new TypeParameterType(t)]);
    DartType derivedOfInt = new InterfaceType(derived, [intType]);
    derived.supertype = new Supertype(base, [derivedOfT]);

    expect(isRecursiveAfterFlattening(derivedOfT), isTrue);
    expect(isRecursiveAfterFlattening(derivedOfInt), isTrue);
  });

  test('isRecursiveAfterFlattening-01', () async {
    // class Derived<T> extends Base<Derived<Derived<int>>>
    TypeParameter t = new TypeParameter('T');
    Class derived = addClass('Derived', [t]);
    DartType derivedOfT =
        new InterfaceType(derived, [new TypeParameterType(t)]);
    DartType derivedOfInt = new InterfaceType(derived, [intType]);
    DartType derivedOfDerivedOfInt = new InterfaceType(derived, [derivedOfInt]);
    derived.supertype = new Supertype(base, [derivedOfDerivedOfInt]);

    expect(isRecursiveAfterFlattening(derivedOfT), isFalse);
    expect(isRecursiveAfterFlattening(derivedOfInt), isTrue);
  });

  test('isRecursiveAfterFlattening-02', () async {
    // class Derived<T> extends Base<Derived<Derived<T>>>
    TypeParameter t = new TypeParameter('T');
    Class derived = addClass('Derived', [t]);
    DartType derivedOfT =
        new InterfaceType(derived, [new TypeParameterType(t)]);
    DartType derivedOfInt = new InterfaceType(derived, [intType]);
    DartType derivedOfDerivedOfT = new InterfaceType(derived, [derivedOfT]);
    derived.supertype = new Supertype(base, [derivedOfDerivedOfT]);

    expect(isRecursiveAfterFlattening(derivedOfT), isTrue);
    expect(isRecursiveAfterFlattening(derivedOfInt), isTrue);
  });

  test('isRecursiveAfterFlattening-03', () async {
    // class Derived1<U> extends Base<Derived2<U>>
    // class Derived2<V> extends Base<Derived1<V>>
    TypeParameter u = new TypeParameter('U');
    Class derived1 = addClass('Derived1', [u]);

    TypeParameter v = new TypeParameter('V');
    Class derived2 = addClass('Derived2', [v]);

    DartType derived2OfU =
        new InterfaceType(derived2, [new TypeParameterType(u)]);
    derived1.supertype = new Supertype(base, [derived2OfU]);

    DartType derived1OfV =
        new InterfaceType(derived1, [new TypeParameterType(v)]);
    derived2.supertype = new Supertype(base, [derived1OfV]);

    DartType derived1OfU =
        new InterfaceType(derived1, [new TypeParameterType(u)]);
    DartType derived1OfInt = new InterfaceType(derived1, [intType]);

    DartType derived2OfV =
        new InterfaceType(derived2, [new TypeParameterType(v)]);
    DartType derived2OfInt = new InterfaceType(derived2, [intType]);

    expect(isRecursiveAfterFlattening(derived1OfU), isTrue);
    expect(isRecursiveAfterFlattening(derived1OfInt), isTrue);
    expect(isRecursiveAfterFlattening(derived2OfV), isTrue);
    expect(isRecursiveAfterFlattening(derived2OfInt), isTrue);
  });
}
