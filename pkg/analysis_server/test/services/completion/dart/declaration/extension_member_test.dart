// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMemberTest1);
    defineReflectiveTests(ExtensionMemberTest2);
  });
}

@reflectiveTest
class ExtensionMemberTest1 extends AbstractCompletionDriverTest
    with ExtensionMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ExtensionMemberTest2 extends AbstractCompletionDriverTest
    with ExtensionMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ExtensionMemberTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_extensionOverride_doesNotMatch_partial() async {
    await computeSuggestions('''
extension E on int {
  bool a0(int b0, int c0) {}
  int get b0 => 0;
  set c0(int d) {}
}
void f() {
  E('3').a0^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
  b0
    kind: getter
  c0
    kind: setter
''');
    }
  }

  Future<void> test_extensionOverride_matches_partial() async {
    await computeSuggestions('''
extension E on int {
  bool a0(int b0, int c0) {}
  int get b0 => 0;
  set c0(int d) {}
}
void f() {
  E(2).a0^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
  b0
    kind: getter
  c0
    kind: setter
''');
    }
  }

  Future<void> test_inExtendedClass() async {
    await computeSuggestions('''
class Person {
  void doSomething() {
    ^
  }
}
extension E on Person {
  String get n0 => '';
  set i0(int id) {}
  void w0() { }
}
''');
    assertResponse(r'''
suggestions
  i0
    kind: setter
  n0
    kind: getter
  w0
    kind: methodInvocation
''');
  }

  Future<void> test_inExtendedClass_accessedWithThis() async {
    await computeSuggestions('''
class Person {
  void doSomething() {
    this.^
  }
}
extension E on Person {
  String get n0 => '';
  set i0(int i0) {}
  void w0() { }
}
''');
    assertResponse(r'''
suggestions
  i0
    kind: setter
  n0
    kind: getter
  w0
    kind: methodInvocation
''');
  }

  Future<void> test_inExtendedClass_multipleExtensions() async {
    await computeSuggestions('''
class Person {
  void doSomething() {
    ^
  }
}
extension on Person {
  String get n0 => '';
}

extension on Person {
  void w0() { }
}

''');
    assertResponse(r'''
suggestions
  n0
    kind: getter
  w0
    kind: methodInvocation
''');
  }

  Future<void> test_inExtension_field() async {
    await computeSuggestions('''
class A {
  int a0 = 0;
}
class B extends A {
  int b0 = 0;
}
extension E on B {
  void e() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_inExtension_getterAndSetter() async {
    await computeSuggestions('''
class A {
  int get a0 => 0;
}
class B extends A {
  set b0(int b0) { }
}
extension E on B {
  void e() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: getter
  b0
    kind: setter
''');
  }

  Future<void> test_inExtension_method() async {
    await computeSuggestions('''
class A {
  void a0() { }
}
class B extends A {
  void b0() { }
}
extension E on B {
  void e() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: methodInvocation
  b0
    kind: methodInvocation
''');
  }

  Future<void> test_inExtension_methodWithParamType() async {
    printerConfiguration.withReturnType = true;
    await computeSuggestions('''
class A<T> {
  T a0() => null;
}

extension E on A<int> {
  void e() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: methodInvocation
    returnType: int
''');
  }

  Future<void> test_inMixinOnExtendedType() async {
    await computeSuggestions('''
class Person { }
extension E on Person {
  void w0() { }
}

mixin M on Person {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  w0
    kind: methodInvocation
''');
  }

  Future<void> test_instanceMemberAccess() async {
    await computeSuggestions('''
extension E on dynamic {
  void e0() {}
}
void f(String s) {
  s.^;
}
''');
    assertResponse(r'''
suggestions
  e0
    kind: methodInvocation
''');
  }

  Future<void>
      test_propertyAccess_afterFunctionInvocation_doesNotMatch_partial() async {
    await computeSuggestions('''
extension E<T extends num> on List<T> {
  bool a0(int b0, int c0) {}
  int get b0 => 0;
  set c0(int d) {}
}
List<T> g<T>(T x) => [x];
void f(String s) {
  g(s).a0^
}
''');
    // The purpose of this test is to verify that nothing is suggested when the
    // extended type doesn't match.
    assertResponse(r'''
replacement
  left: 2
suggestions
''');
  }

  Future<void>
      test_propertyAccess_afterIdentifier_doesNotMatch_partial() async {
    await computeSuggestions('''
extension E<T extends num> on List<T> {
  bool a0(int b0, int c0) {}
  int get b0 => 0;
  set c0(int d) {}
}
void f(List<String> l) {
  l.a0^
}
''');
    // The purpose of this test is to verify that nothing is suggested when the
    // extended type doesn't match.
    assertResponse(r'''
replacement
  left: 2
suggestions
''');
  }

  Future<void> test_propertyAccess_afterIdentifier_matches_partial() async {
    await computeSuggestions('''
extension E<T extends num> on List<T> {
  bool a0(int b0, int c0) {}
  int get b0 => 0;
  set c0(int d) {}
}
void f(List<int> l) {
  l.a0^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
  b0
    kind: getter
  c0
    kind: setter
''');
    }
  }

  Future<void> test_propertyAccess_afterLiteral_doesNotMatch() async {
    await computeSuggestions('''
extension E on String {
  bool a0(int b0, int c0) {}
  int get b0 => 0;
  set c0(int d) {}
}

void f() {
  0.^
}
''');
    // The purpose of this test is to assert that none of the extension methods
    // are suggested.
    assertResponse(r'''
suggestions
''');
  }

  Future<void>
      test_propertyAccess_afterLiteral_doesNotMatch_generic_partial() async {
    await computeSuggestions('''
extension E<T extends num> on List<T> {
  bool a0(int b0, int c0) {}
  int get b0 => 0;
  set c0(int d) {}
}
void f() {
  ['a'].a0^
}
''');
    // The purpose of this test is to assert that none of the extension methods
    // are suggested.
    assertResponse(r'''
replacement
  left: 2
suggestions
''');
  }

  Future<void> test_propertyAccess_afterLiteral_matches_partial() async {
    await computeSuggestions('''
extension E on int {
  bool a0(int b0, int c0) {}
  int get b0 => 0;
  set c0(int d) {}
}
void f() {
  2.a0^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
  b0
    kind: getter
  c0
    kind: setter
''');
    }
  }

  Future<void> test_propertyAccess_matches_partial() async {
    await computeSuggestions('''
extension E on int {
  bool a0(int b0, int c0) {}
  int get b0 => 0;
  set c0(int d) {}
}
void f() {
  g().a0^
}
int g() => 3;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
  b0
    kind: getter
  c0
    kind: setter
''');
    }
  }

  Future<void> test_staticMemberAccess_none_partial() async {
    await computeSuggestions('''
extension E on int {
  void a0() {}
}
void f() {
  E.a^
}
''');
    // The purpose of this test is to verify that there are no suggestions when
    // there are no static members to suggest.
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }
}
