// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/incremental_class_hierarchy.dart';
import 'package:kernel/testing/mock_sdk_program.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/type_algebra.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosedWorldClassHierarchyTest);
    defineReflectiveTests(IncrementalClassHierarchyTest);
  });
}

@reflectiveTest
class ClosedWorldClassHierarchyTest extends _ClassHierarchyTest {
  ClassHierarchy createClassHierarchy(Program program) {
    return new ClosedWorldClassHierarchy(program);
  }

  void test_applyChanges() {
    var a = addClass(new Class(name: 'A', supertype: objectSuper));
    addClass(new Class(name: 'B', supertype: a.asThisSupertype));

    _assertTestLibraryText('''
class A {}
class B extends self::A {}
''');

    // No updated classes, the same hierarchy.
    expect(hierarchy.applyChanges([]), same(hierarchy));

    // Has updated classes, a new hierarchy.
    var newHierarchy = hierarchy.applyChanges([a]);
    expect(newHierarchy, isNot(same(hierarchy)));
    expect(newHierarchy, new isInstanceOf<ClosedWorldClassHierarchy>());
  }
}

@reflectiveTest
class IncrementalClassHierarchyTest extends _ClassHierarchyTest {
  ClassHierarchy createClassHierarchy(Program program) {
    return new IncrementalClassHierarchy();
  }

  void test_applyChanges() {
    var a = addClass(new Class(name: 'A', supertype: objectSuper));
    addClass(new Class(name: 'B', supertype: a.asThisSupertype));

    _assertTestLibraryText('''
class A {}
class B extends self::A {}
''');

    // No updated classes, the same hierarchy.
    expect(hierarchy.applyChanges([]), same(hierarchy));

    // Has updated classes, a new hierarchy.
    var newHierarchy = hierarchy.applyChanges([a]);
    expect(newHierarchy, isNot(same(hierarchy)));
    expect(newHierarchy, new isInstanceOf<IncrementalClassHierarchy>());
  }
}

abstract class _ClassHierarchyTest {
  Program program;
  CoreTypes coreTypes;

  /// The test library.
  Library library;

  ClassHierarchy _hierarchy;

  /// Return the new or existing instance of [ClassHierarchy].
  ClassHierarchy get hierarchy {
    return _hierarchy ??= createClassHierarchy(program);
  }

  Class get objectClass => coreTypes.objectClass;

  Supertype get objectSuper => coreTypes.objectClass.asThisSupertype;

