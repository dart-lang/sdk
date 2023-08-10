// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_printer.dart';
import '../../../util/tree_string_sink.dart';
import '../../summary/elements_base.dart';
import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InheritanceManager3Test);
    defineReflectiveTests(InheritanceManager3WithoutNullSafetyTest);
    defineReflectiveTests(InheritanceManager3Test_ExtensionType);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InheritanceManager3Test extends _InheritanceManager3Base {
  test_getInheritedMap_topMerge_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.6
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
A.foo: void Function({int a})
''');
  }

  test_getMember_fromGenericClass_method_returnType() async {
    await resolveTestCode('''
abstract class B<E> {
  T foo<T>();
}
''');
    final B = findElement.classOrMixin('B');
    final foo = manager.getMember2(B, Name(null, 'foo'))!;
    final T = foo.typeParameters.single;
    final returnType = foo.returnType;
    expect(returnType.element, same(T));
  }

  test_getMember_fromGenericSuper_method_bound() async {
    void checkTextendsFooT(TypeParameterElement t) {
      final otherT = (t.bound as InterfaceType).typeArguments.single.element;
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
    final XB = findElement.typeParameter('XB');
    final typeXB = XB.instantiate(nullabilitySuffix: NullabilitySuffix.none);
    final B = findElement.classOrMixin('B');
    final typeB = B.instantiate(
        typeArguments: [typeXB], nullabilitySuffix: NullabilitySuffix.none);
    final foo = manager.getMember(typeB, Name(null, 'foo'))!;
    final foo2 = manager.getMember2(B, Name(null, 'foo'))!;
    checkTextendsFooT(foo.type.typeFormals.single);
    checkTextendsFooT(foo2.type.typeFormals.single);
    checkTextendsFooT(foo2.typeParameters.single);
    checkTextendsFooT(foo.typeParameters.single);
  }

  test_getMember_fromGenericSuper_method_bound2() async {
    void checkTextendsFooT(TypeParameterElement t) {
      final otherT = (t.bound as InterfaceType).typeArguments.single.element;
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
    final XD = findElement.typeParameter('XD');
    final typeXD = XD.instantiate(nullabilitySuffix: NullabilitySuffix.none);
    final D = findElement.classOrMixin('D');
    final typeD = D.instantiate(
        typeArguments: [typeXD], nullabilitySuffix: NullabilitySuffix.none);
    final foo = manager.getMember(typeD, Name(null, 'foo'))!;
    final foo2 = manager.getMember2(D, Name(null, 'foo'))!;
    checkTextendsFooT(foo.type.typeFormals.single);
    checkTextendsFooT(foo2.type.typeFormals.single);
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
    final B = findElement.classOrMixin('B');
    final foo = manager.getMember2(B, Name(null, 'foo'))!;
    final T = foo.typeParameters.single;
    final returnType = foo.returnType;
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
    final B = findElement.classOrMixin('B');
    final foo = manager.getMember2(B, Name(null, 'foo'))!;
    final T = foo.typeParameters.single;
    final returnType = foo.returnType;
    expect(returnType.element, same(T));
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

  test_getMember_optIn_inheritsOptOut() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.6
class A {
  int foo(int a, int b) => 0;
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
      expected: 'A.foo: int* Function(int*, int*)*',
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

  test_getMember_optIn_topMerge_method() async {
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

  test_getMember_optOut_inheritsOptIn() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await resolveTestCode('''
// @dart = 2.6
import 'a.dart';
class B extends A {
  int bar(int a) => 0;
}
''');
    _assertGetMember2(
      className: 'B',
      name: 'foo',
      expected: 'A.foo: int* Function(int*, int*)*',
    );

    _assertGetMember2(
      className: 'B',
      name: 'bar',
      expected: 'B.bar: int* Function(int*)*',
    );
  }

  test_getMember_optOut_mixesOptIn() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await resolveTestCode('''
// @dart = 2.6
import 'a.dart';
class B with A {
  int bar(int a) => 0;
}
''');
    _assertGetMember2(
      className: 'B',
      name: 'foo',
      expected: 'A.foo: int* Function(int*, int*)*',
    );
    _assertGetMember2(
      className: 'B',
      name: 'bar',
      expected: 'B.bar: int* Function(int*)*',
    );
  }

  test_getMember_optOut_passOptIn() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
// @dart = 2.6
import 'a.dart';
class B extends A {
  int bar(int a) => 0;
}
''');
    await resolveTestCode('''
import 'b.dart';
class C extends B {}
''');
    _assertGetMember(
      className: 'C',
      name: 'foo',
      expected: 'A.foo: int* Function(int*, int*)*',
    );
    _assertGetMember(
      className: 'C',
      name: 'bar',
      expected: 'B.bar: int* Function(int*)*',
    );
  }
}

