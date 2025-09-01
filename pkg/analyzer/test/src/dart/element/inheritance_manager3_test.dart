// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_printer.dart';
import '../../summary/elements_base.dart';
import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InheritanceManager3Test);
    defineReflectiveTests(InheritanceManager3Test_elements);
    defineReflectiveTests(InheritanceManager3Test_ExtensionType);
    defineReflectiveTests(InheritanceManager3NameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InheritanceManager3NameTest {
  test_equals() {
    expect(Name(null, 'foo'), Name(null, 'foo'));
    expect(Name(null, 'foo'), Name(null, 'foo=').forGetter);
    expect(Name(null, 'foo='), Name(null, 'foo='));
    expect(Name(null, 'foo='), Name(null, 'foo').forSetter);
    expect(Name(null, 'foo='), Name(null, 'foo').forSetter.forSetter.forSetter);
  }

  test_forGetter() {
    var name = Name(null, 'foo');
    expect(name.forGetter.name, 'foo');
    expect(name, name.forGetter);
  }

  test_forGetter_fromSetter() {
    var name = Name(null, 'foo=');
    expect(name.forGetter.name, 'foo');
  }

  test_forSetter() {
    var name = Name(null, 'foo=');
    expect(name.forSetter.name, 'foo=');
    expect(name, name.forSetter);
  }

  test_forSetter_fromGetter() {
    var name = Name(null, 'foo');
    expect(name.forSetter.name, 'foo=');
  }

  test_name_getter() {
    expect(Name(null, 'foo').name, 'foo');
  }

  test_name_setter() {
    expect(Name(null, 'foo=').name, 'foo=');
  }
}

@reflectiveTest
class InheritanceManager3Test extends _InheritanceManager3Base {
  test_getInherited_closestSuper() async {
    await resolveTestCode('''
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
    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'B.foo: void Function()',
    );
  }

  test_getInherited_interfaces() async {
    await resolveTestCode('''
abstract class I {
  void foo();
}

abstract class J {
  void foo();
}

class X implements I, J {
  void foo() {}
}
''');
    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'I.foo: void Function()',
    );
  }

  test_getInherited_mixin() async {
    await resolveTestCode('''
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
    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'M.foo: void Function()',
    );
  }

  test_getInherited_preferImplemented() async {
    await resolveTestCode('''
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
    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'A.foo: void Function()',
    );
  }

  test_getInheritedConcreteMap_accessor_extends() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
}

class B extends A {}
''');
    _assertInheritedConcreteMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedConcreteMap_accessor_implements() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
}

abstract class B implements A {}
''');
    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_accessor_with() async {
    await resolveTestCode('''
mixin A {
  int get foo => 0;
}

class B extends Object with A {}
''');
    _assertInheritedConcreteMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedConcreteMap_ignoresDeclarationInClass() async {
    await resolveTestCode(r'''
class A {}

class B extends A {
  void f() {}
}
''');
    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_implicitExtends() async {
    await resolveTestCode('''
class A {}
''');
    _assertInheritedConcreteMap('A', '');
  }

  test_getInheritedConcreteMap_method_extends() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {}
''');
    _assertInheritedConcreteMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedConcreteMap_method_extends_abstract() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

class B extends A {}
''');
    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_method_extends_invalidForImplements() async {
    await resolveTestCode('''
abstract class I {
  void foo(int x, {int y});
  void bar(String s);
}

class A {
  void foo(int x) {}
}

class C extends A implements I {}
''');
    _assertInheritedConcreteMap('C', r'''
A.foo: void Function(int)
''');
  }

  test_getInheritedConcreteMap_method_implements() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_method_with() async {
    await resolveTestCode('''
mixin A {
  void foo() {}
}

class B extends Object with A {}
''');
    _assertInheritedConcreteMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedConcreteMap_method_with2() async {
    await resolveTestCode('''
mixin A {
  void foo() {}
}

mixin B {
  void bar() {}
}

class C extends Object with A, B {}
''');
    _assertInheritedConcreteMap('C', r'''
A.foo: void Function()
B.bar: void Function()
''');
  }

  test_getInheritedConcreteMap_providesInheritedMemberEvenIfShadowedInClass() async {
    await resolveTestCode(r'''
class A {
  void f() {}
}

class B extends A {
  void f() {}
}
''');
    _assertInheritedConcreteMap('B', '''
A.f: void Function()
''');
  }

  test_getInheritedMap_accessor_extends() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
}

class B extends A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedMap_accessor_implements() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
}

abstract class B implements A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedMap_accessor_with() async {
    await resolveTestCode('''
mixin A {
  int get foo => 0;
}

class B extends Object with A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedMap_closestSuper() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}

class X extends B {}
''');
    _assertInheritedMap('X', r'''
B.foo: void Function()
''');
  }

  test_getInheritedMap_field_extends() async {
    await resolveTestCode('''
class A {
  int foo;
}

class B extends A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
A.foo=: void Function(int)
''');
  }

  test_getInheritedMap_field_implements() async {
    await resolveTestCode('''
class A {
  int foo;
}

abstract class B implements A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
A.foo=: void Function(int)
''');
  }

  test_getInheritedMap_field_with() async {
    await resolveTestCode('''
mixin A {
  int foo;
}

class B extends Object with A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
A.foo=: void Function(int)
''');
  }

  test_getInheritedMap_ignoresDeclarationInClass() async {
    await resolveTestCode(r'''
class A {}

class B extends A {
  void f() {}
}
''');
    _assertInheritedMap('B', '');
  }

  test_getInheritedMap_implicitExtendsObject() async {
    await resolveTestCode('''
