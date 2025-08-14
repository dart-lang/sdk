// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateMissingOverridesInheritsAbstractClassTest);
    defineReflectiveTests(CreateMissingOverridesMustBeOverriddenClassTest);
  });
}

/// Tests for NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_*.
@reflectiveTest
class CreateMissingOverridesInheritsAbstractClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_MISSING_OVERRIDES;

  Future<void> test_brackets_both() async {
    await resolveTestCode('''
class A {
  void m() {};
}

class B implements A
''');
    await assertHasFix(
      '''
class A {
  void m() {};
}

class B implements A {
  @override
  void m() {
    // TODO: implement m
  }
}
''',
      errorFilter: (error) {
        return error.diagnosticCode ==
            CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberOne;
      },
    );
  }

  Future<void> test_brackets_left() async {
    await resolveTestCode('''
class A {
  void m() {};
}

class B implements A
}
''');
    await assertHasFix(
      '''
class A {
  void m() {};
}

class B implements A {
  @override
  void m() {
    // TODO: implement m
  }
}
''',
      errorFilter: (error) {
        return error.diagnosticCode ==
            CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberOne;
      },
    );
  }

  Future<void> test_brackets_right() async {
    await resolveTestCode('''
class A {
  void m() {};
}

class B implements A {
''');
    await assertHasFix(
      '''
class A {
  void m() {};
}

class B implements A {
  @override
  void m() {
    // TODO: implement m
  }
}
''',
      errorFilter: (error) {
        return error.diagnosticCode ==
            CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberOne;
      },
    );
  }

  Future<void> test_field_inEnum() async {
    await resolveTestCode('''
abstract class A {
  int get foo;
  set foo(int value);
}

enum E implements A {
  one, two;
}
''');
    await assertHasFix('''
abstract class A {
  int get foo;
  set foo(int value);
}

enum E implements A {
  one, two;

  @override
  final int foo;
}
''');
  }

  Future<void> test_field_untyped() async {
    await resolveTestCode('''
class A {
  var f;
}

class B implements A {
}
''');
    await assertHasFix('''
class A {
  var f;
}

class B implements A {
  @override
  var f;
}
''');
  }

  Future<void> test_functionTypeAlias() async {
    await resolveTestCode('''
typedef int Binary(int left, int right);

abstract class Emulator {
  void performBinary(Binary binary);
}

class MyEmulator extends Emulator {
}
''');
    await assertHasFix('''
typedef int Binary(int left, int right);

abstract class Emulator {
  void performBinary(Binary binary);
}

class MyEmulator extends Emulator {
  @override
  void performBinary(Binary binary) {
    // TODO: implement performBinary
  }
}
''');
  }

  Future<void> test_functionTypedParameter() async {
    await resolveTestCode('''
abstract class A {
  void forEach(int f(double p1, String p2));
}

class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  void forEach(int f(double p1, String p2));
}

class B extends A {
  @override
  void forEach(int Function(double p1, String p2) f) {
    // TODO: implement forEach
  }
}
''');
  }

  Future<void> test_functionTypedParameter_dynamic() async {
    await resolveTestCode('''
abstract class A {
  void m(bool test(e));
}

class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  void m(bool test(e));
}

class B extends A {
  @override
  void m(bool Function(dynamic e) test) {
    // TODO: implement m
  }
}
''');
  }

  Future<void> test_functionTypedParameter_nullable() async {
    await resolveTestCode('''
abstract class A {
  void forEach(int f(double p1, String p2)?);
}

class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  void forEach(int f(double p1, String p2)?);
}

class B extends A {
  @override
  void forEach(int Function(double p1, String p2)? f) {
    // TODO: implement forEach
  }
}
''');
  }

  Future<void> test_generics_typeArguments() async {
    await resolveTestCode('''
class Iterator<T> {
}

abstract class IterableMixin<T> {
  Iterator<T> get iterator;
}

class Test extends IterableMixin<int> {
}
''');
    await assertHasFix('''
class Iterator<T> {
}

abstract class IterableMixin<T> {
  Iterator<T> get iterator;
}

class Test extends IterableMixin<int> {
  @override
  // TODO: implement iterator
  Iterator<int> get iterator => throw UnimplementedError();
}
''');
  }

  Future<void> test_generics_typeParameters() async {
    await resolveTestCode('''
abstract class ItemProvider<T> {
  List<T> getItems();
}

class Test<V> extends ItemProvider<V> {
}
''');
    await assertHasFix('''
abstract class ItemProvider<T> {
  List<T> getItems();
}

class Test<V> extends ItemProvider<V> {
  @override
  List<V> getItems() {
    // TODO: implement getItems
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_getter() async {
    await resolveTestCode('''
abstract class A {
  get g1;
  int get g2;
}

class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  get g1;
  int get g2;
}

class B extends A {
  @override
  // TODO: implement g1
  get g1 => throw UnimplementedError();

  @override
  // TODO: implement g2
  int get g2 => throw UnimplementedError();
}
''');
  }

  Future<void> test_importPrefix() async {
    await resolveTestCode('''
import 'dart:async' as aaa;
abstract class A {
  Map<aaa.Future, List<aaa.Future>> g(aaa.Future p);
}

class B extends A {
}
''');
    await assertHasFix('''
import 'dart:async' as aaa;
abstract class A {
  Map<aaa.Future, List<aaa.Future>> g(aaa.Future p);
}

class B extends A {
  @override
  Map<aaa.Future, List<aaa.Future>> g(aaa.Future p) {
    // TODO: implement g
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_mergeToField_getterSetter() async {
    await resolveTestCode('''
class A {
  int ma = 0;
  void mb() {}
  double mc = 0.0;
}

class B implements A {
}
''');
    await assertHasFix('''
class A {
  int ma = 0;
  void mb() {}
  double mc = 0.0;
}

class B implements A {
  @override
  int ma;

  @override
  double mc;

  @override
  void mb() {
    // TODO: implement mb
  }
}
''');
  }

  Future<void> test_method_emptyClassBody() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

class B extends A {}
''');
    await assertHasFix('''
abstract class A {
  void foo();
}

class B extends A {
  @override
  void foo() {
    // TODO: implement foo
  }
}
''');
  }

  Future<void> test_method_generic() async {
    await resolveTestCode('''
class C<T> {}
class V<E> {}

abstract class A {
  E1 foo<E1, E2 extends C<int>>(V<E2> v);
}

class B implements A {
}
''');
    await assertHasFix('''
class C<T> {}
class V<E> {}

abstract class A {
  E1 foo<E1, E2 extends C<int>>(V<E2> v);
}

class B implements A {
  @override
  E1 foo<E1, E2 extends C<int>>(V<E2> v) {
    // TODO: implement foo
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_method_generic_nullable_dynamic() async {
    // https://github.com/dart-lang/sdk/issues/43535
    await resolveTestCode('''
class A {
  void doSomething(Map<String, dynamic>? m) {}
}

class B implements A {}
''');
    await assertHasFix('''
class A {
  void doSomething(Map<String, dynamic>? m) {}
}

class B implements A {
  @override
  void doSomething(Map<String, dynamic>? m) {
    // TODO: implement doSomething
  }
}
''');
  }

  Future<void> test_method_generic_nullable_Never() async {
    // https://github.com/dart-lang/sdk/issues/43535
    await resolveTestCode('''
class A {
  void doSomething(Map<String, Never>? m) {}
}

class B implements A {}
''');
    await assertHasFix('''
class A {
  void doSomething(Map<String, Never>? m) {}
}

class B implements A {
  @override
  void doSomething(Map<String, Never>? m) {
    // TODO: implement doSomething
  }
}
''');
  }

  Future<void> test_method_generic_withBounds() async {
    // https://github.com/dart-lang/sdk/issues/31199
    await resolveTestCode('''
abstract class A<K, V> {
  List<T> foo<T extends V>(K key);
}

class B<K, V> implements A<K, V> {
}
''');
    await assertHasFix('''
abstract class A<K, V> {
  List<T> foo<T extends V>(K key);
}

class B<K, V> implements A<K, V> {
  @override
  List<T> foo<T extends V>(K key) {
    // TODO: implement foo
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_method_genericClass2() async {
    await resolveTestCode('''
class A<R> {
  R? foo(int a) => null;
}

class B<R> extends A<R> {
  R? bar(double b) => null;
}

class X implements B<bool> {
}
''');
    await assertHasFix('''
class A<R> {
  R? foo(int a) => null;
}

class B<R> extends A<R> {
  R? bar(double b) => null;
}

class X implements B<bool> {
  @override
  bool? bar(double b) {
    // TODO: implement bar
    throw UnimplementedError();
  }

  @override
  bool? foo(int a) {
    // TODO: implement foo
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_method_inEnum() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

enum E implements A {
  one, two;
}
''');
    await assertHasFix('''
abstract class A {
  void foo();
}

enum E implements A {
  one, two;

  @override
  void foo() {
    // TODO: implement foo
  }
}
''');
  }

  Future<void> test_method_inEnumWithMembers() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

enum E implements A {
  one, two;

  void bar() {}
}
''');
    await assertHasFix('''
abstract class A {
  void foo();
}

enum E implements A {
  one, two;

  void bar() {}

  @override
  void foo() {
    // TODO: implement foo
  }
}
''');
  }

  Future<void> test_method_multiple() async {
    await resolveTestCode('''
abstract class A {
  void m1();
  int m2();
}

class B extends A {
}
''');
    var expectedCode = normalizeSource('''
abstract class A {
  void m1();
  int m2();
}

class B extends A {
  @override
  void m1() {
    // TODO: implement m1
  }

  @override
  int m2() {
    // TODO: implement m2
    throw UnimplementedError();
  }
}
''');
    await assertHasFix(expectedCode);

    // The selection should be on "m1", not on "m2".
    var selection = change.selection!;
    expect(selection.file, testFile.path);
    expect(
      expectedCode.substring(selection.offset),
      startsWith(
        normalizeSource('''
@override
  void m1'''),
      ),
    );
  }

  Future<void> test_method_namedParameter() async {
    await resolveTestCode('''
abstract class A {
  foo({int i});
}

class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  foo({int i});
}

class B extends A {
  @override
  foo({int i}) {
    // TODO: implement foo
    throw UnimplementedError();
  }
}
''');
    // One edit group for the parameter type. The name shouldn't have a group
    // because it isn't valid to change it.
    expect(change.linkedEditGroups, hasLength(1));
  }

  Future<void> test_method_namedParameters() async {
    await resolveTestCode('''
abstract class A {
  String m(p1, {int p2 = 2, int p3, p4 = 4});
}

class B extends A {
}
''');
    var expectedCode = normalizeSource('''
abstract class A {
  String m(p1, {int p2 = 2, int p3, p4 = 4});
}

class B extends A {
  @override
  String m(p1, {int p2 = 2, int p3, p4 = 4}) {
    // TODO: implement m
    throw UnimplementedError();
  }
}
''');
    await assertHasFix(expectedCode);

    var selection = change.selection!;
    expect(selection.file, testFile.path);
    expect(expectedCode.substring(selection.offset), startsWith('throw'));
  }

  Future<void> test_method_notEmptyClassBody() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

class B extends A {
  void bar() {}
}
''');
    await assertHasFix('''
abstract class A {
  void foo();
}

class B extends A {
  void bar() {}

  @override
  void foo() {
    // TODO: implement foo
  }
}
''');
  }

  Future<void> test_method_optionalParameters() async {
    await resolveTestCode('''
abstract class A {
  String m(p1, [int p2 = 2, int p3, p4 = 4]);
}

class B extends A {
}
''');
    var expectedCode = normalizeSource('''
abstract class A {
  String m(p1, [int p2 = 2, int p3, p4 = 4]);
}

class B extends A {
  @override
  String m(p1, [int p2 = 2, int p3, p4 = 4]) {
    // TODO: implement m
    throw UnimplementedError();
  }
}
''');
    await assertHasFix(expectedCode);

    var selection = change.selection!;
    expect(selection.file, testFile.path);
    expect(expectedCode.substring(selection.offset), startsWith('throw'));
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/43667')
  Future<void> test_method_withTypedef() async {
    // This fails because the element representing `Base.closure` has a return
    // type that has forgotten that it was declared using the typedef `Closure`.
    await resolveTestCode('''
typedef Closure = T Function<T>(T input);

abstract class Base {
  Closure closure();
}

class Concrete extends Base {}
''');
    await assertHasFix('''
typedef Closure = T Function<T>(T input);

abstract class Base {
  Closure closure();
}

class Concrete extends Base {
  @override
  Closure closure() {
    // TODO: implement closure
  }
}
''');
  }

  Future<void> test_methods_reverseOrder() async {
    await resolveTestCode('''
abstract class A {
  foo(int i);
  bar(String bar);
}

class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  foo(int i);
  bar(String bar);
}

class B extends A {
  @override
  bar(String bar) {
    // TODO: implement bar
    throw UnimplementedError();
  }

  @override
  foo(int i) {
    // TODO: implement foo
    throw UnimplementedError();
  }
}
''');
    // One edit group for the names and types of each parameter.
    expect(change.linkedEditGroups, hasLength(4));
  }

  Future<void> test_operator() async {
    await resolveTestCode('''
abstract class A {
  int operator [](int index);
  void operator []=(int index, String value);
}

class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  int operator [](int index);
  void operator []=(int index, String value);
}

class B extends A {
  @override
  int operator [](int index) {
    // TODO: implement []
    throw UnimplementedError();
  }

  @override
  void operator []=(int index, String value) {
    // TODO: implement []=
  }
}
''');
  }

  Future<void> test_setter() async {
    await resolveTestCode('''
abstract class A {
  set s1(x);
  set s2(int x);
  void set s3(String x);
}

class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  set s1(x);
  set s2(int x);
  void set s3(String x);
}

class B extends A {
  @override
  set s1(x) {
    // TODO: implement s1
  }

  @override
  set s2(int x) {
    // TODO: implement s2
  }

  @override
  set s3(String x) {
    // TODO: implement s3
  }
}
''');
  }
}

/// Tests for MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_*.
@reflectiveTest
class CreateMissingOverridesMustBeOverriddenClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_MISSING_OVERRIDES;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_field() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {
  @override
  int f;
}
''');
  }

  Future<void> test_field_overriddenWithOnlyGetter() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {
  int get f => 0;
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {
  int get f => 0;

  @override
  set f(int value) {
    // TODO: implement f
  }
}
''');
  }

  Future<void> test_method_directMixin() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

mixin M {
  @mustBeOverridden
  void m() {}
}

class A with M {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

mixin M {
  @mustBeOverridden
  void m() {}
}

class A with M {
  @override
  void m() {
    // TODO: implement m
  }
}
''');
  }

  Future<void> test_method_directSuperclass_three() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}

  @mustBeOverridden
  void n() {}

  @mustBeOverridden
  void o() {}
}

class B extends A {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}

  @mustBeOverridden
  void n() {}

  @mustBeOverridden
  void o() {}
}

class B extends A {
  @override
  void m() {
    // TODO: implement m
  }

  @override
  void n() {
    // TODO: implement n
  }

  @override
  void o() {
    // TODO: implement o
  }
}
''');
  }
}