@reflectiveTest
class InheritanceManager3Test_ExtensionType extends ElementsBaseTest {
  final printerConfiguration = _InstancePrinterConfiguration();

  @override
  bool get keepLinkingLibraries => true;

  void assertInterfaceText(InterfaceElementImpl element, String expected) {
    final actual = _interfaceText(element);
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  @override
  void setUp() {
    super.setUp();
    printerConfiguration.withoutIdenticalImplemented = true;
  }

  test_declareGetter() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}
''');

    final element = library.extensionType('A');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::A::@getter::foo
  it: self::@extensionType::A::@getter::it
declared
  foo: self::@extensionType::A::@getter::foo
  it: self::@extensionType::A::@getter::it
''');
  }

  test_declareGetter_static() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  static int get foo => 0;
}
''');

    final element = library.extensionType('A');
    assertInterfaceText(element, r'''
map
  it: self::@extensionType::A::@getter::it
declared
  it: self::@extensionType::A::@getter::it
''');
  }

  test_declareMethod() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}
''');

    final element = library.extensionType('A');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::A::@method::foo
  it: self::@extensionType::A::@getter::it
declared
  foo: self::@extensionType::A::@method::foo
  it: self::@extensionType::A::@getter::it
''');
  }

  test_declareMethod_implementClass_implementExtensionType_wouldConflict() async {
    final library = await buildLibrary(r'''
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

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
declared
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    self::@extensionType::B::@method::foo
    self::@class::A::@method::foo
  it
    self::@extensionType::B::@getter::it
''');
  }

  test_declareMethod_implementClass_method2_wouldConflict() async {
    final library = await buildLibrary(r'''
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

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
declared
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    self::@class::A::@method::foo
    self::@class::B::@method::foo
''');
  }

  test_declareMethod_implementClass_noOverride() async {
    final library = await buildLibrary(r'''
class A {}

class B extends A {
  void foo() {}
}

extension type C(B it) implements A {
  void foo() {}
}
''');

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
declared
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
''');
  }

  test_declareMethod_implementClass_override() async {
    final library = await buildLibrary(r'''
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

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
declared
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    self::@class::A::@method::foo
''');
  }

  test_declareMethod_implementClass_override_getter() async {
    final library = await buildLibrary(r'''
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

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
declared
  foo: self::@extensionType::C::@method::foo
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    self::@class::A::@getter::foo
''');
  }

  test_declareMethod_implementExtensionType_method2_wouldConflict() async {
    final library = await buildLibrary(r'''
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

    final element = library.extensionType('B');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::B::@method::foo
  it: self::@extensionType::B::@getter::it
declared
  foo: self::@extensionType::B::@method::foo
  it: self::@extensionType::B::@getter::it
redeclared
  foo
    self::@extensionType::A1::@method::foo
    self::@extensionType::A2::@method::foo
  it
    self::@extensionType::A1::@getter::it
    self::@extensionType::A2::@getter::it
''');
  }

  test_declareMethod_implementExtensionType_override() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  void foo() {}
}
''');

    final element = library.extensionType('B');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::B::@method::foo
  it: self::@extensionType::B::@getter::it
declared
  foo: self::@extensionType::B::@method::foo
  it: self::@extensionType::B::@getter::it
redeclared
  foo
    self::@extensionType::A::@method::foo
  it
    self::@extensionType::A::@getter::it
''');
  }

  test_declareMethod_implementExtensionType_override_getter() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  void foo() {}
}
''');

    final element = library.extensionType('B');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::B::@method::foo
  it: self::@extensionType::B::@getter::it
declared
  foo: self::@extensionType::B::@method::foo
  it: self::@extensionType::B::@getter::it
redeclared
  foo
    self::@extensionType::A::@getter::foo
  it
    self::@extensionType::A::@getter::it
''');
  }

  test_declareMethod_static() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  static void foo() {}
}
''');

    final element = library.extensionType('A');
    assertInterfaceText(element, r'''
