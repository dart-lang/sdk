// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/testing/mock_sdk_component.dart';
import 'package:test/test.dart';
import 'package:expect/expect.dart';
import 'package:vm/bytecode/object_table.dart';

main() {
  Library lib1;
  Library lib2;
  CoreTypes coreTypes;
  Supertype objectSupertype;
  ObjectTable objectTable;

  Class addClass(Library lib, String name,
      [List<TypeParameter> typeParameters = const []]) {
    Class cls = new Class(
        name: name, supertype: objectSupertype, typeParameters: typeParameters);
    cls.parent = lib;
    lib.addClass(cls);
    return cls;
  }

  setUp(() {
    // Start with mock SDK libraries.
    Component component = createMockSdkComponent();
    coreTypes = new CoreTypes(component);
    objectSupertype = coreTypes.objectClass.asThisSupertype;

    // Add test libraries.
    lib1 = new Library(Uri.parse('org-dartlang:///test1.dart'), name: 'lib1');
    lib1.parent = component;
    component.libraries.add(lib1);

    lib2 = new Library(Uri.parse('org-dartlang:///test2.dart'), name: 'lib2');
    lib2.parent = component;
    component.libraries.add(lib2);

    objectTable = new ObjectTable(coreTypes);
  });

  tearDown(() {});

  test('libraries', () {
    final h1 = objectTable.getHandle(lib1);
    final h2 = objectTable.getHandle(lib2);
    Expect.notEquals(h1, h2);
    Expect.identical(h1, objectTable.getHandle(lib1));
    Expect.identical(h2, objectTable.getHandle(lib2));
    Expect.equals(true, h1.isCacheable);
    Expect.equals(true, h2.isCacheable);
    Expect.equals(false, h1.shouldBeIncludedIntoIndexTable); // 2 uses
    Expect.identical(h1, objectTable.getHandle(lib1));
    Expect.equals(true, h1.shouldBeIncludedIntoIndexTable); // 3 uses
  });

  test('classes', () {
    final Class c1 = addClass(lib1, 'A');
    final Class c2 = addClass(lib1, 'B');
    final Class c3 = addClass(lib2, 'A');
    final h1 = objectTable.getHandle(c1);
    final h2 = objectTable.getHandle(c2);
    final h3 = objectTable.getHandle(c3);
    Expect.notEquals(h1, h2);
    Expect.notEquals(h1, h3);
    Expect.notEquals(h2, h3);
    Expect.identical(h1, objectTable.getHandle(c1));
    Expect.identical(h2, objectTable.getHandle(c2));
    Expect.identical(h3, objectTable.getHandle(c3));
    Expect.equals(true, h1.isCacheable);
    Expect.equals(true, h2.isCacheable);
    Expect.equals(true, h3.isCacheable);
    final lib1h = objectTable.getHandle(lib1);
    final lib2h = objectTable.getHandle(lib2);
    Expect.equals(true, lib1h.shouldBeIncludedIntoIndexTable); // 3 uses
    Expect.equals(false, lib2h.shouldBeIncludedIntoIndexTable); // 2 uses
  });

  test('simple-types', () {
    final h1a = objectTable
        .getHandle(new InterfaceType(coreTypes.intClass, Nullability.legacy));
    final h1b = objectTable
        .getHandle(new InterfaceType(coreTypes.intClass, Nullability.legacy));
    final h2a = objectTable.getHandle(const DynamicType());
    final h2b = objectTable.getHandle(new DynamicType());
    Expect.identical(h1a, h1b);
    Expect.identical(h2a, h2b);
    Expect.notEquals(h1a, h2a);
    Expect.equals(true, h1a.isCacheable);
    Expect.equals(true, h2a.isCacheable);
    Expect.equals(false, h1a.shouldBeIncludedIntoIndexTable); // 2 uses
    objectTable.getHandle(new InterfaceType(
        coreTypes.listClass,
        Nullability.legacy,
        [new InterfaceType(coreTypes.intClass, Nullability.legacy)]));
    Expect.equals(true, h1a.shouldBeIncludedIntoIndexTable); // 3 uses
  });

  test('recursive-types', () {
    final base = addClass(lib1, "Base", [new TypeParameter("T")]);
    final derived1 = addClass(lib1, "Derived");
    derived1.supertype =
        new Supertype(base, [new InterfaceType(derived1, Nullability.legacy)]);
    final derived2 = addClass(lib2, "Derived");
    derived2.supertype =
        new Supertype(base, [new InterfaceType(derived2, Nullability.legacy)]);
    final h1a =
        objectTable.getHandle(new InterfaceType(derived1, Nullability.legacy));
    final h1b =
        objectTable.getHandle(new InterfaceType(derived1, Nullability.legacy));
    final h2a =
        objectTable.getHandle(new InterfaceType(derived2, Nullability.legacy));
    final h2b =
        objectTable.getHandle(new InterfaceType(derived2, Nullability.legacy));
    Expect.identical(h1a, h1b);
    Expect.identical(h2a, h2b);
    Expect.notEquals(h1a, h2a);
    Expect.equals(true, h1a.isCacheable);
    Expect.equals(true, h2a.isCacheable);
    final typeArgs1 = (h1a as dynamic).typeArgs;
    final typeArgs2 = (h2a as dynamic).typeArgs;
    Expect.equals(false, typeArgs1.isCacheable);
    Expect.equals(false, typeArgs2.isCacheable);
  });
}
