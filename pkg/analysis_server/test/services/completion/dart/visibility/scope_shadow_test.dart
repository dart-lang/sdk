// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionScopeTest);
  });
}

@reflectiveTest
class CompletionScopeTest extends AbstractCompletionDriverTest {
  static const _fooThis = {'foo', 'this'};
  static const _fooThisC = {..._fooThis, 'C'};
  static const _callThisNullable = {'call', 'this', 'this?'};

  @override
  bool get includeKeywords => false;

  Future<void> test_enumConstant() async {
    allowedIdentifiers = const {..._fooThis, 'E'};
    await computeSuggestions('''
enum E {
  foo;

  void f(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  E
    kind: enum
  E.foo
    kind: enumConstant
''');
  }

  Future<void> test_extensionMember_parameter() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  void bar(int foo) {
    ^
  }
}
extension E on C {
  String get foo => '';
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  this.foo
    kind: getter
''');
  }

  /// The `call` method of the extended type is reached with `this?.call`,
  /// because the extended type is nullable. The extension's own getter owns
  /// both the unqualified name (taken here by the parameter) and the `this.`
  /// form.
  Future<void> test_extensionMember_parameter_onFunction() async {
    allowedIdentifiers = _callThisNullable;
    await computeSuggestions('''
extension E on Function? {
  String get call => '';
  void bar(int call) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  call
    kind: parameter
  this.call
    kind: getter
  this?.call
    kind: methodInvocation
''');
  }

  /// The same as [test_extensionMember_parameter_onFunction], but for an
  /// extension on a function type rather than on the class `Function`.
  Future<void> test_extensionMember_parameter_onFunctionType() async {
    allowedIdentifiers = _callThisNullable;
    await computeSuggestions('''
extension E on void Function()? {
  String get call => '';
  void bar(int call) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  call
    kind: parameter
  this.call
    kind: getter
  this?.call
    kind: methodInvocation
''');
  }

  /// The fields of the extended record type are reached with `this?.`, because
  /// the extended type is nullable. The extension's own getters of the same
  /// names own both the unqualified names (taken here by the parameters) and
  /// the `this.` form.
  Future<void> test_extensionMember_parameter_onRecordType() async {
    allowedIdentifiers = const {r'$1', 'named', 'this', 'this?'};
    await computeSuggestions(r'''
extension E on (int, {String named})? {
  String get $1 => '';
  String get named => '';
  void bar(int named, int $1) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  named
    kind: parameter
  $1
    kind: parameter
  this.named
    kind: getter
  this.$1
    kind: getter
  this?.$1
    kind: identifier
  this?.named
    kind: identifier
''');
  }

  /// `this.foo` always resolves to the instance member `C.foo`, never to the
  /// extension getter `E.foo`, because instance members take priority over
  /// extension members. The extension getter must not be suggested with a
  /// `this.` prefix, since accepting that suggestion would insert code that
  /// resolves to a different element (and a different type) than the one
  /// being suggested.
  Future<void> test_extensionMemberShadowedByInstanceMember() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  int foo = 0;
  void bar() {
    ^
  }
}
extension E on C {
  String get foo => '';
}
''');
    assertResponse('''
suggestions
  foo
    kind: field
''');
  }

  /// Inside the body of an extension, the extension's own method is a regular
  /// member of the current scope and is not shadowed by anything, so it must
  /// be suggested exactly once, without a `this.` prefix.
  Future<void> test_insideExtensionBody_ownMethodNotDuplicated() async {
    allowedIdentifiers = const {'foo', 'bar', 'this'};
    await computeSuggestions('''
class C {
  int foo = 0;
}
extension E on C {
  void bar() {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: field
  bar
    kind: methodInvocation
''');
  }

  Future<void> test_instanceMember_extensionOnNullable() async {
    allowedIdentifiers = const {'foo', 'this', 'this?'};
    await computeSuggestions('''
class C {
  int foo = 0;
}
extension E on C? {
  int get foo => 0;
  void bar(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  this?.foo
    kind: field
  this.foo
    kind: getter
''');
  }