map
  it: self::@extensionType::A::@getter::it
declared
  it: self::@extensionType::A::@getter::it
''');
  }

  test_declareSetter() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  set foo(int _) {}
}
''');

    final element = library.extensionType('A');
    assertInterfaceText(element, r'''
map
  foo=: self::@extensionType::A::@setter::foo
  it: self::@extensionType::A::@getter::it
declared
  foo=: self::@extensionType::A::@setter::foo
  it: self::@extensionType::A::@getter::it
''');
  }

  test_declareSetter_static() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  static set foo(int _) {}
}
''');

    final element = library.extensionType('A');
    assertInterfaceText(element, r'''
map
  it: self::@extensionType::A::@getter::it
declared
  it: self::@extensionType::A::@getter::it
''');
  }

  test_noDeclaration_implementClass_generic_method() async {
    final library = await buildLibrary(r'''
class A<T> {
  void foo(T a) {}
}

class B extends A<int> {}

extension type C(B it) implements A<int> {}
''');

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo: MethodMember
    base: self::@class::A::@method::foo
    substitution: {T: int}
  it: self::@extensionType::C::@getter::it
declared
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    MethodMember
      base: self::@class::A::@method::foo
      substitution: {T: int}
''');
  }

  test_noDeclaration_implementClass_implementExtensionType_hasConflict() async {
    final library = await buildLibrary(r'''
class A {
  void foo() {}
}

extension type B(A it) {
  void foo() {}
}

extension type C(A it) implements A, B {}
''');

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  it: self::@extensionType::C::@getter::it
declared
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    self::@extensionType::B::@method::foo
    self::@class::A::@method::foo
  it
    self::@extensionType::B::@getter::it
conflicts
  HasExtensionAndNotExtensionMemberConflict
    nonExtension
      self::@class::A::@method::foo
    extension
      self::@extensionType::B::@method::foo
''');
  }

  test_noDeclaration_implementClass_method() async {
    final library = await buildLibrary(r'''
class A {
  void foo() {}
}

class B extends A {}

extension type C(B it) implements A {}
''');

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo: self::@class::A::@method::foo
  it: self::@extensionType::C::@getter::it
declared
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    self::@class::A::@method::foo
''');
  }

  test_noDeclaration_implementClass_method2_hasConflict() async {
    final library = await buildLibrary(r'''
class A {
  int foo() => 0;
}

class B {
  String foo() => '0';
}

extension type C(Object it) implements A, B {}
''');

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  it: self::@extensionType::C::@getter::it
declared
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    self::@class::A::@method::foo
    self::@class::B::@method::foo
conflicts
  CandidatesConflict
    self::@class::A::@method::foo
    self::@class::B::@method::foo
''');
  }

  test_noDeclaration_implementClass_method2_noConflict() async {
    final library = await buildLibrary(r'''
class A {
  int foo() => 0;
}

class B {
  num foo() => 0;
}

extension type C(Object it) implements A, B {}
''');

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo: self::@class::A::@method::foo
  it: self::@extensionType::C::@getter::it
declared
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    self::@class::A::@method::foo
    self::@class::B::@method::foo
''');
  }

  test_noDeclaration_implementClass_method2_noConflict2() async {
    final library = await buildLibrary(r'''
class A {
  int foo() => 0;
}

class B1 extends A {}

class B2 extends A {}

abstract class C implements B1, B2 {}

extension type D(C it) implements B1, B2 {}
''');

    final element = library.extensionType('D');
    assertInterfaceText(element, r'''
map
  foo: self::@class::A::@method::foo
  it: self::@extensionType::D::@getter::it
declared
  it: self::@extensionType::D::@getter::it
redeclared
  foo
    self::@class::A::@method::foo
''');
  }

  test_noDeclaration_implementClass_setter() async {
    final library = await buildLibrary(r'''
class A {
  set foo(int _) {}
}

class B extends A {}

extension type C(B it) implements A {}
''');

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo=: self::@class::A::@setter::foo
  it: self::@extensionType::C::@getter::it
declared
  it: self::@extensionType::C::@getter::it
redeclared
  foo=
    self::@class::A::@setter::foo
''');
  }

  test_noDeclaration_implementExtensionType_generic_method() async {
    final library = await buildLibrary(r'''
extension type A<T>(T it) {
  void foo(T a) {}
}

extension type B(int it) implements A<int> {}
''');

    final element = library.extensionType('B');
    assertInterfaceText(element, r'''
map
  foo: MethodMember
    base: self::@extensionType::A::@method::foo
    substitution: {T: int}
  it: self::@extensionType::B::@getter::it
declared
  it: self::@extensionType::B::@getter::it
redeclared
  foo
    MethodMember
      base: self::@extensionType::A::@method::foo
      substitution: {T: int}
  it
    PropertyAccessorMember
      base: self::@extensionType::A::@getter::it
      substitution: {T: int}
''');
  }

  test_noDeclaration_implementExtensionType_method() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {}
''');

    final element = library.extensionType('B');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::A::@method::foo
  it: self::@extensionType::B::@getter::it