  Class addClass(Class c) {
    if (_hierarchy != null) {
      fail('The classs hierarchy has already been created.');
    }
    library.addClass(c);
    return c;
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
        implements_ != null ? implements_(typeParameterTypes) : [];
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

  ClassHierarchy createClassHierarchy(Program program);

  Procedure newEmptyGetter(String name,
      {DartType returnType: const DynamicType()}) {
    var body = new Block([new ReturnStatement(new NullLiteral())]);
    return new Procedure(new Name(name), ProcedureKind.Getter,
        new FunctionNode(body, returnType: returnType));
  }

  Procedure newEmptyMethod(String name, {bool isAbstract: false}) {
    var body = isAbstract ? null : new Block([]);
    return new Procedure(new Name(name), ProcedureKind.Method,
        new FunctionNode(body, returnType: const VoidType()),
        isAbstract: isAbstract);
  }

  Procedure newEmptySetter(String name,
      {bool abstract: false, DartType type: const DynamicType()}) {
    var body = abstract ? null : new Block([]);
    return new Procedure(
        new Name(name),
        ProcedureKind.Setter,
        new FunctionNode(body,
            returnType: const VoidType(),
            positionalParameters: [new VariableDeclaration('_', type: type)]));
  }

  void setUp() {
    // Start with mock SDK libraries.
    program = createMockSdkProgram();
    coreTypes = new CoreTypes(program);

    // Add the test library.
    library = new Library(Uri.parse('org-dartlang:///test.dart'), name: 'test');
    library.parent = program;
    program.libraries.add(library);
  }

  void test_forEachOverridePair_crossGetterSetter_extends() {
    var int = coreTypes.intClass.rawType;
    var a = addClass(new Class(name: 'A', supertype: objectSuper, procedures: [
      newEmptySetter('foo', type: int),
      newEmptyGetter('bar', returnType: int)
    ]));
    var b = addClass(new Class(
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [newEmptyGetter('foo'), newEmptySetter('bar')]));

    _assertTestLibraryText('''
class A {
  set foo(core::int _) → void {}
  get bar() → core::int {
    return null;
  }
}
class B extends self::A {
  get foo() → dynamic {
    return null;
  }
  set bar(dynamic _) → void {}
}
''');

    // No overrides of getters with getters, or setters with setters.
    _assertOverridePairs(b, []);

    // Has cross-overrides between getters and setters.
    _assertOverridePairs(
        b,
        [
          'test::B::foo overrides test::A::foo=',
          'test::B::bar= overrides test::A::bar'
        ],
        crossGettersSetters: true);
  }

  void test_forEachOverridePair_crossGetterSetter_implements() {
    var int = coreTypes.intClass.rawType;
    var double = coreTypes.doubleClass.rawType;
    var a = addClass(new Class(name: 'A', supertype: objectSuper, procedures: [
      newEmptySetter('foo', type: int),
    ]));
    var b = addClass(new Class(name: 'B', supertype: objectSuper, procedures: [
      newEmptySetter('foo', type: double),
    ]));
    var c = addClass(new Class(
        name: 'C',
        supertype: objectSuper,
        implementedTypes: [a.asThisSupertype, b.asThisSupertype],
        procedures: [newEmptyGetter('foo')]));

    _assertTestLibraryText('''
class A {
  set foo(core::int _) → void {}
}
class B {
  set foo(core::double _) → void {}
}
class C implements self::A, self::B {
  get foo() → dynamic {
    return null;
  }
}
''');

    // No overrides of getters with getters, or setters with setters.
    _assertOverridePairs(c, []);

    // Has cross-overrides between getters and setters.
    // Even if these overrides are incompatible with each other.
    _assertOverridePairs(
        c,
        [
          'test::C::foo overrides test::A::foo=',
          'test::C::foo overrides test::B::foo=',
        ],
        crossGettersSetters: true);
  }

  /// 2. A non-abstract member is inherited from a superclass, and in the
  /// context of this class, it overrides an abstract member inheritable through
  /// one of its superinterfaces.
  void test_forEachOverridePair_supertypeOverridesInterface() {
    var a = addClass(new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [newEmptyMethod('foo'), newEmptyMethod('bar')]));
    var b = addClass(new Class(
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [newEmptyMethod('foo', isAbstract: true)]));
    var c = addClass(new Class(
        name: 'C',
        supertype: a.asThisSupertype,
        implementedTypes: [b.asThisSupertype]));
    var d = addClass(new Class(name: 'D', supertype: objectSuper));
    var e = addClass(new Class(
        name: 'E',
        supertype: d.asThisSupertype,
        mixedInType: a.asThisSupertype,
        implementedTypes: [b.asThisSupertype]));

    _assertTestLibraryText('''
class A {
  method foo() → void {}
  method bar() → void {}
}
class B extends self::A {
  abstract method foo() → void;
}
class C extends self::A implements self::B {}
class D {}
class E = self::D with self::A implements self::B {}
''');

    _assertOverridePairs(c, ['test::A::foo overrides test::B::foo']);
    _assertOverridePairs(e, ['test::A::foo overrides test::B::foo']);
  }

  /// 3. A non-abstract member is inherited from a superclass, and it overrides
  /// an abstract member declared in this class.
  void test_forEachOverridePair_supertypeOverridesThisAbstract() {
    var a = addClass(new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [newEmptyMethod('foo'), newEmptyMethod('bar')]));
    var b = addClass(new Class(
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [newEmptyMethod('foo', isAbstract: true)]));