  Future<void> test_instanceMember_parameter_noExtensionMember() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  int foo = 0;
}
extension E on C {
  String get foo => '';
  void bar(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  this.foo
    kind: field
''');
  }

  Future<void> test_instanceMemberShadowedByExtensionMember() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  int foo = 0;
}
extension E on C {
  String get foo => '';
  void bar() {
    ^
  }
}
''');
    assertResponse('''
suggestions
  this.foo
    kind: field
  foo
    kind: getter
''');
  }

  Future<void> test_instanceMemberShadowedByTopLevelDeclaration() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
String get foo => '';
class C {
  int foo = 0;
}
class D extends C {
  void bar() {
    ^
  }
}
''');
    assertResponse('''
suggestions
  this.foo
    kind: field
  foo
    kind: getter
''');
  }

  /// The name of a field in an initializer list is never written with a `this.`
  /// prefix, even when a parameter of the constructor shadows the field.
  Future<void> test_parameter_fieldInInitializerList() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  int foo;
  C(int foo) : ^;
}
''');
    assertResponse('''
suggestions
  foo
    kind: field
''');
  }

  Future<void> test_parameter_instanceField() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C(var int foo) {
  void bar(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  this.foo
    kind: field
''');
  }

  Future<void> test_parameter_instanceField_assignment() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  int foo = 0;
  void bar(int foo) {
    ^ = 0;
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  this.foo
    kind: field
''');
  }

  Future<void> test_parameter_instanceGetter() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  int get foo => 0;
  void bar(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  this.foo
    kind: getter
''');
  }

  Future<void> test_parameter_instanceMethod() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  void foo() {}
  void bar(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  this.foo
    kind: methodInvocation
''');
  }

  Future<void> test_parameter_instanceSetter() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  set foo(int value) {}
  void bar(int foo) {
    ^ = 0;
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  this.foo
    kind: setter
''');
  }

  Future<void> test_parameter_method_constructor() async {
    allowedIdentifiers = _fooThisC;
    await computeSuggestions('''
class C {
  C.foo();
  void foo(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  C
    kind: class
  this.foo
    kind: methodInvocation
  C.foo
    kind: constructorInvocation
''');
  }

  Future<void> test_parameter_propertyAccess() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C(var int foo) {
  void bar(int foo) {
    C().^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: field
''');
  }

  Future<void> test_parameter_staticField() async {
    allowedIdentifiers = _fooThisC;
    await computeSuggestions('''
class C {
  static int foo = 0;
  void bar(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  C.foo
    kind: field
  C
    kind: class
  C
    kind: constructorInvocation
''');
  }

  Future<void> test_parameter_staticGetter() async {
    allowedIdentifiers = _fooThisC;
    await computeSuggestions('''
class C {
  static int get foo => 0;
  void bar(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  C.foo
    kind: getter
  C
    kind: class
  C
    kind: constructorInvocation
''');
  }

  Future<void> test_parameter_staticMethod() async {
    allowedIdentifiers = _fooThisC;
    await computeSuggestions('''
class C {
  static void foo() {}
  void bar(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  C
    kind: class
  C.foo
    kind: methodInvocation
  C
    kind: constructorInvocation
''');
  }

  Future<void> test_parameter_staticSetter() async {
    allowedIdentifiers = _fooThisC;
    await computeSuggestions('''
class C {
  static set foo(int value) {}
  void bar(int foo) {
    ^ = 0;
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  C.foo
    kind: setter
  C
    kind: class
  C
    kind: constructorInvocation
''');
  }

  Future<void> test_superMember() async {
    allowedIdentifiers = _fooThis;
    await computeSuggestions('''
class C {
  int foo = 0;
}
class D extends C {
  void bar(int foo) {
    ^
  }
}
''');
    assertResponse('''
suggestions
  foo
    kind: parameter
  this.foo
    kind: field
''');
  }
}