class A {}
''');
    _assertInheritedMap('A', '');
  }

  test_getInheritedMap_method_extends() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {}
''');
    _assertInheritedMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedMap_method_implements() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    _assertInheritedMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedMap_method_with() async {
    await resolveTestCode('''
mixin A {
  void foo() {}
}

class B extends Object with A {}
''');
    _assertInheritedMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedMap_preferImplemented() async {
    await resolveTestCode('''
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
    _assertInheritedMap('X', r'''
A.foo: void Function()
''');
  }

  test_getInheritedMap_providesInheritedMemberEvenIfShadowedInClass() async {
    await resolveTestCode(r'''
class A {
  void f() {}
}

class B extends A {
  void f() {}
}
''');
    _assertInheritedMap('B', '''
A.f: void Function()
''');
  }

  test_getInheritedMap_topMerge_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo({int a}) {}
}
''');

    await resolveTestCode('''
import 'a.dart';

class B {
  void foo({required int? a}) {}
}

class C implements A, B {
  void foo({int? a}) {}
}
''');

    _assertInheritedMap('C', r'''
''');
  }

  test_getInheritedMap_union_conflict() async {
    await resolveTestCode('''
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
    _assertInheritedMap('A', r'''
I.bar: void Function()
''');
  }

  test_getInheritedMap_union_differentNames() async {
    await resolveTestCode('''
abstract class I {
  int foo();
}

abstract class J {
  double bar();
}

abstract class A implements I, J {}
''');
    _assertInheritedMap('A', r'''
I.foo: int Function()
J.bar: double Function()
''');
  }

  test_getInheritedMap_union_multipleSubtypes_2_getters() async {
    await resolveTestCode('''
abstract class I {
  int get foo;
}

abstract class J {
  int get foo;
}

abstract class A implements I, J {}
''');
    _assertInheritedMap('A', r'''
I.foo: int Function()
''');
  }

  test_getInheritedMap_union_multipleSubtypes_2_methods() async {
    await resolveTestCode('''
abstract class I {
  void foo();
}

abstract class J {
  void foo();
}

abstract class A implements I, J {}
''');
    _assertInheritedMap('A', r'''
I.foo: void Function()
''');
  }

  test_getInheritedMap_union_multipleSubtypes_2_setters() async {
    await resolveTestCode('''
abstract class I {
  void set foo(num _);
}

abstract class J {
  void set foo(int _);
}

abstract class A implements I, J {}
abstract class B implements J, I {}
''');
    _assertInheritedMap('A', r'''
I.foo=: void Function(num)
''');

    _assertInheritedMap('B', r'''
I.foo=: void Function(num)
''');
  }

  test_getInheritedMap_union_multipleSubtypes_3_getters() async {
    await resolveTestCode('''
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
    _assertInheritedMap('D', r'''
I3.foo: C Function()
''');

    _assertInheritedMap('E', r'''
I3.foo: C Function()
''');
  }

  test_getInheritedMap_union_multipleSubtypes_3_methods() async {
    await resolveTestCode('''
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
    _assertInheritedMap('D', r'''
I1.foo: void Function(A)
''');
  }

  test_getInheritedMap_union_multipleSubtypes_3_setters() async {
    await resolveTestCode('''
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
    _assertInheritedMap('D', r'''
I1.foo=: void Function(A)
''');

    _assertInheritedMap('E', r'''
I1.foo=: void Function(A)
''');
  }

  test_getInheritedMap_union_oneSubtype_2_methods() async {
    await resolveTestCode('''
abstract class I1 {
  int foo();
}

abstract class I2 {
  int foo([int _]);
}

abstract class A implements I1, I2 {}
abstract class B implements I2, I1 {}
''');
    _assertInheritedMap('A', r'''
I2.foo: int Function([int])
''');

    _assertInheritedMap('B', r'''
I2.foo: int Function([int])
''');
  }

  test_getInheritedMap_union_oneSubtype_3_methods() async {
    await resolveTestCode('''
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
    _assertInheritedMap('A', r'''
I3.foo: int Function([int, int])
''');

    _assertInheritedMap('B', r'''
I3.foo: int Function([int, int])
''');
  }

  test_getMember() async {
    await resolveTestCode('''
abstract class I1 {
  void f(int i);
}

abstract class I2 {
  void f(Object o);
}

abstract class C implements I1, I2 {}
''');
    _assertGetMember(
      className: 'C',
      name: 'f',
      expected: 'I2.f: void Function(Object)',
    );
  }

  test_getMember_concrete() async {
    await resolveTestCode('''
class A {
  void foo() {}
}
''');
    _assertGetMember(
      className: 'A',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_abstract() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}
''');
    _assertGetMember(className: 'A', name: 'foo', concrete: true);
  }

  test_getMember_concrete_fromMixedClass() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class X with A {}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_fromMixedClass2() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B = Object with A;

class X with B {}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_fromMixedClass_skipObject() async {
    await resolveTestCode('''
class A {
  String toString() => 'A';
}

class B {}

class X extends A with B {}
''');
    _assertGetMember(
      className: 'X',
      name: 'toString',
      concrete: true,
      expected: 'A.toString: String Function()',
    );
  }

  test_getMember_concrete_fromMixin() async {
    await resolveTestCode('''
mixin M {
  void foo() {}
}

class X with M {}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      concrete: true,
      expected: 'M.foo: void Function()',
    );
  }

  test_getMember_concrete_fromSuper() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {}

abstract class C extends B {}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );

    _assertGetMember(
      className: 'C',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_missing() async {
    await resolveTestCode('''
abstract class A {}
''');
    _assertGetMember(className: 'A', name: 'foo', concrete: true);
  }

  test_getMember_concrete_noSuchMethod() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B implements A {
  noSuchMethod(_) {}
}

abstract class C extends B {}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );

    _assertGetMember(
      className: 'C',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_noSuchMethod_mixin() async {
    await resolveTestCode('''
class A {
  void foo();

  noSuchMethod(_) {}
}

abstract class B extends Object with A {}
''');
    // noSuchMethod forwarders are not mixed-in.
    // https://github.com/dart-lang/sdk/issues/33553#issuecomment-424638320
    _assertGetMember(className: 'B', name: 'foo', concrete: true);
  }

  test_getMember_concrete_noSuchMethod_moreSpecificSignature() async {
    await resolveTestCode('''
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
    _assertGetMember(
      className: 'C',
      name: 'foo',
      concrete: true,
      expected: 'C.foo: void Function([int])',
    );
  }

  test_getMember_fromGenericClass_method_returnType() async {
    await resolveTestCode('''
abstract class B<E> {
  T foo<T>();
}
''');
    var B = findElement2.classOrMixin('B');
    var foo = manager.getMember(B, Name(null, 'foo'))!;
    var T = foo.typeParameters.single;
    var returnType = foo.returnType;
    expect(returnType.element, same(T));
  }

  test_getMember_fromGenericSuper_method_bound() async {
    void checkTextendsFooT(TypeParameterElement t) {
      var otherT = (t.bound as InterfaceType).typeArguments.single.element;
      expect(otherT, same(t));
    }

    await resolveTestCode('''
abstract class Foo<TF> {}
class Bar implements Foo<Bar> {}
abstract class A<XA> {
  T foo<T extends Foo<T>>() => throw '';
}
abstract class B<XB> extends A<XB> {}
''');
    var XB = findElement2.typeParameter('XB');
    var typeXB = XB.instantiate(nullabilitySuffix: NullabilitySuffix.none);
    var B = findElement2.classOrMixin('B');
    var typeB = B.instantiate(
      typeArguments: [typeXB],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var foo = manager.getMember3(typeB, Name(null, 'foo'))!;
    var foo2 = manager.getMember(B, Name(null, 'foo'))!;
    checkTextendsFooT(foo.type.typeParameters.single);
    checkTextendsFooT(foo2.type.typeParameters.single);
    checkTextendsFooT(foo2.typeParameters.single);
    checkTextendsFooT(foo.typeParameters.single);
  }

  test_getMember_fromGenericSuper_method_bound2() async {
    void checkTextendsFooT(TypeParameterElement t) {
      var otherT = (t.bound as InterfaceType).typeArguments.single.element;
      expect(otherT, same(t));
    }

    await resolveTestCode('''
abstract class Foo<T> {}
class Bar implements Foo<Bar> {}
abstract class A<X> {
  T foo<T extends Foo<T>>() => throw '';
}
abstract class B<X> extends A<X> {}
typedef C<V> = B<List<V>>;
abstract class D<XD> extends C<XD> {}
''');
    var XD = findElement2.typeParameter('XD');
    var typeXD = XD.instantiate(nullabilitySuffix: NullabilitySuffix.none);
    var D = findElement2.classOrMixin('D');
    var typeD = D.instantiate(
      typeArguments: [typeXD],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var foo = manager.getMember3(typeD, Name(null, 'foo'))!;
    var foo2 = manager.getMember(D, Name(null, 'foo'))!;
    checkTextendsFooT(foo.type.typeParameters.single);
    checkTextendsFooT(foo2.type.typeParameters.single);
    checkTextendsFooT(foo2.typeParameters.single);
    checkTextendsFooT(foo.typeParameters.single);
  }

  test_getMember_fromGenericSuper_method_returnType() async {
    await resolveTestCode('''
abstract class A<E> {
  T foo<T>();
}

abstract class B<E> extends A<E> {}
''');
    var B = findElement2.classOrMixin('B');
    var foo = manager.getMember(B, Name(null, 'foo'))!;
    var T = foo.typeParameters.single;
    var returnType = foo.returnType;
    // Check that the return type uses the same `T` as `<T>`.
    expect(returnType.element, same(T));
  }

  test_getMember_fromNotGenericSuper_method_returnType() async {
    await resolveTestCode('''
abstract class A {
  T foo<T>();
}

abstract class B extends A {}
''');
    var B = findElement2.classOrMixin('B');
    var foo = manager.getMember(B, Name(null, 'foo'))!;
    var T = foo.typeParameters.single;
    var returnType = foo.returnType;
    expect(returnType.element, same(T));
  }

  test_getMember_method_covariantAfterSubstitutedParameter_merged() async {
    await resolveTestCode(r'''
class A<T> {
  void foo<U>(covariant Object a, U b, int c) {}
}

class B extends A<int> implements C {}

class C {
  void foo<U>(Object a, U b, covariant Object c) {}
}
''');
    var member = manager.getMember(
      findElement2.classOrMixin('B'),
      Name(null, 'foo'),
      concrete: true,
    )!;
    expect(member.formalParameters[0].isCovariant, isTrue);
    expect(member.formalParameters[1].isCovariant, isFalse);
    expect(member.formalParameters[2].isCovariant, isTrue);
  }

  test_getMember_method_covariantByDeclaration_inherited() async {
    await resolveTestCode('''
abstract class A {
  void foo(covariant num a);
}

abstract class B extends A {
  void foo(int a);
}
''');
    var member = manager.getMember(
      findElement2.classOrMixin('B'),
      Name(null, 'foo'),
    )!;
    // TODO(scheglov): It would be nice to use `_assertGetMember`.
    // But we need a way to check covariance.
    // Maybe check the element display string, not the type.
    expect(member.formalParameters[0].isCovariant, isTrue);
  }

  @FailingTest(
    reason:
        'The baseElement and the element associated with the declaration '
        'are not the same',
  )
  test_getMember_method_covariantByDeclaration_merged() async {
    await resolveTestCode('''
class A {
  void foo(covariant num a) {}
}

class B {
  void foo(int a) {}
}

class C extends B implements A {}
''');
    var member = manager.getMember(
      findElement2.classOrMixin('C'),
      Name(null, 'foo'),
      concrete: true,
    )!;
    // TODO(scheglov): It would be nice to use `_assertGetMember`.
    expect(member.baseElement, same(findElement2.method('foo', of: 'B')));
    expect(member.formalParameters[0].isCovariant, isTrue);
  }

  test_getMember_mixin_notMerge_replace() async {
    await resolveTestCode('''
class A<T> {
  T foo() => throw 0;
}

mixin M<T> {
  T foo() => throw 1;
}

class X extends A<dynamic> with M<Object?> {}
class Y extends A<Object?> with M<dynamic> {}
''');
    _assertGetMember2(
      className: 'X',
      name: 'foo',
      expected: 'M.foo: Object? Function()',
    );
    _assertGetMember2(
      className: 'Y',
      name: 'foo',
      expected: 'M.foo: dynamic Function()',
    );
  }

  test_getMember_optIn_inheritsOptIn() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await resolveTestCode('''
import 'a.dart';
class B extends A {
  int? bar(int a) => 0;
}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      expected: 'A.foo: int Function(int, int?)',
    );
    _assertGetMember(
      className: 'B',
      name: 'bar',
      expected: 'B.bar: int? Function(int)',
    );
  }

  test_getMember_optIn_topMerge_getter_existing() async {
    await resolveTestCode('''
class A {
  dynamic get foo => 0;
}

class B {
  Object? get foo => 0;
}

class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'B.foo: Object? Function()',
    );
  }

  test_getMember_optIn_topMerge_getter_synthetic() async {
    await resolveTestCode('''
abstract class A {
  Future<void> get foo;
}

abstract class B {
  Future<dynamic> get foo;
}

abstract class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'X.foo: Future<Object?> Function()',
    );
  }

  test_getMember_optIn_topMerge_method_existing() async {
    await resolveTestCode('''
class A {
  dynamic foo() {}
}

class B {
  Object? foo() {}
}

class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'B.foo: Object? Function()',
    );
  }

  test_getMember_optIn_topMerge_method_synthetic() async {
    await resolveTestCode('''
class A {
  Object? foo(dynamic x) {}
}

class B {
  dynamic foo(Object? x) {}
}

class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'X.foo: Object? Function(Object?)',
    );
  }

  test_getMember_optIn_topMerge_setter_existing() async {
    await resolveTestCode('''
class A {
  set foo(dynamic _) {}
}

class B {
  set foo(Object? _) {}
}

class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo=',
      expected: 'B.foo=: void Function(Object?)',
    );
  }

  test_getMember_optIn_topMerge_setter_synthetic() async {
    await resolveTestCode('''
abstract class A {
  set foo(Future<void> _);
}

abstract class B {
  set foo(Future<dynamic> _);
}

abstract class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo=',
      expected: 'X.foo=: void Function(Future<Object?>)',
    );
  }

  test_getMember_preferLatest_mixin() async {
    await resolveTestCode('''
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
    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'M2.foo: void Function()',
    );
  }

  test_getMember_preferLatest_superclass() async {
    await resolveTestCode('''
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
    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'B.foo: void Function()',
    );
  }

  test_getMember_preferLatest_this() async {
    await resolveTestCode('''
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
    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'X.foo: void Function()',
    );
  }

  test_getMember_setter_covariantByDeclaration_inherited() async {
    await resolveTestCode('''
abstract class A {
  set foo(covariant num a);
}

abstract class B extends A {
  set foo(int a);
}
''');
    var member = manager.getMember(
      findElement2.classOrMixin('B'),
      Name(null, 'foo='),
    )!;
    // TODO(scheglov): It would be nice to use `_assertGetMember`.
    // But we need a way to check covariance.
    // Maybe check the element display string, not the type.
    expect(member.formalParameters[0].isCovariant, isTrue);
  }

  @FailingTest(
    reason:
        'The baseElement and the element associated with the declaration '
        'are not the same',
  )
  test_getMember_setter_covariantByDeclaration_merged() async {
    await resolveTestCode('''
class A {
  set foo(covariant num a) {}
}

class B {
  set foo(int a) {}
}

class C extends B implements A {}
''');
    var member = manager.getMember(
      findElement2.classOrMixin('C'),
      Name(null, 'foo='),
      concrete: true,
    )!;
    // TODO(scheglov): It would be nice to use `_assertGetMember`.
    expect(member.baseElement, same(findElement2.setter('foo', of: 'B')));
    expect(member.formalParameters[0].isCovariant, isTrue);
  }

  test_getMember_super_abstract() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

class B extends A {
  noSuchMethod(_) {}
}
''');
    _assertGetMember(className: 'B', name: 'foo', forSuper: true);
  }

  test_getMember_super_forMixin_interface() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

mixin M implements A {}
''');
    _assertGetMember(className: 'M', name: 'foo', forSuper: true);
  }

  test_getMember_super_forMixin_superclassConstraint() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

mixin M on A {}
''');
    _assertGetMember(
      className: 'M',
      name: 'foo',
      forSuper: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_super_forObject() async {
    await resolveTestCode('''
class A {}
''');
    var member = manager.getMember(
      typeProvider.objectType.element,
      Name(null, 'hashCode'),
      forSuper: true,
    );
    expect(member, isNull);
  }

  test_getMember_super_fromMixin() async {
    await resolveTestCode('''
mixin M {
  void foo() {}
}

class X extends Object with M {
  void foo() {}
}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      forSuper: true,
      expected: 'M.foo: void Function()',
    );
  }

  test_getMember_super_fromSuper() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_super_missing() async {
    await resolveTestCode('''
class A {}

class B extends A {}
''');
    _assertGetMember(className: 'B', name: 'foo', forSuper: true);
  }

  test_getMember_super_noSuchMember() async {
    await resolveTestCode('''
class A {
  void foo();
  noSuchMethod(_) {}
}

class B extends A {
  void foo() {}
}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getOverridden_doesNotShadowIfDirectlyOverriddenByAnotherPath() async {
    await resolveTestCode('''
class A {
  void m() {}
}
class B extends A {
  void m() {}
}
class C extends B implements A {
  void m() {}
}
''');
    _assertGetOverridden4(
      className: 'C',
      name: 'm',
      expected: '''
A.m: void Function()
B.m: void Function()
''',
    );
  }

  test_getOverridden_shadowsTransitiveOverrides() async {
    await resolveTestCode('''
class A {
  void m() {}
}
class B extends A {
  void m() {}
}
class C extends B {
  void m() {}
}
''');
    _assertGetOverridden4(
      className: 'C',
      name: 'm',
      expected: '''
B.m: void Function()
''',
    );
  }
}

@reflectiveTest
class InheritanceManager3Test_elements extends _InheritanceManager3Base2 {
  test_interface_candidatesConflict() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo(int _);
}

abstract class B {
  void foo(String _);
}

abstract class C extends Object with A implements B {}
''');

    var element = library.getClass('C')!;
    assertInterfaceText(element, r'''
overridden
  foo
    <testLibrary>::@mixin::A::@method::foo
    <testLibrary>::@class::B::@method::foo
superImplemented
conflicts
  CandidatesConflict
    <testLibrary>::@mixin::A::@method::foo
    <testLibrary>::@class::B::@method::foo
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_interface_candidatesConflict_interfaceInAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

mixin A {
  void foo(int _);
}

abstract class B {
  void foo(String _);
}

abstract class C extends Object with A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment abstract class C implements B {}
''');

    var library = await buildFileLibrary(a);

    var element = library.getClass('C')!;
    assertInterfaceText(element, r'''
overridden
  foo
    package:test/a.dart::<fragment>::@mixin::A::@method::foo
    package:test/a.dart::<fragment>::@class::B::@method::foo
superImplemented
conflicts
  CandidatesConflict
    package:test/a.dart::<fragment>::@mixin::A::@method::foo
    package:test/a.dart::<fragment>::@class::B::@method::foo
''');
  }

  test_interface_getterMethodConflict() async {
    var library = await buildLibrary(r'''
abstract class A {
  int get foo;
}

abstract class B {
  int foo();
}

abstract class C implements A, B {}
''');

    var element = library.getClass('C')!;
    assertInterfaceText(element, r'''
overridden
  foo
    <testLibrary>::@class::A::@getter::foo
    <testLibrary>::@class::B::@method::foo
superImplemented
conflicts
  GetterMethodConflict
    getter: <testLibrary>::@class::A::@getter::foo
    method: <testLibrary>::@class::B::@method::foo
''');
  }

  test_interface_getterMethodConflict_declares() async {
    var library = await buildLibrary(r'''
abstract class A {
  int get foo;
}

abstract class B {
  int foo();
}

abstract class C implements A, B {
  int foo() => 0;
}
''');

    var element = library.getClass('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@class::C::@method::foo
declared
  foo: <testLibrary>::@class::C::@method::foo
implemented
  foo: <testLibrary>::@class::C::@method::foo
overridden
  foo
    <testLibrary>::@class::A::@getter::foo
    <testLibrary>::@class::B::@method::foo
superImplemented
conflicts
  GetterMethodConflict
    getter: <testLibrary>::@class::A::@getter::foo
    method: <testLibrary>::@class::B::@method::foo
''');
  }
}

@reflectiveTest
class InheritanceManager3Test_ExtensionType extends _InheritanceManager3Base2 {
  @override
  void setUp() {
    super.setUp();
    printerConfiguration.withoutIdenticalImplemented = true;
  }

  test_declareGetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}
''');

    var element = library.getExtensionType('A')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::A::@getter::foo
  it: <testLibrary>::@extensionType::A::@getter::it
declared
  foo: <testLibrary>::@extensionType::A::@getter::foo
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareGetter_implementClass_precludeGetter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}

class B extends A {}

extension type C(B it) implements A {
  int get foo => 0;
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@getter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@getter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@getter::foo
inheritedMap
  foo: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_declareGetter_implementClass_precludeMethod() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

class B extends A {}

extension type C(B it) implements A {
  int get foo => 0;
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@getter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@getter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@method::foo
inheritedMap
  foo: <testLibrary>::@class::A::@method::foo
''');
  }

  test_declareGetter_implementClass_withSetter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(_) {}
}

class B extends A {}

extension type C(B it) implements A {
  int get foo => 0;
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@getter::foo
  foo=: <testLibrary>::@class::A::@setter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@getter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo=
    <testLibrary>::@class::A::@setter::foo
inheritedMap
  foo=: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_declareGetter_static() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int get foo => 0;
}
''');

    var element = library.getExtensionType('A')!;
    assertInterfaceText(element, r'''
map
  it: <testLibrary>::@extensionType::A::@getter::it
declared
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareMethod() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}
''');

    var element = library.getExtensionType('A')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::A::@method::foo
  it: <testLibrary>::@extensionType::A::@getter::it
declared
  foo: <testLibrary>::@extensionType::A::@method::foo
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareMethod_implementClass_implementExtensionType_wouldConflict() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

extension type B(A it) {
  void foo() {}
}

extension type C(A it) implements A, B {
  void foo() {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::B::@method::foo
    <testLibrary>::@class::A::@method::foo
  it
    <testLibrary>::@extensionType::B::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
''');
  }

  test_declareMethod_implementClass_method2_wouldConflict() async {
    var library = await buildLibrary(r'''
class A {
  int foo() => 0;
}

class B {
  String foo() => '0';
}

extension type C(Object it) implements A, B {
  void foo() {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@method::foo
    <testLibrary>::@class::B::@method::foo
''');
  }

  test_declareMethod_implementClass_noPreclude() async {
    var library = await buildLibrary(r'''
class A {}

class B extends A {
  void foo() {}
}

extension type C(B it) implements A {
  void foo() {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
''');
  }

  test_declareMethod_implementClass_precludeGetter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}

class B extends A {
  void bar() {}
}

extension type C(B it) implements A {
  void foo() {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@getter::foo
inheritedMap
  foo: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_declareMethod_implementClass_precludeMethod() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

class B extends A {
  void bar() {}
}

extension type C(B it) implements A {
  void foo() {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@method::foo
inheritedMap
  foo: <testLibrary>::@class::A::@method::foo
''');
  }

  test_declareMethod_implementClass_precludeSetter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(_) {}
}

class B extends A {}

extension type C(B it) implements A {
  void foo() {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo=
    <testLibrary>::@class::A::@setter::foo
inheritedMap
  foo=: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_declareMethod_implementExtensionType_method2_wouldConflict() async {
    var library = await buildLibrary(r'''
extension type A1(int it) {
  void foo() {}
}

extension type A2(int it) {
  void foo() {}
}

extension type B(int it) implements A1, A2 {
  void foo() {}
}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::A1::@method::foo
    <testLibrary>::@extensionType::A2::@method::foo
  it
    <testLibrary>::@extensionType::A1::@getter::it
    <testLibrary>::@extensionType::A2::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::A1::@method::foo
  it: <testLibrary>::@extensionType::A1::@getter::it
''');
  }

  test_declareMethod_implementExtensionType_precludeGetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  void foo() {}
}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::A::@getter::foo
  it
    <testLibrary>::@extensionType::A::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::A::@getter::foo
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareMethod_implementExtensionType_precludeMethod() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  void foo() {}
}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::A::@method::foo
  it
    <testLibrary>::@extensionType::A::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::A::@method::foo
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareMethod_implementExtensionType_precludeSetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo(_) {}
}

extension type B(int it) implements A {
  void foo() {}
}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo=
    <testLibrary>::@extensionType::A::@setter::foo
  it
    <testLibrary>::@extensionType::A::@getter::it
inheritedMap
  foo=: <testLibrary>::@extensionType::A::@setter::foo
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareMethod_static() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static void foo() {}
}
''');

    var element = library.getExtensionType('A')!;
    assertInterfaceText(element, r'''
map
  it: <testLibrary>::@extensionType::A::@getter::it
declared
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareSetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo(int _) {}
}
''');

    var element = library.getExtensionType('A')!;
    assertInterfaceText(element, r'''
map
  foo=: <testLibrary>::@extensionType::A::@setter::foo
  it: <testLibrary>::@extensionType::A::@getter::it
declared
  foo=: <testLibrary>::@extensionType::A::@setter::foo
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareSetter_implementClass_withGetter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}

class B extends A {}

extension type C(B it) implements A {
  set foo(_) {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@class::A::@getter::foo
  foo=: <testLibrary>::@extensionType::C::@setter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo=: <testLibrary>::@extensionType::C::@setter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@getter::foo
inheritedMap
  foo: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_declareSetter_implementClass_withMethod() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

class B extends A {}

extension type C(B it) implements A {
  set foo(_) {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo=: <testLibrary>::@extensionType::C::@setter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo=: <testLibrary>::@extensionType::C::@setter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@method::foo
inheritedMap
  foo: <testLibrary>::@class::A::@method::foo
''');
  }

  test_declareSetter_implementExtensionType_withGetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  set foo(_) {}
}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::A::@getter::foo
  foo=: <testLibrary>::@extensionType::B::@setter::foo
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  foo=: <testLibrary>::@extensionType::B::@setter::foo
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::A::@getter::foo
  it
    <testLibrary>::@extensionType::A::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::A::@getter::foo
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareSetter_implementExtensionType_withMethod() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  set foo(_) {}
}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo=: <testLibrary>::@extensionType::B::@setter::foo
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  foo=: <testLibrary>::@extensionType::B::@setter::foo
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::A::@method::foo
  it
    <testLibrary>::@extensionType::A::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::A::@method::foo
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_declareSetter_static() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static set foo(int _) {}
}
''');

    var element = library.getExtensionType('A')!;
    assertInterfaceText(element, r'''
map
  it: <testLibrary>::@extensionType::A::@getter::it
declared
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_noDeclaration_implementClass_generic_method() async {
    var library = await buildLibrary(r'''
class A<T> {
  void foo(T a) {}
}

class B extends A<int> {}

extension type C(B it) implements A<int> {}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: MethodMember
    baseElement: <testLibrary>::@class::A::@method::foo
    substitution: {T: int}
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    MethodMember
      baseElement: <testLibrary>::@class::A::@method::foo
      substitution: {T: int}
inheritedMap
  foo: MethodMember
    baseElement: <testLibrary>::@class::A::@method::foo
    substitution: {T: int}
''');
  }

  test_noDeclaration_implementClass_implementExtensionType_hasConflict_methods() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

extension type B(A it) {
  void foo() {}
}

extension type C(A it) implements A, B {}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::B::@method::foo
    <testLibrary>::@class::A::@method::foo
  it
    <testLibrary>::@extensionType::B::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
conflicts
  HasNonExtensionAndExtensionMemberConflict
    nonExtension
      <testLibrary>::@class::A::@method::foo
    extension
      <testLibrary>::@extensionType::B::@method::foo
''');
  }

  test_noDeclaration_implementClass_implementExtensionType_hasConflict_setters() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int _) {}
}

extension type B(A it) {
  set foo(int _) {}
}

extension type C(A it) implements A, B {}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo=
    <testLibrary>::@extensionType::B::@setter::foo
    <testLibrary>::@class::A::@setter::foo
  it
    <testLibrary>::@extensionType::B::@getter::it
inheritedMap
  foo=: <testLibrary>::@extensionType::B::@setter::foo
  it: <testLibrary>::@extensionType::B::@getter::it
conflicts
  HasNonExtensionAndExtensionMemberConflict
    nonExtension
      <testLibrary>::@class::A::@setter::foo
    extension
      <testLibrary>::@extensionType::B::@setter::foo
''');
  }

  test_noDeclaration_implementClass_implementExtensionType_noConflict_methodPrecludesSetters() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int _) {}
}

extension type B(A it) {
  set foo(int _) {}
}

extension type C(A it) implements A, B {
  void foo() {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo: <testLibrary>::@extensionType::C::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo=
    <testLibrary>::@extensionType::B::@setter::foo
    <testLibrary>::@class::A::@setter::foo
  it
    <testLibrary>::@extensionType::B::@getter::it
inheritedMap
  foo=: <testLibrary>::@extensionType::B::@setter::foo
  it: <testLibrary>::@extensionType::B::@getter::it
''');
  }

  test_noDeclaration_implementClass_implementExtensionType_noConflict_setterPrecludesMethods() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