declared
  it: self::@extensionType::B::@getter::it
redeclared
  foo
    self::@extensionType::A::@method::foo
  it
    self::@extensionType::A::@getter::it
''');
  }

  test_noDeclaration_implementExtensionType_method2_hasConflict() async {
    final library = await buildLibrary(r'''
extension type A1(int it) {
  void foo() {}
}

extension type A2(int it) {
  void foo() {}
}

extension type B(int it) implements A1, A2 {}
''');

    final element = library.extensionType('B');
    assertInterfaceText(element, r'''
map
  it: self::@extensionType::B::@getter::it
declared
  it: self::@extensionType::B::@getter::it
redeclared
  foo
    self::@extensionType::A1::@method::foo
    self::@extensionType::A2::@method::foo
  it
    self::@extensionType::A1::@getter::it
    self::@extensionType::A2::@getter::it
conflicts
  NotUniqueExtensionMemberConflict
    self::@extensionType::A1::@method::foo
    self::@extensionType::A2::@method::foo
''');
  }

  test_noDeclaration_implementExtensionType_method2_noConflict() async {
    final library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

extension type B1(int it) implements A {}

extension type B2(int it) implements A {}

extension type C(int it) implements B1, B2 {}
''');

    final element = library.extensionType('C');
    assertInterfaceText(element, r'''
map
  foo: self::@extensionType::A::@method::foo
  it: self::@extensionType::C::@getter::it
declared
  it: self::@extensionType::C::@getter::it
redeclared
  foo
    self::@extensionType::A::@method::foo
  it
    self::@extensionType::B1::@getter::it
    self::@extensionType::B2::@getter::it
''');
  }

  test_withObjectMembers() async {
    final library = await buildLibrary(r'''
extension type A(int it) {}
''');

    final element = library.extensionType('A');
    printerConfiguration.withObjectMembers = true;
    assertInterfaceText(element, r'''
map
  ==: dart:core::@class::Object::@method::==
  hashCode: dart:core::@class::Object::@getter::hashCode
  it: self::@extensionType::A::@getter::it
  noSuchMethod: dart:core::@class::Object::@method::noSuchMethod
  runtimeType: dart:core::@class::Object::@getter::runtimeType
  toString: dart:core::@class::Object::@method::toString
declared
  it: self::@extensionType::A::@getter::it
redeclared
  ==
    dart:core::@class::Object::@method::==
  hashCode
    dart:core::@class::Object::@getter::hashCode
  noSuchMethod
    dart:core::@class::Object::@method::noSuchMethod
  runtimeType
    dart:core::@class::Object::@getter::runtimeType
  toString
    dart:core::@class::Object::@method::toString
''');
  }

  String _interfaceText(InterfaceElementImpl element) {
    final library = element.library;
    final inheritance = library.session.inheritanceManager;
    final interface = inheritance.getInterface(element);

    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );
    final elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
      selfUriStr: '${library.source.uri}',
    );

    _InterfacePrinter(
      sink: sink,
      elementPrinter: elementPrinter,
      configuration: printerConfiguration,
    ).write(interface);

    return buffer.toString();
  }
}

