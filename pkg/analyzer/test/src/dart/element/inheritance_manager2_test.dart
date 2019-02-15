// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InheritanceManager2Test);
  });
}

@reflectiveTest
class InheritanceManager2Test extends DriverResolutionTest {
  InheritanceManager2 manager;

  @override
  Future<void> resolveTestFile() async {
    await super.resolveTestFile();
    manager = new InheritanceManager2(
      result.unit.declaredElement.context.typeSystem,
    );
  }

  test_getInherited_closestSuper() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}

class X extends B {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'B.foo: () → void',
    );
  }

  test_getInherited_interfaces() async {
    addTestFile('''
abstract class I {
  void foo();
}

abstrac class J {
  void foo();
}

class X implements I, J {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'J.foo: () → void',
    );
  }

  test_getInherited_mixin() async {
    addTestFile('''
class A {
  void foo() {}
}

mixin M {
  void foo() {}
}

class X extends A with M {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'M.foo: () → void',
    );
  }

  test_getInherited_preferImplemented() async {
    addTestFile('''
class A {
  void foo() {}
}

class I {
  void foo() {}
}

class X extends A implements I {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'A.foo: () → void',
    );
  }

  test_getInheritedConcreteMap_accessor_extends() async {
    addTestFile('''
class A {
  int get foo => 0;
}

class B extends A {}
''');
    await resolveTestFile();

    _assertInheritedConcreteMap('B', r'''
A.foo: () → int
''');
  }

  test_getInheritedConcreteMap_accessor_implements() async {
    addTestFile('''
class A {
  int get foo => 0;
}

abstract class B implements A {}
''');
    await resolveTestFile();
    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_accessor_with() async {
    addTestFile('''
mixin A {
  int get foo => 0;
}

class B extends Object with A {}
''');
    await resolveTestFile();

    _assertInheritedConcreteMap('B', r'''
A.foo: () → int
''');
  }

  test_getInheritedConcreteMap_implicitExtends() async {
    addTestFile('''
class A {}
''');
    await resolveTestFile();
    _assertInheritedConcreteMap('A', '');
  }

  test_getInheritedConcreteMap_method_extends() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {}
''');
    await resolveTestFile();

    _assertInheritedConcreteMap('B', r'''
A.foo: () → void
''');
  }

  test_getInheritedConcreteMap_method_extends_abstract() async {
    addTestFile('''
abstract class A {
  void foo();
}

class B extends A {}
''');
    await resolveTestFile();

    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_method_extends_invalidForImplements() async {
    addTestFile('''
abstract class I {
  void foo(int x, {int y});
  void bar(String s);
}

class A {
  void foo(int x) {}
}

class C extends A implements I {}
''');
    await resolveTestFile();

    _assertInheritedConcreteMap('C', r'''
A.foo: (int) → void
''');
  }

  test_getInheritedConcreteMap_method_implements() async {
    addTestFile('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    await resolveTestFile();

    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_method_with() async {
    addTestFile('''
mixin A {
  void foo() {}
}

class B extends Object with A {}
''');
    await resolveTestFile();

    _assertInheritedConcreteMap('B', r'''
A.foo: () → void
''');
  }

  test_getInheritedConcreteMap_method_with2() async {
    addTestFile('''
mixin A {
  void foo() {}
}

mixin B {
  void bar() {}
}

class C extends Object with A, B {}
''');
    await resolveTestFile();

    _assertInheritedConcreteMap('C', r'''
A.foo: () → void
B.bar: () → void
''');
  }

  test_getInheritedMap_accessor_extends() async {
    addTestFile('''
class A {
  int get foo => 0;
}

class B extends A {}
''');
    await resolveTestFile();

    _assertInheritedMap('B', r'''
A.foo: () → int
''');
  }

  test_getInheritedMap_accessor_implements() async {
    addTestFile('''
class A {
  int get foo => 0;
}

abstract class B implements A {}
''');
    await resolveTestFile();

    _assertInheritedMap('B', r'''
A.foo: () → int
''');
  }

  test_getInheritedMap_accessor_with() async {
    addTestFile('''
mixin A {
  int get foo => 0;
}

class B extends Object with A {}
''');
    await resolveTestFile();

    _assertInheritedMap('B', r'''
A.foo: () → int
''');
  }

  test_getInheritedMap_closestSuper() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}

class X extends B {}
''');
    await resolveTestFile();

    _assertInheritedMap('X', r'''
B.foo: () → void
''');
  }

  test_getInheritedMap_field_extends() async {
    addTestFile('''
class A {
  int foo;
}

class B extends A {}
''');
    await resolveTestFile();

    _assertInheritedMap('B', r'''
A.foo: () → int
A.foo=: (int) → void
''');
  }

  test_getInheritedMap_field_implements() async {
    addTestFile('''
class A {
  int foo;
}

abstract class B implements A {}
''');
    await resolveTestFile();

    _assertInheritedMap('B', r'''
A.foo: () → int
A.foo=: (int) → void
''');
  }

  test_getInheritedMap_field_with() async {
    addTestFile('''
mixin A {
  int foo;
}

class B extends Object with A {}
''');
    await resolveTestFile();

    _assertInheritedMap('B', r'''
A.foo: () → int
A.foo=: (int) → void
''');
  }

  test_getInheritedMap_implicitExtendsObject() async {
    addTestFile('''
class A {}
''');
    await resolveTestFile();

    _assertInheritedMap('A', '');
  }

  test_getInheritedMap_method_extends() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {}
''');
    await resolveTestFile();

    _assertInheritedMap('B', r'''
A.foo: () → void
''');
  }

  test_getInheritedMap_method_implements() async {
    addTestFile('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    await resolveTestFile();

    _assertInheritedMap('B', r'''
A.foo: () → void
''');
  }

  test_getInheritedMap_method_with() async {
    addTestFile('''
mixin A {
  void foo() {}
}

class B extends Object with A {}
''');
    await resolveTestFile();

    _assertInheritedMap('B', r'''
A.foo: () → void
''');
  }

  test_getInheritedMap_preferImplemented() async {
    addTestFile('''
class A {
  void foo() {}
}

class I {
  void foo() {}
}

class X extends A implements I {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertInheritedMap('X', r'''
A.foo: () → void
''');
  }

  test_getInheritedMap_union_conflict() async {
    addTestFile('''
abstract class I {
  int foo();
  void bar();
}

abstract class J {
  double foo();
  void bar();
}

abstract class A implements I, J {}
''');
    await resolveTestFile();

    _assertInheritedMap('A', r'''
J.bar: () → void
''');
  }

  test_getInheritedMap_union_differentNames() async {
    addTestFile('''
abstract class I {
  int foo();
}

abstract class J {
  double bar();
}

abstract class A implements I, J {}
''');
    await resolveTestFile();

    _assertInheritedMap('A', r'''
I.foo: () → int
J.bar: () → double
''');
  }

  test_getInheritedMap_union_multipleSubtypes_2_getters() async {
    addTestFile('''
abstract class I {
  int get foo;
}

abstract class J {
  int get foo;
}

abstract class A implements I, J {}
''');
    await resolveTestFile();

    _assertInheritedMap('A', r'''
J.foo: () → int
''');
  }

  test_getInheritedMap_union_multipleSubtypes_2_methods() async {
    addTestFile('''
abstract class I {
  void foo();
}

abstract class J {
  void foo();
}

abstract class A implements I, J {}
''');
    await resolveTestFile();

    _assertInheritedMap('A', r'''
J.foo: () → void
''');
  }

  test_getInheritedMap_union_multipleSubtypes_2_setters() async {
    addTestFile('''
abstract class I {
  void set foo(num _);
}

abstract class J {
  void set foo(int _);
}

abstract class A implements I, J {}
abstract class B implements J, I {}
''');
    await resolveTestFile();

    _assertInheritedMap('A', r'''
I.foo=: (num) → void
''');

    _assertInheritedMap('B', r'''
I.foo=: (num) → void
''');
  }

  test_getInheritedMap_union_multipleSubtypes_3_getters() async {
    addTestFile('''
class A {}
class B extends A {}
class C extends B {}

abstract class I1 {
  A get foo;
}

abstract class I2 {
  B get foo;
}

abstract class I3 {
  C get foo;
}

abstract class D implements I1, I2, I3 {}
abstract class E implements I3, I2, I1 {}
''');
    await resolveTestFile();

    _assertInheritedMap('D', r'''
I3.foo: () → C
''');

    _assertInheritedMap('E', r'''
I3.foo: () → C
''');
  }

  test_getInheritedMap_union_multipleSubtypes_3_methods() async {
    addTestFile('''
class A {}
class B extends A {}
class C extends B {}

abstract class I1 {
  void foo(A _);
}

abstract class I2 {
  void foo(B _);
}

abstract class I3 {
  void foo(C _);
}

abstract class D implements I1, I2, I3 {}
abstract class E implements I3, I2, I1 {}
''');
    await resolveTestFile();

    _assertInheritedMap('D', r'''
I1.foo: (A) → void
''');
  }

  test_getInheritedMap_union_multipleSubtypes_3_setters() async {
    addTestFile('''
class A {}
class B extends A {}
class C extends B {}

abstract class I1 {
  set foo(A _);
}

abstract class I2 {
  set foo(B _);
}

abstract class I3 {
  set foo(C _);
}

abstract class D implements I1, I2, I3 {}
abstract class E implements I3, I2, I1 {}
''');
    await resolveTestFile();

    _assertInheritedMap('D', r'''
I1.foo=: (A) → void
''');

    _assertInheritedMap('E', r'''
I1.foo=: (A) → void
''');
  }

  test_getInheritedMap_union_oneSubtype_2_methods() async {
    addTestFile('''
abstract class I1 {
  int foo();
}

abstract class I2 {
  int foo([int _]);
}

abstract class A implements I1, I2 {}
abstract class B implements I2, I1 {}
''');
    await resolveTestFile();

    _assertInheritedMap('A', r'''
I2.foo: ([int]) → int
''');

    _assertInheritedMap('B', r'''
I2.foo: ([int]) → int
''');
  }

  test_getInheritedMap_union_oneSubtype_3_methods() async {
    addTestFile('''
abstract class I1 {
  int foo();
}

abstract class I2 {
  int foo([int _]);
}

abstract class I3 {
  int foo([int _, int __]);
}

abstract class A implements I1, I2, I3 {}
abstract class B implements I3, I2, I1 {}
''');
    await resolveTestFile();

    _assertInheritedMap('A', r'''
I3.foo: ([int, int]) → int
''');

    _assertInheritedMap('B', r'''
I3.foo: ([int, int]) → int
''');
  }

  test_getMember() async {
    addTestFile('''
abstract class I1 {
  void f(int i);
}

abstract class I2 {
  void f(Object o);
}

abstract class C implements I1, I2 {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'C',
      name: 'f',
      expected: 'I2.f: (Object) → void',
    );
  }

  test_getMember_concrete() async {
    addTestFile('''
class A {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'A',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: () → void',
    );
  }

  test_getMember_concrete_abstract() async {
    addTestFile('''
abstract class A {
  void foo();
}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'A',
      name: 'foo',
      concrete: true,
    );
  }

  test_getMember_concrete_fromMixedClass() async {
    addTestFile('''
class A {
  void foo() {}
}

class X with A {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'X',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: () → void',
    );
  }

  test_getMember_concrete_fromMixedClass2() async {
    addTestFile('''
class A {
  void foo() {}
}

class B = Object with A;

class X with B {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'X',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: () → void',
    );
  }

  test_getMember_concrete_fromMixedClass_skipObject() async {
    addTestFile('''
class A {
  String toString() => 'A';
}

class B {}

class X extends A with B {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'X',
      name: 'toString',
      concrete: true,
      expected: 'A.toString: () → String',
    );
  }

  test_getMember_concrete_fromMixin() async {
    addTestFile('''
mixin M {
  void foo() {}
}

class X with M {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'X',
      name: 'foo',
      concrete: true,
      expected: 'M.foo: () → void',
    );
  }

  test_getMember_concrete_fromSuper() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {}

abstract class C extends B {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'B',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: () → void',
    );

    _assertGetMember(
      className: 'C',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: () → void',
    );
  }

  test_getMember_concrete_missing() async {
    addTestFile('''
abstract class A {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'A',
      name: 'foo',
      concrete: true,
    );
  }

  test_getMember_concrete_noSuchMethod() async {
    addTestFile('''
class A {
  void foo() {}
}

class B implements A {
  noSuchMethod(_) {}
}

abstract class C extends B {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'B',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: () → void',
    );

    _assertGetMember(
      className: 'C',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: () → void',
    );
  }

  test_getMember_concrete_noSuchMethod_mixin() async {
    addTestFile('''
class A {
  void foo();

  noSuchMethod(_) {}
}

abstract class B extends Object with A {}
''');
    await resolveTestFile();

    // noSuchMethod forwarders are not mixed-in.
    // https://github.com/dart-lang/sdk/issues/33553#issuecomment-424638320
    _assertGetMember(
      className: 'B',
      name: 'foo',
      concrete: true,
    );
  }

  test_getMember_concrete_noSuchMethod_moreSpecificSignature() async {
    addTestFile('''
class A {
  void foo() {}
}

class B implements A {
  noSuchMethod(_) {}
}

class C extends B {
  void foo([int a]);
}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'C',
      name: 'foo',
      concrete: true,
      expected: 'C.foo: ([int]) → void',
    );
  }

  test_getMember_preferLatest_mixin() async {
    addTestFile('''
class A {
  void foo() {}
}

mixin M1 {
  void foo() {}
}

mixin M2 {
  void foo() {}
}

abstract class I {
  void foo();
}

class X extends A with M1, M2 implements I {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'M2.foo: () → void',
    );
  }

  test_getMember_preferLatest_superclass() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}

abstract class I {
  void foo();
}

class X extends B implements I {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'B.foo: () → void',
    );
  }

  test_getMember_preferLatest_this() async {
    addTestFile('''
class A {
  void foo() {}
}

abstract class I {
  void foo();
}

class X extends A implements I {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'X.foo: () → void',
    );
  }

  test_getMember_super_abstract() async {
    addTestFile('''
abstract class A {
  void foo();
}

class B extends A {
  noSuchMethod(_) {}
}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
    );
  }

  test_getMember_super_forMixin_interface() async {
    addTestFile('''
abstract class A {
  void foo();
}

mixin M implements A {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'M',
      name: 'foo',
      forSuper: true,
    );
  }

  test_getMember_super_forMixin_superclassConstraint() async {
    addTestFile('''
abstract class A {
  void foo();
}

mixin M on A {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'M',
      name: 'foo',
      forSuper: true,
      expected: 'A.foo: () → void',
    );
  }

  test_getMember_super_fromMixin() async {
    addTestFile('''
mixin M {
  void foo() {}
}

class X extends Object with M {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'X',
      name: 'foo',
      forSuper: true,
      expected: 'M.foo: () → void',
    );
  }

  test_getMember_super_fromSuper() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
      expected: 'A.foo: () → void',
    );
  }

  test_getMember_super_missing() async {
    addTestFile('''
class A {}

class B extends A {}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
    );
  }

  test_getMember_super_noSuchMember() async {
    addTestFile('''
class A {
  void foo();
  noSuchMethod(_) {}
}

class B extends A {
  void foo() {}
}
''');
    await resolveTestFile();

    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
      expected: 'A.foo: () → void',
    );
  }

  void _assertGetInherited({
    @required String className,
    @required String name,
    String expected,
  }) {
    var interfaceType = findElement.classOrMixin(className).type;

    var memberType = manager.getInherited(
      interfaceType,
      new Name(null, name),
    );

    _assertMemberType(memberType, expected);
  }

  void _assertGetMember({
    @required String className,
    @required String name,
    String expected,
    bool concrete = false,
    bool forSuper = false,
  }) {
    var interfaceType = findElement.classOrMixin(className).type;

    var memberType = manager.getMember(
      interfaceType,
      new Name(null, name),
      concrete: concrete,
      forSuper: forSuper,
    );

    _assertMemberType(memberType, expected);
  }

  void _assertInheritedConcreteMap(String className, String expected) {
    var type = findElement.class_(className).type;
    var map = manager.getInheritedConcreteMap(type);
    _assertNameToFunctionTypeMap(map, expected);
  }

  void _assertInheritedMap(String className, String expected) {
    var type = findElement.class_(className).type;
    var map = manager.getInheritedMap(type);
    _assertNameToFunctionTypeMap(map, expected);
  }

  void _assertMemberType(FunctionType type, String expected) {
    if (expected != null) {
      var element = type.element;
      var enclosingElement = element.enclosingElement;
      var actual = '${enclosingElement.name}.${element.name}: $type';
      expect(actual, expected);
    } else {
      expect(type, isNull);
    }
  }

  void _assertNameToFunctionTypeMap(
      Map<Name, FunctionType> map, String expected) {
    var lines = <String>[];
    for (var name in map.keys) {
      var type = map[name];
      var element = type.element;

      var enclosingElement = element.enclosingElement;
      if (enclosingElement.name == 'Object') continue;

      lines.add('${enclosingElement.name}.${element.name}: $type');
    }

    lines.sort();
    var actual = lines.isNotEmpty ? lines.join('\n') + '\n' : '';

    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
  }
}
