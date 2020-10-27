// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateMissingOverridesTest);
    defineReflectiveTests(CreateMissingOverridesWithNullSafetyTest);
  });
}

@reflectiveTest
class CreateMissingOverridesTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_MISSING_OVERRIDES;

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
  int ma;
  void mb() {}
  double mc;
}

class B implements A {
}
''');
    await assertHasFix('''
class A {
  int ma;
  void mb() {}
  double mc;
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

  Future<void> test_method() async {
    await resolveTestCode('''
abstract class A {
  void m1();
  int m2();
  String m3(int p1, double p2, Map<int, List<String>> p3);
  String m4(p1, p2);
  String m5(p1, [int p2 = 2, int p3, p4 = 4]);
  String m6(p1, {int p2 = 2, int p3, p4: 4});
}

class B extends A {
}
''');
    var expectedCode = '''
abstract class A {
  void m1();
  int m2();
  String m3(int p1, double p2, Map<int, List<String>> p3);
  String m4(p1, p2);
  String m5(p1, [int p2 = 2, int p3, p4 = 4]);
  String m6(p1, {int p2 = 2, int p3, p4: 4});
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

  @override
  String m3(int p1, double p2, Map<int, List<String>> p3) {
    // TODO: implement m3
    throw UnimplementedError();
  }

  @override
  String m4(p1, p2) {
    // TODO: implement m4
    throw UnimplementedError();
  }

  @override
  String m5(p1, [int p2 = 2, int p3, p4 = 4]) {
    // TODO: implement m5
    throw UnimplementedError();
  }

  @override
  String m6(p1, {int p2 = 2, int p3, p4 = 4}) {
    // TODO: implement m6
    throw UnimplementedError();
  }
}
''';
    await assertHasFix(expectedCode);
    {
      // end position should be on "m1", not on "m2", "m3", etc.
      var endPosition = change.selection;
      expect(endPosition, isNotNull);
      expect(endPosition.file, testFile);
      var endOffset = endPosition.offset;
      var endString = expectedCode.substring(endOffset, endOffset + 25);
      expect(endString, contains('m1'));
      expect(endString, isNot(contains('m2')));
      expect(endString, isNot(contains('m3')));
      expect(endString, isNot(contains('m4')));
      expect(endString, isNot(contains('m5')));
      expect(endString, isNot(contains('m6')));
    }
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
  R foo(int a) => null;
}

class B<R> extends A<R> {
  R bar(double b) => null;
}

class X implements B<bool> {
}
''');
    await assertHasFix('''
class A<R> {
  R foo(int a) => null;
}

class B<R> extends A<R> {
  R bar(double b) => null;
}

class X implements B<bool> {
  @override
  bool bar(double b) {
    // TODO: implement bar
    throw UnimplementedError();
  }

  @override
  bool foo(int a) {
    // TODO: implement foo
    throw UnimplementedError();
  }
}
''');
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

@reflectiveTest
class CreateMissingOverridesWithNullSafetyTest extends FixProcessorTest
    with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.CREATE_MISSING_OVERRIDES;

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
}
