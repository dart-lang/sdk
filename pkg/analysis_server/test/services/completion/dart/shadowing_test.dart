// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ShadowingTest);
  });
}

@reflectiveTest
class ShadowingTest extends AbstractCompletionDriverTest
    with ShadowingTestCases {}

/// Test that when one declaration shadows another declaration, only the
/// innermost declaration is suggested.
///
/// By convention, the tests are named `test_shadowingKind_shadowedKind` where
/// the kinds are:
/// - class
/// - localFunction
/// - localVariable
/// - field
/// - method
/// - parameter
/// - topLevelFunction
/// - topLevelVariable
/// - typeParameter
mixin ShadowingTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  @override
  Future<void> setUp() async {
    await super.setUp();
    printerConfiguration.withElementOffset = true;
  }

  Future<void> test_field_class() async {
    await computeSuggestions('''
class C {
  String f0 = '';
  void m() {
    ^
  }
}

class f0 {}
''');
    assertResponse(r'''
suggestions
  f0
    kind: field
    offset: 19
''');
  }

  Future<void> test_field_topLevelFunction() async {
    await computeSuggestions('''
String f0() => '';

class C {
  String f0 = '';
  void m() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: field
    offset: 39
''');
  }

  Future<void> test_field_topLevelVariable() async {
    await computeSuggestions('''
String f0 = '';

class C {
  String f0 = '';
  void m() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: field
    offset: 36
''');
  }

  Future<void> test_localFunction_localFunction() async {
    await computeSuggestions('''
void f() {
  void f0() {}
  if (true) {
    void f0() {}
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: functionInvocation
    offset: 49
''');
  }

  Future<void> test_localFunction_localVariable() async {
    await computeSuggestions('''
void f() {
  var v0 = 0;
  if (true) {
    void v0() {}
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: functionInvocation
    offset: 48
''');
  }

  Future<void> test_localFunction_parameter() async {
    await computeSuggestions('''
void f(int v0) {
  void v0() {}
  ^
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: functionInvocation
    offset: 24
''');
  }

  Future<void> test_localVariable_localFunction() async {
    await computeSuggestions('''
void f() {
  void v0() {}
  if (true) {
    var v0 = 'zero';
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: localVariable
    offset: 48
''');
  }

  Future<void> test_localVariable_localVariable() async {
    await computeSuggestions('''
void f() {
  var v0 = 0;
  if (true) {
    var v0 = 'zero';
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: localVariable
    offset: 47
''');
  }

  Future<void> test_localVariable_parameter() async {
    await computeSuggestions('''
void f(int v0) {
  var v0 = 'zero';
  ^
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: localVariable
    offset: 23
''');
  }

  Future<void> test_localVariable_typeParameter() async {
    await computeSuggestions('''
void f<v0>() {
  var v0 = 'zero';
  ^
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: localVariable
    offset: 21
''');
  }

  Future<void> test_method_class() async {
    await computeSuggestions('''
class C {
  void m0() {
    ^
  }
}

class m0 {}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    offset: 17
''');
  }

  Future<void> test_method_topLevelFunction() async {
    await computeSuggestions('''
void m0() {}

class C {
  void m0() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    offset: 31
''');
  }

  Future<void> test_method_topLevelVariable() async {
    await computeSuggestions('''
int m0 = 0;

class C {
  void m0() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    offset: 30
''');
  }

  Future<void> test_parameter_class() async {
    await computeSuggestions('''
class c0 {
  void m(int c0) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  c0
    kind: parameter
    offset: 24
''');
  }

  Future<void> test_parameter_field() async {
    await computeSuggestions('''
class C {
  String f0 = '';
  void m(int f0) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: parameter
    offset: 41
''');
  }

  Future<void> test_parameter_method() async {
    await computeSuggestions('''
class C {
  String m0() => '';
  void m(int m0) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: parameter
    offset: 44
''');
  }

  Future<void> test_parameter_topLevelFunction() async {
    await computeSuggestions('''
String f0() => '';
void f(int f0) {
  ^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: parameter
    offset: 30
''');
  }

  Future<void> test_parameter_topLevelVariable() async {
    await computeSuggestions('''
String f0 = '';
void f(int f0) {
  ^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: parameter
    offset: 27
''');
  }

  Future<void> test_parameter_typeParameter() async {
    await computeSuggestions('''
void f<p0>(int p0) {
  ^
}
''');
    assertResponse(r'''
suggestions
  p0
    kind: parameter
    offset: 15
''');
  }

  Future<void> test_typeParameter_localVariable() async {
    await computeSuggestions('''
void f() {
  var v0 = 0;
  void g<v0>() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: typeParameter
    offset: 34
''');
  }

  Future<void> test_typeParameter_parameter() async {
    await computeSuggestions('''
void f(int p0) {
  void g<p0>() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  p0
    kind: typeParameter
    offset: 26
''');
  }

  Future<void> test_typeParameter_typeParameter() async {
    await computeSuggestions('''
void f<p0>() {
  void g<p0>() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  p0
    kind: typeParameter
    offset: 24
''');
  }
}
