// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/testing/mock_sdk_component.dart';
import 'package:test/test.dart';
import 'package:expect/expect.dart';
import 'package:vm/bytecode/recursive_types_validator.dart';

main() {
  CoreTypes coreTypes;
  Library lib;
  Supertype objectSuper;
  DartType intType;
  DartType doubleType;
  Class base;
  RecursiveTypesValidator validator;

  Class addClass(String name, List<TypeParameter> typeParameters) {
    Class cls = new Class(
        name: name, supertype: objectSuper, typeParameters: typeParameters);
    lib.addClass(cls);
    return cls;
  }

  setUp(() {
    // Start with mock SDK libraries.
    Component component = createMockSdkComponent();
    coreTypes = new CoreTypes(component);
    objectSuper = coreTypes.objectClass.asThisSupertype;
    intType = new InterfaceType(coreTypes.intClass, Nullability.legacy);
    doubleType = new InterfaceType(coreTypes.doubleClass, Nullability.legacy);

    // Add the test library.
    lib = new Library(Uri.parse('org-dartlang:///test.dart'), name: 'lib');
    lib.parent = component;
    component.libraries.add(lib);

    // class Base<T>
    base = addClass('Base', [new TypeParameter('T')]);

    validator = new RecursiveTypesValidator(coreTypes);
  });

  tearDown(() {});

  test('simple-recursive-type', () async {
    // class Derived<T> extends Base<Derived<T>>
    TypeParameter t = new TypeParameter('T');
    Class derived = addClass('Derived', [t]);
    DartType derivedOfT = new InterfaceType(derived, Nullability.legacy,
        [new TypeParameterType(t, Nullability.legacy)]);
    DartType derivedOfInt =
        new InterfaceType(derived, Nullability.legacy, [intType]);
    derived.supertype = new Supertype(base, [derivedOfT]);

    validator.validateType(derivedOfT);
    Expect.isTrue(validator.isRecursive(derivedOfT));

    validator.validateType(derivedOfInt);
    Expect.isTrue(validator.isRecursive(derivedOfInt));
  });

  test('recursive-type-extends-instantiated', () async {
    // class Derived<T> extends Base<Derived<Derived<int>>>
    TypeParameter t = new TypeParameter('T');
    Class derived = addClass('Derived', [t]);
    DartType derivedOfT = new InterfaceType(derived, Nullability.legacy,
        [new TypeParameterType(t, Nullability.legacy)]);
    DartType derivedOfInt =
        new InterfaceType(derived, Nullability.legacy, [intType]);
    DartType derivedOfDerivedOfInt =
        new InterfaceType(derived, Nullability.legacy, [derivedOfInt]);
    derived.supertype = new Supertype(base, [derivedOfDerivedOfInt]);

    validator.validateType(derivedOfT);
    validator.validateType(derivedOfInt);

    Expect.isFalse(validator.isRecursive(derivedOfT));
    Expect.isTrue(validator.isRecursive(derivedOfInt));
    Expect.isTrue(validator.isRecursive(derivedOfDerivedOfInt));
  });

  test('recursive-non-contractive-type', () async {
    // class Derived<T> extends Base<Derived<Derived<T>>>
    TypeParameter t = new TypeParameter('T');
    Class derived = addClass('Derived', [t]);
    DartType derivedOfT = new InterfaceType(derived, Nullability.legacy,
        [new TypeParameterType(t, Nullability.legacy)]);
    DartType derivedOfInt =
        new InterfaceType(derived, Nullability.legacy, [intType]);
    DartType derivedOfDerivedOfT =
        new InterfaceType(derived, Nullability.legacy, [derivedOfT]);
    derived.supertype = new Supertype(base, [derivedOfDerivedOfT]);

    Expect.throws(() {
      validator.validateType(derivedOfT);
    });
    Expect.throws(() {
      validator.validateType(derivedOfDerivedOfT);
    });
    Expect.throws(() {
      validator.validateType(derivedOfInt);
    });
  });

  test('mutually-recursive-types', () async {
    // class Derived1<U> extends Base<Derived2<U>>
    // class Derived2<V> extends Base<Derived1<V>>
    TypeParameter u = new TypeParameter('U');
    Class derived1 = addClass('Derived1', [u]);

    TypeParameter v = new TypeParameter('V');
    Class derived2 = addClass('Derived2', [v]);

    DartType derived2OfU = new InterfaceType(derived2, Nullability.legacy,
        [new TypeParameterType(u, Nullability.legacy)]);
    derived1.supertype = new Supertype(base, [derived2OfU]);

    DartType derived1OfV = new InterfaceType(derived1, Nullability.legacy,
        [new TypeParameterType(v, Nullability.legacy)]);
    derived2.supertype = new Supertype(base, [derived1OfV]);

    DartType derived1OfU = new InterfaceType(derived1, Nullability.legacy,
        [new TypeParameterType(u, Nullability.legacy)]);
    DartType derived1OfInt =
        new InterfaceType(derived1, Nullability.legacy, [intType]);

    DartType derived2OfV = new InterfaceType(derived2, Nullability.legacy,
        [new TypeParameterType(v, Nullability.legacy)]);
    DartType derived2OfInt =
        new InterfaceType(derived2, Nullability.legacy, [intType]);

    validator.validateType(derived1OfU);
    Expect.isTrue(validator.isRecursive(derived1OfU));

    validator.validateType(derived1OfInt);
    Expect.isTrue(validator.isRecursive(derived1OfInt));

    validator.validateType(derived2OfV);
    Expect.isTrue(validator.isRecursive(derived2OfV));

    validator.validateType(derived2OfInt);
    Expect.isTrue(validator.isRecursive(derived2OfInt));
  });

  test('recursive-two-type-params', () async {
    // class F<P1, P2> {}
    // class E<Q1, Q2> extends F<E<Q1, int>, Q2> {}
    TypeParameter p1 = new TypeParameter('P1');
    TypeParameter p2 = new TypeParameter('P2');
    Class f = addClass('F', [p1, p2]);

    TypeParameter q1 = new TypeParameter('Q1');
    TypeParameter q2 = new TypeParameter('Q2');
    Class e = addClass('E', [q1, q2]);

    DartType eOfQ1Int = new InterfaceType(e, Nullability.legacy,
        [new TypeParameterType(q1, Nullability.legacy), intType]);
    e.supertype = new Supertype(
        f, [eOfQ1Int, new TypeParameterType(q2, Nullability.legacy)]);

    DartType eOfIntDouble =
        new InterfaceType(e, Nullability.legacy, [intType, doubleType]);

    validator.validateType(eOfIntDouble);
    validator.validateType(e.getThisType(coreTypes, lib.nonNullable));

    Expect.isFalse(validator.isRecursive(eOfIntDouble));
    Expect.isFalse(
        validator.isRecursive(e.getThisType(coreTypes, lib.nonNullable)));
  });
}
