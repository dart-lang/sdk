// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/testing/mock_sdk_component.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/type_algebra.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosedWorldClassHierarchyTest);
  });
}

@reflectiveTest
class ClosedWorldClassHierarchyTest extends _ClassHierarchyTest {
  ClassHierarchy createClassHierarchy(Component component) {
    return new ClassHierarchy(component);
  }

  void test_applyTreeChanges() {
    Class a = addClass(new Class(name: 'A', supertype: objectSuper));
    _assertLibraryText(library, '''
class A {}
''');

    Class b = new Class(name: 'B', supertype: a.asThisSupertype);
    Library libWithB =
        new Library(Uri.parse('org-dartlang:///test_b.dart'), name: 'test_b');
    libWithB.parent = component;
    component.libraries.add(libWithB);
    libWithB.addClass(b);
    _assertLibraryText(libWithB, '''
library test_b;
import self as self;
import "./test.dart" as test;

class B extends test::A {}
''');

    // No updated classes, the same hierarchy.
    expect(hierarchy.applyTreeChanges([], []), same(hierarchy));
    expect(hierarchy.hasProperSubtypes(a), true);

    // Has updated classes, still the same hierarchy (instance). Can answer
    // queries about the new classes.
    var c = new Class(name: 'C', supertype: a.asThisSupertype);
    Library libWithC =
        new Library(Uri.parse('org-dartlang:///test2.dart'), name: 'test2');
    libWithC.parent = component;
    component.libraries.add(libWithC);
    libWithC.addClass(c);

    expect(hierarchy.applyTreeChanges([libWithB], [libWithC]), same(hierarchy));
    expect(hierarchy.isSubclassOf(a, c), false);
    expect(hierarchy.isSubclassOf(c, a), true);
    expect(hierarchy.hasProperSubtypes(a), true);

    // Remove so A should no longer be a super of anything.
    expect(hierarchy.applyTreeChanges([libWithC], []), same(hierarchy));
    expect(hierarchy.hasProperSubtypes(a), false);
  }

  void test_applyMemberChanges() {
    var methodA1 = newEmptyMethod('memberA1');
    var methodA2 = newEmptyMethod('memberA2');
    var methodA3 = newEmptyMethod('memberA3');
    var methodB1 = newEmptyMethod('memberB1');

    var a = addClass(new Class(
        name: 'A', supertype: objectSuper, procedures: [methodA1, methodA2]));
    var b = addClass(new Class(
        name: 'B', supertype: a.asThisSupertype, procedures: [methodB1]));

    _assertTestLibraryText('''
class A {
  method memberA1() → void {}
  method memberA2() → void {}
}
class B extends self::A {
  method memberB1() → void {}
}
''');

    // No changes: B has memberA1, memberA2 and memberB1;
    // A has memberA1 and memberA2
    expect(hierarchy.getDispatchTargets(b),
        unorderedEquals([methodA1, methodA2, methodB1]));
    expect(
        hierarchy.getDispatchTargets(a), unorderedEquals([methodA1, methodA2]));

    // Add a member to A, but only update A.
    a.addMember(methodA3);
    hierarchy.applyMemberChanges([a]);
    expect(hierarchy.getDispatchTargets(b),
        unorderedEquals([methodA1, methodA2, methodB1]));
    expect(hierarchy.getDispatchTargets(a),
        unorderedEquals([methodA1, methodA2, methodA3]));

    // Apply member changes again, this time telling the hierarchy to find
    // descendants.
    hierarchy.applyMemberChanges([a], findDescendants: true);
    expect(hierarchy.getDispatchTargets(b),
        unorderedEquals([methodA1, methodA2, methodA3, methodB1]));
    expect(hierarchy.getDispatchTargets(a),
        unorderedEquals([methodA1, methodA2, methodA3]));
  }

