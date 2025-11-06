// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandInvocationTest);
  });
}

@reflectiveTest
class DotShorthandInvocationTest extends AbstractCompletionDriverTest
    with DotShorthandInvocationTestCases {}

mixin DotShorthandInvocationTestCases on AbstractCompletionDriverTest {
  Future<void> test_constructor_class_named() async {
    allowedIdentifiers = {'named'};
    await computeSuggestions('''
class C {
  C.named();
}
void f() {
  C c = .^
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_class_unnamed() async {
    allowedIdentifiers = {'new'};
    await computeSuggestions('''
class C {}
void f() {
  C c = .^
}
''');
    assertResponse(r'''
suggestions
  new
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_class_withParentheses() async {
    allowedIdentifiers = {'named'};
    await computeSuggestions('''
class C {
  C.named();
}
void f() {
  C c = .^()
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_class_withPrefix() async {
    allowedIdentifiers = {'named', 'new'};
    await computeSuggestions('''
class C {
  C.named();
}
void f() {
  C c = .n^()
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_constantContext() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  const C c = .^
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructorInvocation
  notConstant
    kind: constructor
''');
  }

  Future<void> test_constructor_constantContext_withPrefix() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  const C c = .n^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  named
    kind: constructorInvocation
  notConstant
    kind: constructor
''');
  }

  Future<void> test_constructor_constantContext_withPrefix_parentheses() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  const C c = .n^()
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  named
    kind: constructorInvocation
  notConstant
    kind: constructor
''');
  }

  Future<void> test_constructor_extensionType_named() async {
    allowedIdentifiers = {'named'};
    await computeSuggestions('''
extension type C(int x) {
  C.named(this.x);
}
void f() {
  C c = .^
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_extensionType_unnamed() async {
    allowedIdentifiers = {'new'};
    await computeSuggestions('''
extension type C(int x) {}
void f() {
  C c = .^
}
''');
    assertResponse(r'''
suggestions
  new
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_extensionType_withPrefix_named() async {
    allowedIdentifiers = {'named'};
    await computeSuggestions('''
extension type C(int x) {
  C.named(this.x);
}
void f() {
  C c = .n^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_extensionType_withPrefix_unnamed() async {
    allowedIdentifiers = {'new'};
    await computeSuggestions('''
extension type C(int x) {}
void f() {
  C c = .n^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  new
    kind: constructorInvocation
''');
  }

  Future<void> test_method_class() async {
    allowedIdentifiers = {'method', 'notStatic'};
    await computeSuggestions('''
class C {
  static C method() => C();
  C notStatic() => C();
}
void f() {
  C c = .^
}
''');
    assertResponse(r'''
suggestions
  method
    kind: methodInvocation
''');
  }

  Future<void> test_method_class_chain() async {
    allowedIdentifiers = {'method', 'anotherMethod', 'notStatic'};
    await computeSuggestions('''
class C {
  static C method() => C();
  static C anotherMethod() => C();
  C notStatic() => C();
}
void f() {
  C c = .anotherMethod().^
}
''');
    assertResponse(r'''
suggestions
  notStatic
    kind: methodInvocation
''');
  }

  Future<void> test_method_class_chain_withPrefix() async {
    allowedIdentifiers = {
      'method',
      'anotherMethod',
      'notStatic',
      'alsoInstance',
    };
    await computeSuggestions('''
class C {
  static C method() => C();
  static C anotherMethod() => C();
  C notStatic() => C();
  C alsoInstance() => C();
}
void f() {
  C c = .anotherMethod().no^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  notStatic
    kind: methodInvocation
''');
  }

  Future<void> test_method_class_withParentheses() async {
    allowedIdentifiers = {'method', 'notStatic'};
    await computeSuggestions('''
class C {
  static C method() => C();
  C notStatic() => C();
}
void f() {
  C c = .^()
}
''');
    assertResponse(r'''
suggestions
  method
    kind: methodInvocation
''');
  }

  Future<void> test_method_class_withPrefix() async {
    allowedIdentifiers = {'method', 'anotherMethod', 'notStatic'};
    await computeSuggestions('''
class C {
  static C method() => C();
  static C anotherMethod() => C();
  C notStatic() => C();
}
void f() {
  C c = .a^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  anotherMethod
    kind: methodInvocation
''');
  }

  Future<void> test_method_extensionType() async {
    allowedIdentifiers = {'method', 'notStatic'};
    await computeSuggestions('''
extension type C(int x) {
  static C method() => C(1);
  C notStatic() => C(1);
}
void f() {
  C c = .^
}
''');
    assertResponse(r'''
suggestions
  method
    kind: methodInvocation
''');
  }

  Future<void> test_method_extensionType_withPrefix() async {
    allowedIdentifiers = {'method', 'anotherMethod', 'notStatic'};
    await computeSuggestions('''
extension type C(int x) {
  static C method() => C(1);
  static C anotherMethod() => C(1);
  C notStatic() => C(1);
}
void f() {
  C c = .a^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  anotherMethod
    kind: methodInvocation
''');
  }
}