extension type B(A it) {
  void foo() {}
}

extension type C(A it) implements A, B {
  set foo(int _) {}
}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo=: <testLibrary>::@extensionType::C::@setter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  foo=: <testLibrary>::@extensionType::C::@setter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::B::@method::foo
    <testLibrary>::@class::A::@method::foo
  it
    <testLibrary>::@extensionType::B::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
''');
  }

  test_noDeclaration_implementClass_method() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
}

class B extends A {}

extension type C(B it) implements A {}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@class::A::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@method::foo
inheritedMap
  foo: <testLibrary>::@class::A::@method::foo
''');
  }

  test_noDeclaration_implementClass_method2_hasConflict() async {
    var library = await buildLibrary(r'''
class A {
  int foo() => 0;
}

class B {
  String foo() => '0';
}

extension type C(Object it) implements A, B {}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@method::foo
    <testLibrary>::@class::B::@method::foo
conflicts
  CandidatesConflict
    <testLibrary>::@class::A::@method::foo
    <testLibrary>::@class::B::@method::foo
''');
  }

  test_noDeclaration_implementClass_method2_noConflict() async {
    var library = await buildLibrary(r'''
class A {
  int foo() => 0;
}

class B {
  num foo() => 0;
}

extension type C(Object it) implements A, B {}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@class::A::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@method::foo
    <testLibrary>::@class::B::@method::foo
inheritedMap
  foo: <testLibrary>::@class::A::@method::foo
''');
  }

  test_noDeclaration_implementClass_method2_noConflict2() async {
    var library = await buildLibrary(r'''
class A {
  int foo() => 0;
}

class B1 extends A {}

class B2 extends A {}

abstract class C implements B1, B2 {}

extension type D(C it) implements B1, B2 {}
''');

    var element = library.getExtensionType('D')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@class::A::@method::foo
  it: <testLibrary>::@extensionType::D::@getter::it
declared
  it: <testLibrary>::@extensionType::D::@getter::it
redeclared
  foo
    <testLibrary>::@class::A::@method::foo
inheritedMap
  foo: <testLibrary>::@class::A::@method::foo
''');
  }

  test_noDeclaration_implementClass_setter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int _) {}
}

class B extends A {}

extension type C(B it) implements A {}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo=: <testLibrary>::@class::A::@setter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo=
    <testLibrary>::@class::A::@setter::foo
inheritedMap
  foo=: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_noDeclaration_implementExtensionType_generic_method() async {
    var library = await buildLibrary(r'''
extension type A<T>(T it) {
  void foo(T a) {}
}

extension type B(int it) implements A<int> {}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo: MethodMember
    baseElement: <testLibrary>::@extensionType::A::@method::foo
    substitution: {T: int}
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo
    MethodMember
      baseElement: <testLibrary>::@extensionType::A::@method::foo
      substitution: {T: int}
  it
    GetterMember
      baseElement: <testLibrary>::@extensionType::A::@getter::it
      substitution: {T: int}
inheritedMap
  foo: MethodMember
    baseElement: <testLibrary>::@extensionType::A::@method::foo
    substitution: {T: int}
  it: GetterMember
    baseElement: <testLibrary>::@extensionType::A::@getter::it
    substitution: {T: int}
''');
  }

  test_noDeclaration_implementExtensionType_method() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::A::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::A::@method::foo
  it
    <testLibrary>::@extensionType::A::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::A::@method::foo
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_noDeclaration_implementExtensionType_method2_hasConflict() async {
    var library = await buildLibrary(r'''
extension type A1(int it) {
  void foo() {}
}

extension type A2(int it) {
  void foo() {}
}

extension type B(int it) implements A1, A2 {}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::A1::@method::foo
    <testLibrary>::@extensionType::A2::@method::foo
  it
    <testLibrary>::@extensionType::A1::@getter::it
    <testLibrary>::@extensionType::A2::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::A1::@method::foo
  it: <testLibrary>::@extensionType::A1::@getter::it
conflicts
  NotUniqueExtensionMemberConflict
    <testLibrary>::@extensionType::A1::@method::foo
    <testLibrary>::@extensionType::A2::@method::foo
''');
  }

  test_noDeclaration_implementExtensionType_method2_noConflict_setterPrecludes() async {
    var library = await buildLibrary(r'''
extension type A1(int it) {
  void foo() {}
}

extension type A2(int it) {
  void foo() {}
}

extension type B(int it) implements A1, A2 {
  set foo(int _) {}
}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo=: <testLibrary>::@extensionType::B::@setter::foo
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  foo=: <testLibrary>::@extensionType::B::@setter::foo
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::A1::@method::foo
    <testLibrary>::@extensionType::A2::@method::foo
  it
    <testLibrary>::@extensionType::A1::@getter::it
    <testLibrary>::@extensionType::A2::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::A1::@method::foo
  it: <testLibrary>::@extensionType::A1::@getter::it
''');
  }

  test_noDeclaration_implementExtensionType_method2_noConflict_unique() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

extension type B1(int it) implements A {}

extension type B2(int it) implements A {}

extension type C(int it) implements B1, B2 {}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::A::@method::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo
    <testLibrary>::@extensionType::A::@method::foo
  it
    <testLibrary>::@extensionType::B1::@getter::it
    <testLibrary>::@extensionType::B2::@getter::it
inheritedMap
  foo: <testLibrary>::@extensionType::A::@method::foo
  it: <testLibrary>::@extensionType::B1::@getter::it
''');
  }

  test_noDeclaration_implementExtensionType_setter2_hasConflict() async {
    var library = await buildLibrary(r'''
extension type A1(int it) {
  set foo(int _) {}
}

extension type A2(int it) {
  set foo(int _) {}
}

extension type B(int it) implements A1, A2 {}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo=
    <testLibrary>::@extensionType::A1::@setter::foo
    <testLibrary>::@extensionType::A2::@setter::foo
  it
    <testLibrary>::@extensionType::A1::@getter::it
    <testLibrary>::@extensionType::A2::@getter::it
inheritedMap
  foo=: <testLibrary>::@extensionType::A1::@setter::foo
  it: <testLibrary>::@extensionType::A1::@getter::it
conflicts
  NotUniqueExtensionMemberConflict
    <testLibrary>::@extensionType::A1::@setter::foo
    <testLibrary>::@extensionType::A2::@setter::foo
''');
  }

  test_noDeclaration_implementExtensionType_setter2_noConflict_methodPrecludes() async {
    var library = await buildLibrary(r'''
extension type A1(int it) {
  set foo(int _) {}
}

extension type A2(int it) {
  set foo(int _) {}
}

extension type B(int it) implements A1, A2 {
  void foo() {}
}
''');

    var element = library.getExtensionType('B')!;
    assertInterfaceText(element, r'''
map
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
declared
  foo: <testLibrary>::@extensionType::B::@method::foo
  it: <testLibrary>::@extensionType::B::@getter::it
redeclared
  foo=
    <testLibrary>::@extensionType::A1::@setter::foo
    <testLibrary>::@extensionType::A2::@setter::foo
  it
    <testLibrary>::@extensionType::A1::@getter::it
    <testLibrary>::@extensionType::A2::@getter::it
inheritedMap
  foo=: <testLibrary>::@extensionType::A1::@setter::foo
  it: <testLibrary>::@extensionType::A1::@getter::it
''');
  }

  test_noDeclaration_implementExtensionType_setter2_noConflict_unique() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo(int _) {}
}