  void test_getSingleTargetForInterfaceInvocation() {
    var methodInA = newEmptyMethod('foo', isAbstract: true);
    var methodInB = newEmptyMethod('foo');
    var methodInD = newEmptyMethod('foo');
    var methodInE = newEmptyMethod('foo');

    var a = addClass(
        new Class(name: 'A', supertype: objectSuper, procedures: [methodInA]));
    var b = addClass(new Class(
        name: 'B',
        isAbstract: true,
        supertype: objectSuper,
        procedures: [methodInB]));
    var c = addClass(new Class(
        name: 'C',
        supertype: b.asThisSupertype,
        implementedTypes: [a.asThisSupertype]));
    addClass(new Class(
        name: 'D', supertype: b.asThisSupertype, procedures: [methodInD]));
    addClass(new Class(
        name: 'E',
        isAbstract: true,
        supertype: objectSuper,
        implementedTypes: [c.asThisSupertype],
        procedures: [methodInE]));

    _assertTestLibraryText('''
class A {
  abstract method foo() → void;
}
abstract class B {
  method foo() → void {}
}
class C extends self::B implements self::A {}
class D extends self::B {
  method foo() → void {}
}
abstract class E implements self::C {
  method foo() → void {}
}
''');

    ClosedWorldClassHierarchy cwch = hierarchy as ClosedWorldClassHierarchy;
    ClassHierarchySubtypes cwchst = cwch.computeSubtypesInformation();

    expect(cwchst.getSingleTargetForInterfaceInvocation(methodInA), methodInB);
    expect(cwchst.getSingleTargetForInterfaceInvocation(methodInB),
        null); // B::foo and D::foo
    expect(cwchst.getSingleTargetForInterfaceInvocation(methodInD), methodInD);
    expect(cwchst.getSingleTargetForInterfaceInvocation(methodInE),
        null); // no concrete subtypes
  }

  void test_getSubtypesOf() {
    var a = addClass(new Class(name: 'A', supertype: objectSuper));
    var b = addClass(new Class(name: 'B', supertype: objectSuper));
    var c = addClass(new Class(name: 'C', supertype: objectSuper));

    var d = addClass(new Class(name: 'D', supertype: a.asThisSupertype));

    var e = addClass(new Class(
        name: 'E',
        supertype: b.asThisSupertype,
        implementedTypes: [c.asThisSupertype]));

    var f = addClass(new Class(
        name: 'F',
        supertype: e.asThisSupertype,
        implementedTypes: [a.asThisSupertype]));

    var g = addClass(new Class(name: 'G', supertype: objectSuper));

    var h = addClass(new Class(
        name: 'H',
        supertype: g.asThisSupertype,
        implementedTypes: [c.asThisSupertype, a.asThisSupertype]));

    _assertTestLibraryText('''
class A {}
class B {}
class C {}
class D extends self::A {}
class E extends self::B implements self::C {}
class F extends self::E implements self::A {}
class G {}
class H extends self::G implements self::C, self::A {}
''');

    ClosedWorldClassHierarchy cwch = hierarchy as ClosedWorldClassHierarchy;
    ClassHierarchySubtypes cwchst = cwch.computeSubtypesInformation();

    expect(cwchst.getSubtypesOf(a), unorderedEquals([a, d, f, h]));
    expect(cwchst.getSubtypesOf(b), unorderedEquals([b, e, f]));
    expect(cwchst.getSubtypesOf(c), unorderedEquals([c, e, f, h]));
    expect(cwchst.getSubtypesOf(d), unorderedEquals([d]));
    expect(cwchst.getSubtypesOf(e), unorderedEquals([e, f]));
    expect(cwchst.getSubtypesOf(f), unorderedEquals([f]));
    expect(cwchst.getSubtypesOf(g), unorderedEquals([g, h]));
    expect(cwchst.getSubtypesOf(h), unorderedEquals([h]));
  }
}

abstract class _ClassHierarchyTest {
  Component component;
  CoreTypes coreTypes;

  /// The test library.
  Library library;

  ClassHierarchy _hierarchy;

