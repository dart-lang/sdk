// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandPropertyAccessTest);
  });
}

@reflectiveTest
class DotShorthandPropertyAccessTest extends AbstractCompletionDriverTest
    with DotShorthandPropertyAccessTestCases {}

mixin DotShorthandPropertyAccessTestCases on AbstractCompletionDriverTest {
  Future<void> test_class() async {
    allowedIdentifiers = {'getter', 'notStatic'};
    await computeSuggestions('''
class C {
  static C get getter => C();
  C get notStatic => C();
}
void f() {
  C c = .^
}
''');
    assertResponse(r'''
suggestions
  getter
    kind: getter
''');
  }

  Future<void> test_class_assignment() async {
    allowedIdentifiers = {'setter', 'self'};
    await computeSuggestions('''
class C {
  set setter(int value) {}
  late C self = this;
}

void f(C foo) {var foo.^ = C()}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_class_assignment_prefix() async {
    allowedIdentifiers = {'setter', 'self'};
    await computeSuggestions('''
class C {
  set setter(int value) {}
  late C self = this;
}

void f(C foo) {var foo.s^ = C()}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_class_assignment_prefix_chain() async {
    allowedIdentifiers = {'setter', 'self'};
    await computeSuggestions('''
class C {
  set setter(int value) {}
  late C self = this;
}

void f(C foo) {var foo.s^.self = C()}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_class_chain() async {
    allowedIdentifiers = {'getter', 'anotherGetter', 'notStatic'};
    await computeSuggestions('''
class C {
  static C get getter => C();
  static C get anotherGetter => C();
  C get notStatic => C();
}
void f() {
  C c = .anotherGetter.^
}
''');
    assertResponse(r'''
suggestions
  notStatic
    kind: getter
''');
  }

  Future<void> test_class_chain_withPrefix() async {
    allowedIdentifiers = {'getter', 'anotherGetter', 'notStatic'};
    await computeSuggestions('''
class C {
  static C get getter => C();
  static C get anotherGetter => C();
  C get notStatic => C();
  C get anotherNotStatic => C();
}
void f() {
  C c = .anotherGetter.no^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  notStatic
    kind: getter
''');
  }

  Future<void> test_class_withPrefix() async {
    allowedIdentifiers = {'getter', 'anotherGetter', 'notStatic'};
    await computeSuggestions('''
class C {
  static C get getter => C();
  static C get anotherGetter => C();
  C get notStatic => C();
}
void f() {
  C c = .a^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  anotherGetter
    kind: getter
''');
  }

  Future<void> test_enum() async {
    allowedIdentifiers = {'red', 'blue', 'yellow'};
    await computeSuggestions('''
enum E { red, blue, yellow }
void f() {
  E e = .^
}
''');
    assertResponse(r'''
suggestions
  blue
    kind: enumConstant
  red
    kind: enumConstant
  yellow
    kind: enumConstant
''');
  }

  Future<void> test_enum_static() async {
    allowedIdentifiers = {'red', 'other'};
    await computeSuggestions('''
enum E {
  red;

  static const other = red;
}
void f() {
  E e = .^
}
''');
    assertResponse(r'''
suggestions
  other
    kind: field
  red
    kind: enumConstant
''');
  }

  Future<void> test_enum_withPrefix() async {
    allowedIdentifiers = {'red', 'blue', 'yellow', 'black'};
    await computeSuggestions('''
enum E { red, blue, yellow, black }
void f() {
  E e = .b^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  black
    kind: enumConstant
  blue
    kind: enumConstant
''');
  }

  Future<void> test_extensionType() async {
    allowedIdentifiers = {'getter', 'notStatic'};
    await computeSuggestions('''
extension type C(int x) {
  static C get getter => C(1);
  C get notStatic => C(1);
}
void f() {
  C c = .^
}
''');
    assertResponse(r'''
suggestions
  getter
    kind: getter
''');
  }

  Future<void> test_extensionType_withPrefix() async {
    allowedIdentifiers = {'getter', 'anotherGetter', 'notStatic'};
    await computeSuggestions('''
extension type C(int x) {
  static C get getter => C(1);
  static C get anotherGetter => C(1);
  C get notStatic => C(1);
}
void f() {
  C c = .a^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  anotherGetter
    kind: getter
''');
  }
}
