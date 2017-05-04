// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/testing/mock_sdk_program.dart';
import 'package:test/test.dart';

main() {
  Library makeTestLibrary(Program program) {
    var library = new Library(Uri.parse('org-dartlang:///test.dart'))
      ..parent = program;
    program.libraries.add(library);
    return library;
  }

  test('depth', () {
    var program = createMockSdkProgram();
    var coreTypes = new CoreTypes(program);
    var defaultSuper = coreTypes.objectClass.asThisSupertype;
    var library = makeTestLibrary(program);

    Class addClass(Class c) {
      library.addClass(c);
      return c;
    }

    var base = addClass(new Class(name: 'base', supertype: defaultSuper));
    var extends_ =
        addClass(new Class(name: 'extends_', supertype: base.asThisSupertype));
    var with_ = addClass(new Class(
        name: 'with_',
        supertype: defaultSuper,
        mixedInType: base.asThisSupertype));
    var implements_ = addClass(new Class(
        name: 'implements_',
        supertype: defaultSuper,
        implementedTypes: [base.asThisSupertype]));
    var hierarchy = new ClassHierarchy(program);

    expect(hierarchy.getClassDepth(coreTypes.objectClass), 0);
    expect(hierarchy.getClassDepth(base), 1);
    expect(hierarchy.getClassDepth(extends_), 2);
    expect(hierarchy.getClassDepth(with_), 2);
    expect(hierarchy.getClassDepth(implements_), 2);
  });

  test('ranked_superclasses', () {
    var program = createMockSdkProgram();
    var coreTypes = new CoreTypes(program);
    var defaultSuper = coreTypes.objectClass.asThisSupertype;
    var library = makeTestLibrary(program);

    Class addClass(String name, List<Class> implements_) {
      var c = new Class(
          name: name,
          supertype: defaultSuper,
          implementedTypes: implements_.map((c) => c.asThisSupertype).toList());
      library.addClass(c);
      return c;
    }

    // Create the class hierarchy:
    //
    // Object
    //   |
    //   A
    //  / \
    // B   C
    // |   |
    // |   D
    //  \ /
    //   E
    var a = addClass('A', []);
    var b = addClass('B', [a]);
    var c = addClass('C', [a]);
    var d = addClass('D', [c]);
    var e = addClass('E', [b, d]);
    var hierarchy = new ClassHierarchy(program);

    expect(hierarchy.getRankedSuperclasses(a), [a, coreTypes.objectClass]);
    expect(hierarchy.getRankedSuperclasses(b), [b, a, coreTypes.objectClass]);
    expect(hierarchy.getRankedSuperclasses(c), [c, a, coreTypes.objectClass]);
    expect(
        hierarchy.getRankedSuperclasses(d), [d, c, a, coreTypes.objectClass]);
    if (hierarchy.getClassIndex(b) < hierarchy.getClassIndex(c)) {
      expect(hierarchy.getRankedSuperclasses(e),
          [e, d, b, c, a, coreTypes.objectClass]);
    } else {
      expect(hierarchy.getRankedSuperclasses(e),
          [e, d, c, b, a, coreTypes.objectClass]);
    }
  });

  test('least_upper_bound_non_generic', () {
    var program = createMockSdkProgram();
    var coreTypes = new CoreTypes(program);
    var defaultSuper = coreTypes.objectClass.asThisSupertype;
    var library = makeTestLibrary(program);

    Class addClass(String name, List<Class> implements_) {
      var c = new Class(
          name: name,
          supertype: defaultSuper,
          implementedTypes: implements_.map((c) => c.asThisSupertype).toList());
      library.addClass(c);
      return c;
    }

    // Create the class hierarchy:
    //
    //    Object
    //     /  \
    //    A    B
    //   /|\
    //  C D E
    //  |X|/
    // FG HI
    //
    // (F and G both implement (C, D); H and I both implement (C, D, E).
    var a = addClass('A', []);
    var b = addClass('B', []);
    var c = addClass('C', [a]);
    var d = addClass('D', [a]);
    var e = addClass('E', [a]);
    var f = addClass('F', [c, d]);
    var g = addClass('G', [c, d]);
    var h = addClass('H', [c, d, e]);
    var i = addClass('I', [c, d, e]);
    var hierarchy = new ClassHierarchy(program);

    expect(hierarchy.getClassicLeastUpperBound(a.rawType, b.rawType),
        coreTypes.objectClass.rawType);
    expect(
        hierarchy.getClassicLeastUpperBound(
            a.rawType, coreTypes.objectClass.rawType),
        coreTypes.objectClass.rawType);
    expect(
        hierarchy.getClassicLeastUpperBound(
            coreTypes.objectClass.rawType, b.rawType),
        coreTypes.objectClass.rawType);
    expect(
        hierarchy.getClassicLeastUpperBound(c.rawType, d.rawType), a.rawType);
    expect(
        hierarchy.getClassicLeastUpperBound(c.rawType, a.rawType), a.rawType);
    expect(
        hierarchy.getClassicLeastUpperBound(a.rawType, d.rawType), a.rawType);
    expect(
        hierarchy.getClassicLeastUpperBound(f.rawType, g.rawType), a.rawType);
    expect(
        hierarchy.getClassicLeastUpperBound(h.rawType, i.rawType), a.rawType);
  });

  test('least_upper_bound_non_generic', () {
    var program = createMockSdkProgram();
    var coreTypes = new CoreTypes(program);
    var defaultSuper = coreTypes.objectClass.asThisSupertype;
    var library = makeTestLibrary(program);
    var int = coreTypes.intClass.rawType;
    var double = coreTypes.doubleClass.rawType;
    var bool = coreTypes.boolClass.rawType;

    Class addClass(String name, List<String> typeParameterNames,
        List<Supertype> implements_(List<DartType> typeParameterTypes)) {
      var typeParameters = typeParameterNames
          .map((name) => new TypeParameter(name, coreTypes.objectClass.rawType))
          .toList();
      var typeParameterTypes = typeParameters
          .map((parameter) => new TypeParameterType(parameter))
          .toList();
      var c = new Class(
          name: name,
          typeParameters: typeParameters,
          supertype: defaultSuper,
          implementedTypes: implements_(typeParameterTypes));
      library.addClass(c);
      return c;
    }

    // Create the class hierarchy:
    //
    //    Object
    //      |
    //      A
    //     / \
    // B<T>   C<U>
    //     \  /
    //    D<T,U>
    //     /  \
    //    E    F
    //
    // Where E implements D<int, double> and F implements D<int, bool>.
    var a = addClass('A', [], (_) => []);
    var b = addClass('B', ['T'], (_) => [a.asThisSupertype]);
    var c = addClass('C', ['U'], (_) => [a.asThisSupertype]);
    var d = addClass('D', ['T', 'U'], (typeParameterTypes) {
      var t = typeParameterTypes[0];
      var u = typeParameterTypes[1];
      return [
        new Supertype(b, [t]),
        new Supertype(c, [u])
      ];
    });
    var e = addClass(
        'E',
        [],
        (_) => [
              new Supertype(d, [int, double])
            ]);
    var f = addClass(
        'F',
        [],
        (_) => [
              new Supertype(d, [int, bool])
            ]);
    var hierarchy = new ClassHierarchy(program);

    expect(
        hierarchy.getClassicLeastUpperBound(new InterfaceType(d, [int, double]),
            new InterfaceType(d, [int, double])),
        new InterfaceType(d, [int, double]));
    expect(
        hierarchy.getClassicLeastUpperBound(new InterfaceType(d, [int, double]),
            new InterfaceType(d, [int, bool])),
        new InterfaceType(b, [int]));
    expect(
        hierarchy.getClassicLeastUpperBound(new InterfaceType(d, [int, double]),
            new InterfaceType(d, [bool, double])),
        new InterfaceType(c, [double]));
    expect(
        hierarchy.getClassicLeastUpperBound(new InterfaceType(d, [int, double]),
            new InterfaceType(d, [bool, int])),
        a.rawType);
    expect(hierarchy.getClassicLeastUpperBound(e.rawType, f.rawType),
        new InterfaceType(b, [int]));
  });
}