  /// Return the new or existing instance of [ClassHierarchy].
  ClassHierarchy get hierarchy {
    return _hierarchy ??= createClassHierarchy(component);
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

  ClassHierarchy createClassHierarchy(Component component);

  Procedure newEmptyGetter(String name,
      {DartType returnType: const DynamicType(), bool isAbstract: false}) {
    var body =
        isAbstract ? null : new Block([new ReturnStatement(new NullLiteral())]);
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
      {bool isAbstract: false, DartType type: const DynamicType()}) {
    var body = isAbstract ? null : new Block([]);
    return new Procedure(
        new Name(name),
        ProcedureKind.Setter,
        new FunctionNode(body,
            returnType: const VoidType(),
            positionalParameters: [new VariableDeclaration('_', type: type)]));
  }

  void setUp() {
    // Start with mock SDK libraries.
    component = createMockSdkComponent();
    coreTypes = new CoreTypes(component);

    // Add the test library.
    library = new Library(Uri.parse('org-dartlang:///test.dart'), name: 'test');
    library.parent = component;
    component.libraries.add(library);
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

    _assertOverridePairs(c, []);
    _assertOverridePairs(e, ['test::A::foo overrides test::B::foo']);
  }

  /// An abstract member declared in the class is overridden by a member in
  /// one of the interfaces.
  void test_forEachOverridePair_supertypeOverridesThis() {
    var a = addClass(new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [newEmptyMethod('foo')]));
    var b = addClass(new Class(
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [newEmptyMethod('foo', isAbstract: true)]));
    var c = addClass(new Class(
        name: 'C',
        supertype: a.asThisSupertype,
        procedures: [newEmptyMethod('foo', isAbstract: true)],
        isAbstract: true));
    var d = addClass(new Class(name: 'D', supertype: b.asThisSupertype));
    var e = addClass(new Class(name: 'E', supertype: c.asThisSupertype));

    _assertTestLibraryText('''
class A {
  method foo() → void {}
}
class B extends self::A {
  abstract method foo() → void;
}
abstract class C extends self::A {
  abstract method foo() → void;
}
class D extends self::B {}
class E extends self::C {}
''');

    _assertOverridePairs(b, ['test::B::foo overrides test::A::foo']);
    _assertOverridePairs(c, ['test::C::foo overrides test::A::foo']);
    _assertOverridePairs(d, []);
    _assertOverridePairs(e, []);
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
    _assertOverridePairs(b, ['test::B::foo overrides test::A::foo']);
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

  void test_getDeclaredMembers() {
    var method = newEmptyMethod('method');
    var getter = newEmptyGetter('getter');
    var setter = newEmptySetter('setter');
    var abstractMethod = newEmptyMethod('abstractMethod', isAbstract: true);
    var abstractGetter = newEmptyGetter('abstractGetter', isAbstract: true);
    var abstractSetter = newEmptySetter('abstractSetter', isAbstract: true);
    var nonFinalField = new Field(new Name('nonFinalField'));
    var finalField = new Field(new Name('finalField'), isFinal: true);
    var a = addClass(new Class(
        isAbstract: true,
        name: 'A',
        supertype: objectSuper,
        fields: [
          nonFinalField,
          finalField
        ],
        procedures: [
          method,
          getter,
          setter,
          abstractMethod,
          abstractGetter,
          abstractSetter
        ]));
    var b = addClass(
        new Class(isAbstract: true, name: 'B', supertype: a.asThisSupertype));

    _assertTestLibraryText('''
abstract class A {
  field dynamic nonFinalField;
  final field dynamic finalField;
  method method() → void {}
  get getter() → dynamic {
    return null;
  }
  set setter(dynamic _) → void {}
  abstract method abstractMethod() → void;
  get abstractGetter() → dynamic;
  set abstractSetter(dynamic _) → void;
}
abstract class B extends self::A {}
''');

    expect(
        hierarchy.getDeclaredMembers(a),
        unorderedEquals([
          method,
          getter,
          abstractMethod,
          abstractGetter,
          nonFinalField,
          finalField
        ]));
    expect(hierarchy.getDeclaredMembers(a, setters: true),
        unorderedEquals([setter, abstractSetter, nonFinalField]));
    expect(hierarchy.getDeclaredMembers(b), isEmpty);
    expect(hierarchy.getDeclaredMembers(b, setters: true), isEmpty);
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

  void test_getInterfaceMembers_in_class() {
    var method = newEmptyMethod('method');
    var getter = newEmptyGetter('getter');
    var setter = newEmptySetter('setter');
    var abstractMethod = newEmptyMethod('abstractMethod', isAbstract: true);
    var abstractGetter = newEmptyGetter('abstractGetter', isAbstract: true);
    var abstractSetter = newEmptySetter('abstractSetter', isAbstract: true);
    var nonFinalField = new Field(new Name('nonFinalField'));
    var finalField = new Field(new Name('finalField'), isFinal: true);
    var a = addClass(new Class(
        isAbstract: true,
        name: 'A',
        supertype: objectSuper,
        fields: [
          nonFinalField,
          finalField
        ],
        procedures: [
          method,
          getter,
          setter,
          abstractMethod,
          abstractGetter,
          abstractSetter
        ]));

    _assertTestLibraryText('''
abstract class A {
  field dynamic nonFinalField;
  final field dynamic finalField;
  method method() → void {}
  get getter() → dynamic {
    return null;
  }
  set setter(dynamic _) → void {}
  abstract method abstractMethod() → void;
  get abstractGetter() → dynamic;
  set abstractSetter(dynamic _) → void;
}
''');

    expect(
        hierarchy.getInterfaceMembers(a),
        unorderedEquals([
          method,
          getter,
          abstractMethod,
          abstractGetter,
          nonFinalField,
          finalField
        ]));
    expect(hierarchy.getInterfaceMembers(a, setters: true),
        unorderedEquals([setter, abstractSetter, nonFinalField]));
  }

  void test_getInterfaceMembers_inherited_or_mixed_in() {
    var method = newEmptyMethod('method');
    var getter = newEmptyGetter('getter');
    var setter = newEmptySetter('setter');
    var abstractMethod = newEmptyMethod('abstractMethod', isAbstract: true);
    var abstractGetter = newEmptyGetter('abstractGetter', isAbstract: true);
    var abstractSetter = newEmptySetter('abstractSetter', isAbstract: true);
    var nonFinalField = new Field(new Name('nonFinalField'));
    var finalField = new Field(new Name('finalField'), isFinal: true);

    var a = addClass(new Class(name: 'A', supertype: objectSuper, fields: [
      nonFinalField,
      finalField
    ], procedures: [
      method,
      getter,
      setter,
      abstractMethod,
      abstractGetter,
      abstractSetter
    ]));
    var b = addClass(new Class(name: 'B', supertype: a.asThisSupertype));
    var c = addClass(new Class(
        isAbstract: true,
        name: 'C',
        supertype: objectSuper,
        implementedTypes: [a.asThisSupertype]));
    var d = addClass(new Class(
        name: 'D', supertype: objectSuper, mixedInType: a.asThisSupertype));

    _assertTestLibraryText('''
class A {
  field dynamic nonFinalField;
  final field dynamic finalField;
  method method() → void {}
  get getter() → dynamic {
    return null;
  }
  set setter(dynamic _) → void {}
  abstract method abstractMethod() → void;
  get abstractGetter() → dynamic;
  set abstractSetter(dynamic _) → void;
}
class B extends self::A {}
abstract class C implements self::A {}
class D = core::Object with self::A {}
''');

    var expectedGetters = [
      method,
      getter,
      abstractMethod,
      abstractGetter,
      nonFinalField,
      finalField
    ];
    expect(hierarchy.getInterfaceMembers(b), unorderedEquals(expectedGetters));
    var expectedSetters = [setter, abstractSetter, nonFinalField];
    expect(hierarchy.getInterfaceMembers(b, setters: true),
        unorderedEquals(expectedSetters));
    expect(hierarchy.getInterfaceMembers(c), unorderedEquals(expectedGetters));
    expect(hierarchy.getInterfaceMembers(c, setters: true),
        unorderedEquals(expectedSetters));
    expect(hierarchy.getInterfaceMembers(d), unorderedEquals(expectedGetters));
    expect(hierarchy.getInterfaceMembers(d, setters: true),
        unorderedEquals(expectedSetters));
  }

  void test_getInterfaceMembers_multiple() {
    var method_a = newEmptyMethod('method');
    var getter_a = newEmptyGetter('getter');
    var setter_a = newEmptySetter('setter');
    var nonFinalField_a = new Field(new Name('nonFinalField'));
    var finalField_a = new Field(new Name('finalField'), isFinal: true);
    var method_b = newEmptyMethod('method');
    var getter_b = newEmptyGetter('getter');
    var setter_b = newEmptySetter('setter');
    var nonFinalField_b = new Field(new Name('nonFinalField'));
    var finalField_b = new Field(new Name('finalField'), isFinal: true);

    var a = addClass(new Class(
        name: 'A',
        supertype: objectSuper,
        fields: [nonFinalField_a, finalField_a],
        procedures: [method_a, getter_a, setter_a]));
    var b = addClass(new Class(
        name: 'B',
        supertype: objectSuper,
        fields: [nonFinalField_b, finalField_b],
        procedures: [method_b, getter_b, setter_b]));
    var c = addClass(new Class(
        isAbstract: true,
        name: 'C',
        supertype: objectSuper,
        implementedTypes: [a.asThisSupertype, b.asThisSupertype]));

    _assertTestLibraryText('''
class A {
  field dynamic nonFinalField;
  final field dynamic finalField;
  method method() → void {}
  get getter() → dynamic {
    return null;
  }
  set setter(dynamic _) → void {}
}
class B {
  field dynamic nonFinalField;
  final field dynamic finalField;
  method method() → void {}
  get getter() → dynamic {
    return null;
  }
  set setter(dynamic _) → void {}
}
abstract class C implements self::A, self::B {}
''');

    expect(
        hierarchy.getInterfaceMembers(c),
        unorderedEquals([
          method_a,
          getter_a,
          nonFinalField_a,
          finalField_a,
          method_b,
          getter_b,
          nonFinalField_b,
          finalField_b
        ]));
    expect(
        hierarchy.getInterfaceMembers(c, setters: true),
        unorderedEquals(
            [setter_a, nonFinalField_a, setter_b, nonFinalField_b]));
  }

  void test_getInterfaceMembers_shadowed() {
    var method_a = newEmptyMethod('method');
    var nonShadowedMethod_a = newEmptyMethod('nonShadowedMethod');
    var getter_a = newEmptyGetter('getter');
    var setter_a = newEmptySetter('setter');
    var nonShadowedSetter_a = newEmptySetter('nonShadowedSetter');
    var nonFinalField_a = new Field(new Name('nonFinalField'));
    var finalField_a = new Field(new Name('finalField'), isFinal: true);
    var method_b = newEmptyMethod('method');
    var getter_b = newEmptyGetter('getter');
    var setter_b = newEmptySetter('setter');
    var nonFinalField_b = new Field(new Name('nonFinalField'));
    var finalField_b = new Field(new Name('finalField'), isFinal: true);

    var a = addClass(new Class(name: 'A', supertype: objectSuper, fields: [
      nonFinalField_a,
      finalField_a
    ], procedures: [
      method_a,
      nonShadowedMethod_a,
      getter_a,
      setter_a,
      nonShadowedSetter_a
    ]));
    var b = addClass(new Class(
        name: 'B',
        supertype: a.asThisSupertype,
        fields: [nonFinalField_b, finalField_b],
        procedures: [method_b, getter_b, setter_b]));

    _assertTestLibraryText('''
class A {
  field dynamic nonFinalField;
  final field dynamic finalField;
  method method() → void {}
  method nonShadowedMethod() → void {}
  get getter() → dynamic {
    return null;
  }
  set setter(dynamic _) → void {}
  set nonShadowedSetter(dynamic _) → void {}
}
class B extends self::A {
  field dynamic nonFinalField;
  final field dynamic finalField;
  method method() → void {}
  get getter() → dynamic {
    return null;
  }
  set setter(dynamic _) → void {}
}
''');

    expect(
        hierarchy.getInterfaceMembers(b),
        unorderedEquals([
          nonShadowedMethod_a,
          method_b,
          getter_b,
          nonFinalField_b,
          finalField_b
        ]));
    expect(hierarchy.getInterfaceMembers(b, setters: true),
        unorderedEquals([nonShadowedSetter_a, setter_b, nonFinalField_b]));
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

  void _assertOverridePairs(Class class_, List<String> expected) {
    List<String> overrideDescriptions = [];
    void callback(
        Member declaredMember, Member interfaceMember, bool isSetter) {
      var suffix = isSetter ? '=' : '';
      String declaredName = '$declaredMember$suffix';
      String interfaceName = '$interfaceMember$suffix';
      var desc = '$declaredName overrides $interfaceName';
      overrideDescriptions.add(desc);
    }

    hierarchy.forEachOverridePair(class_, callback);
    expect(overrideDescriptions, unorderedEquals(expected));
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
}