extension type B1(int it) implements A {}

extension type B2(int it) implements A {}

extension type C(int it) implements B1, B2 {}
''');

    var element = library.getExtensionType('C')!;
    assertInterfaceText(element, r'''
map
  foo=: <testLibrary>::@extensionType::A::@setter::foo
  it: <testLibrary>::@extensionType::C::@getter::it
declared
  it: <testLibrary>::@extensionType::C::@getter::it
redeclared
  foo=
    <testLibrary>::@extensionType::A::@setter::foo
  it
    <testLibrary>::@extensionType::B1::@getter::it
    <testLibrary>::@extensionType::B2::@getter::it
inheritedMap
  foo=: <testLibrary>::@extensionType::A::@setter::foo
  it: <testLibrary>::@extensionType::B1::@getter::it
''');
  }

  test_withObjectMembers() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}
''');

    var element = library.getExtensionType('A')!;
    printerConfiguration.withObjectMembers = true;
    assertInterfaceText(element, r'''
map
  it: <testLibrary>::@extensionType::A::@getter::it
declared
  it: <testLibrary>::@extensionType::A::@getter::it
''');
  }
}

class _InheritanceManager3Base extends PubPackageResolutionTest {
  late final InheritanceManager3 manager;

  @override
  Future<void> resolveTestFile() async {
    await super.resolveTestFile();
    manager = InheritanceManager3();
  }