@reflectiveTest
class InheritanceManager3WithoutNullSafetyTest
    extends _InheritanceManager3Base {
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
    _assertGetMember(
      className: 'A',
      name: 'foo',
      concrete: true,
    );
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
    _assertGetMember(
      className: 'A',
      name: 'foo',
      concrete: true,
    );
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
    _assertGetMember(
      className: 'B',
      name: 'foo',
      concrete: true,
    );
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

  test_getMember_method_covariantByDeclaration_inherited() async {
    await resolveTestCode('''
abstract class A {
  void foo(covariant num a);
}

abstract class B extends A {
  void foo(int a);
}
''');
    var member = manager.getMember2(
      findElement.classOrMixin('B'),
      Name(null, 'foo'),
    )!;
    // TODO(scheglov) It would be nice to use `_assertGetMember`.
    // But we need a way to check covariance.
    // Maybe check the element display string, not the type.
    expect(member.parameters[0].isCovariant, isTrue);
  }

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
    var member = manager.getMember2(
      findElement.classOrMixin('C'),
      Name(null, 'foo'),
      concrete: true,
    )!;
    // TODO(scheglov) It would be nice to use `_assertGetMember`.
    expect(member.declaration, same(findElement.method('foo', of: 'B')));
    expect(member.parameters[0].isCovariant, isTrue);
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
    var member = manager.getMember2(
      findElement.classOrMixin('B'),
      Name(null, 'foo='),
    )!;
    // TODO(scheglov) It would be nice to use `_assertGetMember`.
    // But we need a way to check covariance.
    // Maybe check the element display string, not the type.
    expect(member.parameters[0].isCovariant, isTrue);
  }

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
    var member = manager.getMember2(
      findElement.classOrMixin('C'),
      Name(null, 'foo='),
      concrete: true,
    )!;
    // TODO(scheglov) It would be nice to use `_assertGetMember`.
    expect(member.declaration, same(findElement.setter('foo', of: 'B')));
    expect(member.parameters[0].isCovariant, isTrue);
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
    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
    );
  }

  test_getMember_super_forMixin_interface() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