    _assertTestLibraryText('''
class A {
  method foo() → void {}
  method bar() → void {}
}
class B extends self::A {
  abstract method foo() → void;
}
''');

    // The documentation says:
    // It is possible for two methods to override one another in both directions.
    _assertOverridePairs(b, [
      'test::A::foo overrides test::B::foo',
      'test::B::foo overrides test::A::foo'
    ]);
  }

  /// 1. A member declared in the class overrides a member inheritable through
  /// one of the supertypes of the class.
  void test_forEachOverridePair_thisOverridesSupertype() {
    var a = addClass(new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [newEmptyMethod('foo'), newEmptyMethod('bar')]));
    var b = addClass(new Class(
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [newEmptyMethod('foo')]));
    var c = addClass(new Class(
        name: 'C',
        supertype: b.asThisSupertype,
        procedures: [newEmptyMethod('bar')]));

    _assertTestLibraryText('''
class A {
  method foo() → void {}
  method bar() → void {}
}
class B extends self::A {
  method foo() → void {}
}
class C extends self::B {
  method bar() → void {}
}
''');

    _assertOverridePairs(b, ['test::B::foo overrides test::A::foo']);
    _assertOverridePairs(c, ['test::C::bar overrides test::A::bar']);
  }

  /// 1. A member declared in the class overrides a member inheritable through
  /// one of the supertypes of the class.
  void test_forEachOverridePair_thisOverridesSupertype_setter() {
    var a = addClass(new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [newEmptySetter('foo'), newEmptySetter('bar')]));
    var b = addClass(new Class(
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [newEmptySetter('foo')]));
    var c = addClass(new Class(
        name: 'C',
        supertype: b.asThisSupertype,
        procedures: [newEmptySetter('bar')]));

    _assertTestLibraryText('''
class A {
  set foo(dynamic _) → void {}
  set bar(dynamic _) → void {}
}
class B extends self::A {
  set foo(dynamic _) → void {}
}
class C extends self::B {
  set bar(dynamic _) → void {}
}
''');

    _assertOverridePairs(b, ['test::B::foo= overrides test::A::foo=']);
    _assertOverridePairs(c, ['test::C::bar= overrides test::A::bar=']);
  }

  void test_getClassAsInstanceOf_generic_extends() {
    var int = coreTypes.intClass.rawType;
    var bool = coreTypes.boolClass.rawType;

    var a = addGenericClass('A', ['T', 'U']);

    var bT = new TypeParameter('T', objectClass.rawType);
    var bTT = new TypeParameterType(bT);
    var b = addClass(new Class(
        name: 'B',
        typeParameters: [bT],
        supertype: new Supertype(a, [bTT, bool])));

    var c = addClass(new Class(name: 'C', supertype: new Supertype(b, [int])));

    _assertTestLibraryText('''
class A<T, U> {}
class B<T> extends self::A<self::B::T, core::bool> {}
class C extends self::B<core::int> {}
''');

    expect(hierarchy.getClassAsInstanceOf(a, objectClass), objectSuper);
    expect(hierarchy.getClassAsInstanceOf(a, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(b, a), new Supertype(a, [bTT, bool]));
    expect(hierarchy.getClassAsInstanceOf(c, b), new Supertype(b, [int]));
    expect(hierarchy.getClassAsInstanceOf(c, a), new Supertype(a, [int, bool]));
  }

  void test_getClassAsInstanceOf_generic_implements() {
    var int = coreTypes.intClass.rawType;
    var bool = coreTypes.boolClass.rawType;

    var a = addGenericClass('A', ['T', 'U']);

    var bT = new TypeParameter('T', objectClass.rawType);
    var bTT = new TypeParameterType(bT);
    var b = addClass(new Class(
        name: 'B',
        typeParameters: [bT],
        supertype: objectSuper,
        implementedTypes: [
          new Supertype(a, [bTT, bool])
        ]));

    var c = addClass(
        new Class(name: 'C', supertype: objectSuper, implementedTypes: [
      new Supertype(b, [int])
    ]));

    _assertTestLibraryText('''
class A<T, U> {}
class B<T> implements self::A<self::B::T, core::bool> {}
class C implements self::B<core::int> {}
''');

    expect(hierarchy.getClassAsInstanceOf(a, objectClass), objectSuper);
    expect(hierarchy.getClassAsInstanceOf(a, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(b, a), new Supertype(a, [bTT, bool]));
    expect(hierarchy.getClassAsInstanceOf(c, b), new Supertype(b, [int]));
    expect(hierarchy.getClassAsInstanceOf(c, a), new Supertype(a, [int, bool]));
  }

  void test_getClassAsInstanceOf_generic_with() {
    var int = coreTypes.intClass.rawType;
    var bool = coreTypes.boolClass.rawType;

    var a = addGenericClass('A', ['T', 'U']);

    var bT = new TypeParameter('T', objectClass.rawType);
    var bTT = new TypeParameterType(bT);
    var b = addClass(new Class(
        name: 'B',
        typeParameters: [bT],
        supertype: objectSuper,
        mixedInType: new Supertype(a, [bTT, bool])));

    var c = addClass(new Class(
        name: 'C',
        supertype: objectSuper,
        mixedInType: new Supertype(b, [int])));

    _assertTestLibraryText('''
class A<T, U> {}
class B<T> = core::Object with self::A<self::B::T, core::bool> {}
class C = core::Object with self::B<core::int> {}
''');

    expect(hierarchy.getClassAsInstanceOf(a, objectClass), objectSuper);
    expect(hierarchy.getClassAsInstanceOf(a, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(b, a), new Supertype(a, [bTT, bool]));
    expect(hierarchy.getClassAsInstanceOf(c, b), new Supertype(b, [int]));
    expect(hierarchy.getClassAsInstanceOf(c, a), new Supertype(a, [int, bool]));
  }

  void test_getClassAsInstanceOf_notGeneric_extends() {
    var a = addClass(new Class(name: 'A', supertype: objectSuper));
    var b = addClass(new Class(name: 'B', supertype: a.asThisSupertype));
    var c = addClass(new Class(name: 'C', supertype: b.asThisSupertype));
    var z = addClass(new Class(name: 'Z', supertype: objectSuper));

    _assertTestLibraryText('''
class A {}
class B extends self::A {}
class C extends self::B {}
class Z {}
''');

    expect(hierarchy.getClassAsInstanceOf(a, objectClass), objectSuper);
    expect(hierarchy.getClassAsInstanceOf(a, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(b, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(c, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(c, b), b.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(z, a), null);
    expect(hierarchy.getClassAsInstanceOf(z, objectClass), objectSuper);
  }

  void test_getClassAsInstanceOf_notGeneric_implements() {
    var a = addClass(new Class(name: 'A', supertype: objectSuper));
    var b = addClass(new Class(name: 'B', supertype: objectSuper));
    var c = addClass(new Class(
        name: 'C',
        supertype: objectSuper,
        implementedTypes: [a.asThisSupertype]));
    var d = addClass(new Class(
        name: 'D',
        supertype: objectSuper,
        implementedTypes: [c.asThisSupertype]));
    var e = addClass(new Class(
        name: 'D',
        supertype: a.asThisSupertype,
        implementedTypes: [b.asThisSupertype]));
    var z = addClass(new Class(name: 'Z', supertype: objectSuper));

    _assertTestLibraryText('''
class A {}
class B {}
class C implements self::A {}
class D implements self::C {}
class D extends self::A implements self::B {}
class Z {}
''');

    expect(hierarchy.getClassAsInstanceOf(c, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(d, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(d, c), c.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(e, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(e, b), b.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(z, a), null);
  }

  void test_getClassAsInstanceOf_notGeneric_with() {
    var a = addClass(new Class(name: 'A', supertype: objectSuper));
    var b = addClass(new Class(
        name: 'B', supertype: objectSuper, mixedInType: a.asThisSupertype));
    var z = addClass(new Class(name: 'Z', supertype: objectSuper));

    _assertTestLibraryText('''
class A {}
class B = core::Object with self::A {}
class Z {}
''');

    expect(hierarchy.getClassAsInstanceOf(b, objectClass), objectSuper);
    expect(hierarchy.getClassAsInstanceOf(b, a), a.asThisSupertype);
    expect(hierarchy.getClassAsInstanceOf(z, a), null);
  }

  void test_getClassDepth() {
    var base = addClass(new Class(name: 'base', supertype: objectSuper));
    var extends_ =
        addClass(new Class(name: 'extends_', supertype: base.asThisSupertype));
    var with_ = addClass(new Class(
        name: 'with_',
        supertype: objectSuper,
        mixedInType: base.asThisSupertype));
    var implements_ = addClass(new Class(
        name: 'implements_',
        supertype: objectSuper,
        implementedTypes: [base.asThisSupertype]));

    _assertTestLibraryText('''
class base {}
class extends_ extends self::base {}
class with_ = core::Object with self::base {}
class implements_ implements self::base {}
''');

    expect(hierarchy.getClassDepth(objectClass), 0);
    expect(hierarchy.getClassDepth(base), 1);
    expect(hierarchy.getClassDepth(extends_), 2);
    expect(hierarchy.getClassDepth(with_), 2);
    expect(hierarchy.getClassDepth(implements_), 2);
  }

  /// Copy of the tests/language/least_upper_bound_expansive_test.dart test.
  void test_getClassicLeastUpperBound_expansive() {
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
      DartType C1_T = Substitution
          .fromMap({T: new TypeParameterType(T)}).substituteType(C1.thisType);
      DartType N_C1_T =
          Substitution.fromMap({NT: C1_T}).substituteType(N.thisType);
      Supertype N_N_C1_T = Substitution
          .fromMap({NT: N_C1_T}).substituteSupertype(N.asThisSupertype);
      C1.supertype = N_N_C1_T;
    }

    // class C2<T> extends N<N<C2<N<C2<T>>>>> {}
    Class C2;
    {
      var T = new TypeParameter('T', objectClass.rawType);
      C2 = addClass(
          new Class(name: 'C2', typeParameters: [T], supertype: objectSuper));
      DartType C2_T = Substitution
          .fromMap({T: new TypeParameterType(T)}).substituteType(C2.thisType);
      DartType N_C2_T =
          Substitution.fromMap({NT: C2_T}).substituteType(N.thisType);
      DartType C2_N_C2_T =
          Substitution.fromMap({T: N_C2_T}).substituteType(C2.thisType);
      DartType N_C2_N_C2_T =
          Substitution.fromMap({NT: C2_N_C2_T}).substituteType(N.thisType);
      Supertype N_N_C2_N_C2_T = Substitution
          .fromMap({NT: N_C2_N_C2_T}).substituteSupertype(N.asThisSupertype);
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
        hierarchy.getClassicLeastUpperBound(
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
        hierarchy.getClassicLeastUpperBound(
            new InterfaceType(C2, [int]),
            new InterfaceType(N, [
              new InterfaceType(C2, [string])
            ])),
        objectClass.thisType);
  }

  void test_getClassicLeastUpperBound_generic() {
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
  }

  void test_getClassicLeastUpperBound_nonGeneric() {
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

    expect(hierarchy.getClassicLeastUpperBound(a.rawType, b.rawType),
        objectClass.rawType);
    expect(hierarchy.getClassicLeastUpperBound(a.rawType, objectClass.rawType),
        objectClass.rawType);
    expect(hierarchy.getClassicLeastUpperBound(objectClass.rawType, b.rawType),
        objectClass.rawType);
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
  }

  void test_getDispatchTarget() {
    var aMethod = newEmptyMethod('aMethod');
    var aSetter = newEmptySetter('aSetter');
    var bMethod = newEmptyMethod('bMethod');
    var bSetter = newEmptySetter('bSetter');
    var a = addClass(new Class(
        name: 'A', supertype: objectSuper, procedures: [aMethod, aSetter]));
    var b = addClass(new Class(
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [bMethod, bSetter]));
    var c = addClass(new Class(name: 'C', supertype: b.asThisSupertype));

    _assertTestLibraryText('''
class A {
  method aMethod() → void {}
  set aSetter(dynamic _) → void {}
}
class B extends self::A {
  method bMethod() → void {}
  set bSetter(dynamic _) → void {}
}
class C extends self::B {}
''');

    var aMethodName = new Name('aMethod');
    var aSetterName = new Name('aSetter');
    var bMethodName = new Name('bMethod');
    var bSetterName = new Name('bSetter');
    expect(hierarchy.getDispatchTarget(a, aMethodName), aMethod);
    expect(hierarchy.getDispatchTarget(a, bMethodName), isNull);
    expect(hierarchy.getDispatchTarget(a, aSetterName, setter: true), aSetter);
    expect(hierarchy.getDispatchTarget(a, bSetterName, setter: true), isNull);
    expect(hierarchy.getDispatchTarget(b, aMethodName), aMethod);
    expect(hierarchy.getDispatchTarget(b, bMethodName), bMethod);
    expect(hierarchy.getDispatchTarget(b, aSetterName, setter: true), aSetter);
    expect(hierarchy.getDispatchTarget(b, bSetterName, setter: true), bSetter);
    expect(hierarchy.getDispatchTarget(c, aMethodName), aMethod);
    expect(hierarchy.getDispatchTarget(c, bMethodName), bMethod);
    expect(hierarchy.getDispatchTarget(c, aSetterName, setter: true), aSetter);
    expect(hierarchy.getDispatchTarget(c, bSetterName, setter: true), bSetter);
  }

  void test_getDispatchTarget_abstract() {
    var aFoo = newEmptyMethod('foo', isAbstract: true);
    var aBar = newEmptyMethod('bar');
    var bFoo = newEmptyMethod('foo');
    var bBar = newEmptyMethod('bar', isAbstract: true);
    var a = addClass(new Class(
        isAbstract: true,
        name: 'A',
        supertype: objectSuper,
        procedures: [aFoo, aBar]));
    var b = addClass(new Class(
        isAbstract: true,
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [bFoo, bBar]));
    var c = addClass(new Class(name: 'C', supertype: b.asThisSupertype));

    _assertTestLibraryText('''
abstract class A {
  abstract method foo() → void;
  method bar() → void {}
}
abstract class B extends self::A {
  method foo() → void {}
  abstract method bar() → void;
}
class C extends self::B {}
''');

    expect(hierarchy.getDispatchTarget(a, new Name('foo')), isNull);
    expect(hierarchy.getDispatchTarget(b, new Name('foo')), bFoo);
    expect(hierarchy.getDispatchTarget(c, new Name('foo')), bFoo);

    expect(hierarchy.getDispatchTarget(a, new Name('bar')), aBar);
    expect(hierarchy.getDispatchTarget(b, new Name('bar')), aBar);
    expect(hierarchy.getDispatchTarget(c, new Name('bar')), aBar);
  }

  void test_getInterfaceMember_extends() {
    var aMethod = newEmptyMethod('aMethod');
    var aSetter = newEmptySetter('aSetter');
    var bMethod = newEmptyMethod('bMethod');
    var bSetter = newEmptySetter('bSetter');
    var a = addClass(new Class(
        name: 'A', supertype: objectSuper, procedures: [aMethod, aSetter]));
    var b = addClass(new Class(
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [bMethod, bSetter]));
    var c = addClass(new Class(name: 'C', supertype: b.asThisSupertype));

    _assertTestLibraryText('''
class A {
  method aMethod() → void {}
  set aSetter(dynamic _) → void {}
}
class B extends self::A {
  method bMethod() → void {}
  set bSetter(dynamic _) → void {}
}
class C extends self::B {}
''');

    var aMethodName = new Name('aMethod');
    var aSetterName = new Name('aSetter');
    var bMethodName = new Name('bMethod');
    var bSetterName = new Name('bSetter');
    expect(hierarchy.getInterfaceMember(a, aMethodName), aMethod);
    expect(hierarchy.getInterfaceMember(a, bMethodName), isNull);
    expect(hierarchy.getInterfaceMember(a, aSetterName, setter: true), aSetter);
    expect(hierarchy.getInterfaceMember(a, bSetterName, setter: true), isNull);
    expect(hierarchy.getInterfaceMember(b, aMethodName), aMethod);
    expect(hierarchy.getInterfaceMember(b, bMethodName), bMethod);
    expect(hierarchy.getInterfaceMember(b, aSetterName, setter: true), aSetter);
    expect(hierarchy.getInterfaceMember(b, bSetterName, setter: true), bSetter);
    expect(hierarchy.getInterfaceMember(c, aMethodName), aMethod);
    expect(hierarchy.getInterfaceMember(c, bMethodName), bMethod);
    expect(hierarchy.getInterfaceMember(c, aSetterName, setter: true), aSetter);
    expect(hierarchy.getInterfaceMember(c, bSetterName, setter: true), bSetter);
  }

  void test_getInterfaceMember_implements() {
    var aMethod = newEmptyMethod('aMethod');
    var aSetter = newEmptySetter('aSetter');
    var bMethod = newEmptyMethod('bMethod');
    var bSetter = newEmptySetter('bSetter');
    var a = addClass(new Class(
        name: 'A', supertype: objectSuper, procedures: [aMethod, aSetter]));
    var b = addClass(new Class(
        name: 'B',
        supertype: objectSuper,
        implementedTypes: [a.asThisSupertype],
        procedures: [bMethod, bSetter]));
    var c = addClass(new Class(
        name: 'C',
        supertype: objectSuper,
        implementedTypes: [b.asThisSupertype]));

    _assertTestLibraryText('''
class A {
  method aMethod() → void {}
  set aSetter(dynamic _) → void {}
}
class B implements self::A {
  method bMethod() → void {}
  set bSetter(dynamic _) → void {}
}
class C implements self::B {}
''');

    var aMethodName = new Name('aMethod');
    var aSetterName = new Name('aSetter');
    var bMethodName = new Name('bMethod');
    var bSetterName = new Name('bSetter');
    expect(hierarchy.getInterfaceMember(a, aMethodName), aMethod);
    expect(hierarchy.getInterfaceMember(a, bMethodName), isNull);
    expect(hierarchy.getInterfaceMember(a, aSetterName, setter: true), aSetter);
    expect(hierarchy.getInterfaceMember(a, bSetterName, setter: true), isNull);
    expect(hierarchy.getInterfaceMember(b, aMethodName), aMethod);
    expect(hierarchy.getInterfaceMember(b, bMethodName), bMethod);
    expect(hierarchy.getInterfaceMember(b, aSetterName, setter: true), aSetter);
    expect(hierarchy.getInterfaceMember(b, bSetterName, setter: true), bSetter);
    expect(hierarchy.getInterfaceMember(c, aMethodName), aMethod);
    expect(hierarchy.getInterfaceMember(c, bMethodName), bMethod);
    expect(hierarchy.getInterfaceMember(c, aSetterName, setter: true), aSetter);
    expect(hierarchy.getInterfaceMember(c, bSetterName, setter: true), bSetter);
  }

  void test_getOrderedClasses() {
    var a = addClass(new Class(name: 'A', supertype: objectSuper));
    var b = addClass(new Class(name: 'B', supertype: a.asThisSupertype));
    var c = addClass(new Class(name: 'C', supertype: b.asThisSupertype));

    void assertOrderOfClasses(List<Class> unordered, List<Class> expected) {
      var ordered = hierarchy.getOrderedClasses(unordered);
      expect(ordered, expected);
    }

    assertOrderOfClasses([a, b, c], [a, b, c]);
    assertOrderOfClasses([b, a, c], [a, b, c]);
    assertOrderOfClasses([a, c, b], [a, b, c]);
    assertOrderOfClasses([b, c, a], [a, b, c]);
    assertOrderOfClasses([c, a, b], [a, b, c]);
    assertOrderOfClasses([c, b, a], [a, b, c]);
    assertOrderOfClasses([c, b], [b, c]);
  }

  void test_getRankedSuperclasses() {
    var a = addImplementsClass('A', []);
    var b = addImplementsClass('B', [a]);
    var c = addImplementsClass('C', [a]);
    var d = addImplementsClass('D', [c]);
    var e = addImplementsClass('E', [b, d]);

    _assertTestLibraryText('''
class A {}
class B implements self::A {}
class C implements self::A {}
class D implements self::C {}
class E implements self::B, self::D {}
''');

    expect(hierarchy.getRankedSuperclasses(a), [a, objectClass]);
    expect(hierarchy.getRankedSuperclasses(b), [b, a, objectClass]);
    expect(hierarchy.getRankedSuperclasses(c), [c, a, objectClass]);
    expect(hierarchy.getRankedSuperclasses(d), [d, c, a, objectClass]);
    if (hierarchy.getClassIndex(b) < hierarchy.getClassIndex(c)) {
      expect(hierarchy.getRankedSuperclasses(e), [e, d, b, c, a, objectClass]);
    } else {
      expect(hierarchy.getRankedSuperclasses(e), [e, d, c, b, a, objectClass]);
    }
  }

  void test_getTypeAsInstanceOf_generic_extends() {
    var int = coreTypes.intClass.rawType;
    var bool = coreTypes.boolClass.rawType;

    var a = addGenericClass('A', ['T', 'U']);

    var bT = new TypeParameter('T', objectClass.rawType);
    var bTT = new TypeParameterType(bT);
    var b = addClass(new Class(
        name: 'B',
        typeParameters: [bT],
        supertype: new Supertype(a, [bTT, bool])));

    _assertTestLibraryText('''
class A<T, U> {}
class B<T> extends self::A<self::B::T, core::bool> {}
''');

    var b_int = new InterfaceType(b, [int]);
    expect(hierarchy.getTypeAsInstanceOf(b_int, a),
        new InterfaceType(a, [int, bool]));
    expect(hierarchy.getTypeAsInstanceOf(b_int, objectClass),
        new InterfaceType(objectClass));
  }

  void _assertOverridePairs(Class class_, List<String> expected,
      {bool crossGettersSetters: false}) {
    List<String> overrideDescriptions = [];
    hierarchy.forEachOverridePair(class_,
        (Member declaredMember, Member interfaceMember, bool isSetter) {
      String declaredSuffix;
      String interfaceSuffix;
      if (crossGettersSetters) {
        declaredSuffix = _isSetter(declaredMember) ? '=' : '';
        interfaceSuffix = _isSetter(interfaceMember) ? '=' : '';
      } else {
        declaredSuffix = isSetter ? '=' : '';
        interfaceSuffix = isSetter ? '=' : '';
      }
      String declaredName = '$declaredMember$declaredSuffix';
      String interfaceName = '$interfaceMember$interfaceSuffix';
      var desc = '$declaredName overrides $interfaceName';
      overrideDescriptions.add(desc);
    }, crossGettersSetters: crossGettersSetters);
    expect(overrideDescriptions, unorderedEquals(expected));
  }

  /// Assert that the test [library] has the [expectedText] presentation.
  /// The presentation is close, but not identical to the normal Kernel one.
  void _assertTestLibraryText(String expectedText) {
    StringBuffer sb = new StringBuffer();
    Printer printer = new Printer(sb);
    printer.writeLibraryFile(library);

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

  static bool _isSetter(Member member) {
    return member is Procedure && member.kind == ProcedureKind.Setter;
  }
}