  void _assertExecutable(ExecutableElement? element, String? expected) {
    if (expected != null && element != null) {
      var enclosingElement = element.enclosingElement;

      var type = element.type;
      var typeStr = typeString(type);

      var actual = '${enclosingElement?.name}.${element.lookupName}: $typeStr';
      expect(actual, expected);

      if (element is GetterElement) {
        var variable = element.variable;
        expect(variable.enclosingElement, same(enclosingElement));
        expect(variable.name, element.displayName);
        expect(variable.type, element.returnType);
      } else if (element is SetterElement) {
        var variable = element.variable;
        expect(variable.enclosingElement, same(enclosingElement));
        expect(variable.name, element.displayName);
        expect(variable.type, element.formalParameters[0].type);
      }
    } else {
      expect(element, isNull);
    }
  }

  void _assertExecutableList(
    List<ExecutableElement>? elements,
    String? expected,
  ) {
    var elementsString = elements == null
        ? null
        : [
            for (var element in elements)
              '${element.enclosingElement?.name}.${element.lookupName}: '
                  '${typeString(element.type)}\n',
          ].sorted().join();
    expect(elementsString, expected);
  }

  void _assertGetInherited({
    required String className,
    required String name,
    String? expected,
  }) {
    var member = manager.getInherited(
      findElement2.classOrMixin(className),
      Name(null, name),
    );

    _assertExecutable(member, expected);
  }