mixin M implements A {}
''');
    _assertGetMember(
      className: 'M',
      name: 'foo',
      forSuper: true,
    );
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
    var member = manager.getMember2(
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
    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
    );
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

      var actual = '${enclosingElement.name}.${element.name}: $typeStr';
      expect(actual, expected);

      if (element is PropertyAccessorElement) {
        var variable = element.variable;
        expect(variable.enclosingElement, same(element.enclosingElement));
        expect(variable.name, element.displayName);
        if (element.isGetter) {
          expect(variable.type, element.returnType);
        } else {
          expect(variable.type, element.parameters[0].type);
        }
      }
    } else {
      expect(element, isNull);
    }
  }

  void _assertGetInherited({
    required String className,
    required String name,
    String? expected,
  }) {
    var member = manager.getInherited2(
      findElement.classOrMixin(className),
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
    var member = manager.getMember2(
      findElement.classOrMixin(className),
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
    _assertGetMember(
      className: className,
      name: name,
      expected: expected,
      concrete: false,
    );

    _assertGetMember(
      className: className,
      name: name,
      expected: expected,
      concrete: true,
    );
  }

  void _assertInheritedConcreteMap(String className, String expected) {
    var element = findElement.classOrMixin(className);
    var map = manager.getInheritedConcreteMap2(element);
    _assertNameToExecutableMap(map, expected);
  }

  void _assertInheritedMap(String className, String expected) {
    var element = findElement.classOrMixin(className);
    var map = manager.getInheritedMap2(element);
    _assertNameToExecutableMap(map, expected);
  }

  void _assertNameToExecutableMap(
      Map<Name, ExecutableElement> map, String expected) {
    var lines = <String>[];
    for (var entry in map.entries) {
      var element = entry.value;
      var type = element.type;

      var enclosingElement = element.enclosingElement;
      if (enclosingElement.name == 'Object') continue;

      var typeStr = type.getDisplayString(withNullability: false);
      lines.add('${enclosingElement.name}.${element.name}: $typeStr');
    }

    lines.sort();
    var actual = lines.isNotEmpty ? '${lines.join('\n')}\n' : '';

    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
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
  })  : _sink = sink,
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
    return entries.sortedBy(
      (e) => '${e.key.name} ${e.key.libraryUri}',
    );
  }

  List<ExecutableElement> _withoutObject(List<ExecutableElement> elements) {
    return elements.where(_shouldWrite).toList();
  }

  void _writeConflicts(List<Conflict> conflicts) {
    if (conflicts.isEmpty) return;

    _sink.writelnWithIndent('conflicts');
    _sink.withIndent(() {
      for (final conflict in conflicts) {
        switch (conflict) {
          case CandidatesConflict _:
            _elementPrinter.writeElementList(
              'CandidatesConflict',
              conflict.candidates,
            );
          case HasNonExtensionAndExtensionMemberConflict _:
            _sink.writelnWithIndent(
              'HasExtensionAndNotExtensionMemberConflict',
            );
            _sink.withIndent(() {
              _elementPrinter.writeElementList(
                'nonExtension',
                conflict.nonExtension,
              );
              _elementPrinter.writeElementList(
                'extension',
                conflict.extension,
              );
            });
          case NotUniqueExtensionMemberConflict _:
            _elementPrinter.writeElementList(
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
    final isEmpty = map.values.expand((elements) => elements).where((element) {
      if (_configuration.withObjectMembers) return true;
      return !element.isObjectMember;
    }).isEmpty;
    if (isEmpty) return;

    _sink.writelnWithIndent(name);
    _sink.withIndent(() {
      for (final entry in _sortedEntries(map.entries)) {
        final name = _nameObjStr(entry.key);
        final elements = _withoutObject(entry.value);
        _elementPrinter.writeElementList(name, elements);
      }
    });
  }

  void _writeNameToMap(String name, Map<Name, ExecutableElement> map) {
    final isEmpty = map.values.none(_shouldWrite);
    if (isEmpty) return;

    _sink.writelnWithIndent(name);
    _sink.withIndent(() {
      for (final entry in _sortedEntries(map.entries)) {
        final name = _nameObjStr(entry.key);
        final element = entry.value;
        if (_shouldWrite(element)) {
          _elementPrinter.writeNamedElement(name, element);
        }
      }
    });
  }
}

extension on LibraryElementImpl {
  ExtensionTypeElementImpl extensionType(String name) {
    return topLevelElements
        .whereType<ExtensionTypeElementImpl>()
        .singleWhere((e) => e.name == name);
  }
}