  void _assertGetMember({
    required String className,
    required String name,
    String? expected,
    bool concrete = false,
    bool forSuper = false,
  }) {
    var member = manager.getMember(
      findElement2.classOrMixin(className),
      Name(null, name),
      concrete: concrete,
      forSuper: forSuper,
    );

    _assertExecutable(member, expected);
  }

  void _assertGetMember2({
    required String className,
    required String name,
    String? expected,
  }) {
    _assertGetMember(className: className, name: name, expected: expected);

    _assertGetMember(
      className: className,
      name: name,
      expected: expected,
      concrete: true,
    );
  }

  void _assertGetOverridden4({
    required String className,
    required String name,
    String? expected,
  }) {
    var members = manager.getOverridden(
      findElement2.classOrMixin(className),
      Name(null, name),
    );

    _assertExecutableList(members, expected);
  }

  void _assertInheritedConcreteMap(String className, String expected) {
    var element = findElement2.classOrMixin(className);
    var map = manager.getInheritedConcreteMap(element);
    _assertNameToExecutableMap(map, expected);
  }

  void _assertInheritedMap(String className, String expected) {
    var element = findElement2.classOrMixin(className);
    var map = manager.getInheritedMap(element);
    _assertNameToExecutableMap(map, expected);
  }

  void _assertNameToExecutableMap(
    Map<Name, ExecutableElement> map,
    String expected,
  ) {
    var lines = <String>[];
    for (var entry in map.entries) {
      var element = entry.value;
      var type = element.type;

      var enclosingElement = element.enclosingElement;
      if (enclosingElement?.name == 'Object') continue;

      var typeStr = type.getDisplayString();
      lines.add('${enclosingElement?.name}.${element.lookupName}: $typeStr');
    }

    lines.sort();
    var actual = lines.isNotEmpty ? '${lines.join('\n')}\n' : '';

    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
  }
}

class _InheritanceManager3Base2 extends ElementsBaseTest {
  final printerConfiguration = _InstancePrinterConfiguration();

  @override
  bool get keepLinkingLibraries => true;

  void assertInterfaceText(InterfaceElementImpl element, String expected) {
    var actual = _interfaceText(element);
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  String _interfaceText(InterfaceElementImpl element) {
    var library = element.library;
    var inheritance = library.session.inheritanceManager;
    var interface = inheritance.getInterface(element);

    // Should not throw.
    inheritance.getInheritedConcreteMap(element);

    // Ensure that `inheritedMap` field is initialized.
    inheritance.getInheritedMap(element);

    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    _InterfacePrinter(
      sink: sink,
      elementPrinter: elementPrinter,
      configuration: printerConfiguration,
    ).write(interface);

    return buffer.toString();
  }
}

class _InstancePrinterConfiguration {
  bool withObjectMembers = false;
  bool withoutIdenticalImplemented = false;
}

class _InterfacePrinter {
  final TreeStringSink _sink;
  final ElementPrinter _elementPrinter;
  final _InstancePrinterConfiguration _configuration;

  _InterfacePrinter({
    required TreeStringSink sink,
    required ElementPrinter elementPrinter,
    required _InstancePrinterConfiguration configuration,
  }) : _sink = sink,
       _elementPrinter = elementPrinter,
       _configuration = configuration;

  void write(Interface interface) {
    _writeNameToMap('map', interface.map);
    _writeNameToMap('declared', interface.declared);

    if (_configuration.withoutIdenticalImplemented) {
      expect(interface.implemented, same(interface.map));
    } else {
      _writeNameToMap('implemented', interface.implemented);
    }

    _writeNameToListMap('overridden', interface.overridden);
    _writeNameToListMap('redeclared', interface.redeclared);
    _writeListOfMaps('superImplemented', interface.superImplemented);
    _writeNameToMap('inheritedMap', interface.inheritedMap ?? {});
    _writeConflicts(interface.conflicts);
  }

  String _nameObjStr(Name nameObj) {
    return nameObj.name;
  }

  bool _shouldWrite(ExecutableElement element) {
    return _configuration.withObjectMembers || !element.isObjectMember;
  }

  List<MapEntry<Name, T>> _sortedEntries<T>(
    Iterable<MapEntry<Name, T>> entries,
  ) {
    return entries.sortedBy((e) => '${e.key.name} ${e.key.libraryUri}');
  }

  List<ExecutableElement> _withoutObject(List<ExecutableElement> elements) {
    return elements.where(_shouldWrite).toList();
  }

  void _writeConflicts(List<Conflict> conflicts) {
    if (conflicts.isEmpty) return;

    _sink.writelnWithIndent('conflicts');
    _sink.withIndent(() {
      for (var conflict in conflicts) {
        switch (conflict) {
          case CandidatesConflict _:
            _elementPrinter.writeElementList2(
              'CandidatesConflict',
              conflict.candidates,
            );
          case GetterMethodConflict _:
            _sink.writelnWithIndent('GetterMethodConflict');
            _sink.withIndent(() {
              _elementPrinter.writeNamedElement2('getter', conflict.getter);
              _elementPrinter.writeNamedElement2('method', conflict.method);
            });
          case HasNonExtensionAndExtensionMemberConflict _:
            _sink.writelnWithIndent(
              'HasNonExtensionAndExtensionMemberConflict',
            );
            _sink.withIndent(() {
              _elementPrinter.writeElementList2(
                'nonExtension',
                conflict.nonExtension,
              );
              _elementPrinter.writeElementList2(
                'extension',
                conflict.extension,
              );
            });
          case NotUniqueExtensionMemberConflict _:
            _elementPrinter.writeElementList2(
              'NotUniqueExtensionMemberConflict',
              conflict.candidates,
            );
          default:
            fail('Not implemented: ${conflict.runtimeType}');
        }
      }
    });
  }

  void _writeListOfMaps(
    String name,
    List<Map<Name, ExecutableElement>> listOfMaps,
  ) {
    if (listOfMaps.isEmpty) return;

    _sink.writelnWithIndent(name);
    _sink.withIndent(() {
      listOfMaps.forEachIndexed((index, map) {
        _writeNameToMap('$index', map);
      });
    });
  }

  void _writeNameToListMap(
    String name,
    Map<Name, List<ExecutableElement>> map,
  ) {
    var isEmpty = map.values.flattenedToList.where((element) {
      if (_configuration.withObjectMembers) return true;
      return !element.isObjectMember;
    }).isEmpty;
    if (isEmpty) return;

    _sink.writelnWithIndent(name);
    _sink.withIndent(() {
      for (var entry in _sortedEntries(map.entries)) {
        var name = _nameObjStr(entry.key);
        var elements = _withoutObject(entry.value);
        _elementPrinter.writeElementList2(name, elements);
      }
    });
  }

  void _writeNameToMap(String name, Map<Name, ExecutableElement> map) {
    var isEmpty = map.values.none(_shouldWrite);
    if (isEmpty) return;

    _sink.writelnWithIndent(name);
    _sink.withIndent(() {
      for (var entry in _sortedEntries(map.entries)) {
        var name = _nameObjStr(entry.key);
        var element = entry.value;
        if (_shouldWrite(element)) {
          _elementPrinter.writeNamedElement2(name, element);
        }
      }
    });
  }
}
