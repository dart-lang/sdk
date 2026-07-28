// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchExpressionOnTypeTest);
    defineReflectiveTests(SwitchStatementOnTypeTest);
  });
}

@reflectiveTest
class SwitchExpressionOnTypeTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.switch_on_type;

  Future<void> test_binaryExpression() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  (switch ([!'' + '$t'!]) {
    'type: int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_conditionalBoth() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  (switch ([!1 == 1 ? t : '$t'!]) {
    'type: int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_conditionalElse() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  (switch ([!1 == 1 ? 'other' : '$t'!]) {
    'type: int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_dynamic() async {
    await assertNoDiagnostics('''
void foo(dynamic a) {
  switch (a) {}
}
''');
  }

  Future<void> test_functionToString() async {
    await assertNoDiagnostics('''
void f() {
  (switch (toString()) {
    'int' => null,
    _ => null,
  });
}

String toString() => '';
''');
  }

  Future<void> test_functionToString_prefixed() async {
    await assertNoDiagnostics('''
import '' as self;

void f() {
  (switch (self.toString()) {
    'int' => null,
    _ => null,
  });
}

String toString() => '';
''');
  }

  Future<void> test_insideClass_implicitThis() async {
    await assertDiagnosticsFromMarkup('''
class A {
  void m() {
    (switch ([!runtimeType!]) {
      const (A) => null,
      _ => null,
    });
  }
}
''');
  }

  Future<void> test_insideClass_withThis() async {
    await assertDiagnosticsFromMarkup('''
class A {
  void m() {
    (switch ([!this.runtimeType!]) {
      const (A) => null,
      _ => null,
    });
  }
}
''');
  }

  Future<void> test_nestedSwitch() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t, Object o) {
  (switch ([!switch(o) {_ => t}!]) {
    const (int) => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_other() async {
    await assertNoDiagnostics('''
void f(num i) {
  (switch (i) {
    int _ => null,
    double _ => null,
  });
}
''');
  }

  Future<void> test_override() async {
    await assertDiagnosticsFromMarkup('''
void f(MyClass i) {
  (switch ([!i.runtimeType!]) {
    const (MyClass) => null,
    _ => null,
  });
}

class MyClass {
  @override
  Type get runtimeType => int;
}
''');
  }

  Future<void> test_runtimeType() async {
    await assertDiagnosticsFromMarkup('''
void f(num i) {
  (switch ([!i.runtimeType!]) {
    const (int) => null,
    const (double) => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_runtimeTypeToString() async {
    await assertDiagnosticsFromMarkup('''
void f(num n) {
  (switch ([!n.runtimeType.toString()!]) {
    'int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_runtimeTypeToString_insideClass() async {
    await assertDiagnosticsFromMarkup('''
class A {
  void m() {
    (switch ([!runtimeType.toString()!]) {
      'A' => null,
      _ => null,
    });
  }
}
''');
  }

  Future<void> test_runtimeTypeToString_insideClass_override() async {
    await assertDiagnosticsFromMarkup('''
class A {
  void m() {
    (switch ([!runtimeType.toString()!]) {
      'A' => null,
      _ => null,
    });
  }

  @override
  MyType get runtimeType => const MyType();
}

class MyType implements Type {
  const MyType();

  @override
  String toString() {
    return 'MyType';
  }
}
''');
  }

  Future<void> test_runtimeTypeToString_noCall() async {
    await assertNoDiagnostics('''
void f(num n) {
  (switch (n.runtimeType.toString) {
    function => null,
    _ => null,
  });
}

void function() {}
''');
  }

  Future<void> test_runtimeTypeToString_noCall_insideClass() async {
    await assertNoDiagnostics('''
class A {
  void m() {
    (switch (runtimeType.toString) {
      function => null,
      _ => null,
    });
  }
}

void function() {}
''');
  }

  Future<void> test_stringAddition() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  (switch ([!'type: ' + t.toString()!]) {
    'type: int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_stringInterpolation() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  (switch ([!'type: $t'!]) {
    'type: int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_stringInterpolation_innerConditionalResult() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  (switch ([!'type: ${1 == 1 ? '$t' : 'other'}'!]) {
    'type: int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_stringInterpolation_innerInterpolation() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  (switch ([!'type: ${'inner string $t'}'!]) {
    'type: int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_stringInterpolation_innerSwitchResult() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  (switch ([!'type: ${switch (1) {_ => '$t',}}'!]) {
    'type: int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_stringInterpolation_innerTest() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  (switch ([!'type: ${t == int ? 'int' : '$t'}'!]) {
    'type: int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_toString_insideClass_implicitThis() async {
    await assertNoDiagnostics('''
class A {
  void m() {
    (switch (toString()) {
      'A' => null,
      _ => null,
    });
  }
}
''');
  }

  Future<void> test_toString_insideClass_withThis() async {
    await assertNoDiagnostics('''
class A {
  void m() {
    (switch (this.toString()) {
      'A' => null,
      _ => null,
    });
  }
}
''');
  }

  Future<void> test_typeParameter() async {
    await assertDiagnosticsFromMarkup('''
void f<T>() {
  (switch ([!T!]) {
    const (int) => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_variable_typeToString() async {
    await assertNoDiagnostics(r'''
void f(Object? o) {
  final type = o.runtimeType.toString();
  (switch (type) {
    'int' => null,
    _ => null,
  });
}
''');
  }

  Future<void> test_variableType() async {
    await assertDiagnosticsFromMarkup('''
void f(Type t) {
  (switch ([!t!]) {
    const (int) => null,
    _ => null,
  });
}
''');
  }
}

@reflectiveTest
class SwitchStatementOnTypeTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.switch_on_type;

  Future<void> test_binaryExpression() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  switch ([!'' + '$t'!]) {
    case 'type: int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_conditionalBoth() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  switch ([!1 == 1 ? t : '$t'!]) {
    case 'type: int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_conditionalElse() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  switch ([!1 == 1 ? 'other' : '$t'!]) {
    case 'type: int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_functionToString() async {
    await assertNoDiagnostics('''
void f() {
  switch (toString()) {
    case 'int':
      break;
    default:
      break;
  }
}

String toString() => '';
''');
  }

  Future<void> test_functionToString_prefixed() async {
    await assertNoDiagnostics('''
import '' as self;

void f() {
  switch (self.toString()) {
    case 'int':
      break;
    default:
      break;
  }
}

String toString() => '';
''');
  }

  Future<void> test_insideClass_implicitThis() async {
    await assertDiagnosticsFromMarkup('''
class A {
  void m() {
    switch ([!runtimeType!]) {
      case const (A):
        break;
      default:
        break;
    }
  }
}
''');
  }

  Future<void> test_insideClass_withThis() async {
    await assertDiagnosticsFromMarkup('''
class A {
  void m() {
    switch ([!this.runtimeType!]) {
      case const (A):
        break;
      default:
        break;
    }
  }
}
''');
  }

  Future<void> test_nestedSwitch() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t, Object o) {
  switch ([!switch(o) {_ => t}!]) {
    case const (int):
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_other() async {
    await assertNoDiagnostics('''
void f(num i) {
  switch (i) {
    case int _:
      break;
    case double _:
      break;
  }
}
''');
  }

  Future<void> test_override() async {
    await assertDiagnosticsFromMarkup('''
void f(MyClass i) {
  switch ([!i.runtimeType!]) {
    case const (MyClass):
      break;
    default:
      break;
  }
}

class MyClass {
  @override
  Type get runtimeType => int;
}
''');
  }

  Future<void> test_prePatterns() async {
    await assertNoDiagnostics('''
// @dart = 2.19

void f(num i) {
  switch (i.runtimeType) {
    case int:
      break;
    case double:
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_runtimeType() async {
    await assertDiagnosticsFromMarkup('''
void f(num i) {
  switch ([!i.runtimeType!]) {
    case const (int):
      break;
    case const (double):
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_runtimeTypeToString() async {
    await assertDiagnosticsFromMarkup('''
void f(num n) {
  switch ([!n.runtimeType.toString()!]) {
    case 'int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_runtimeTypeToString_insideClass() async {
    await assertDiagnosticsFromMarkup('''
class A {
  void m() {
    switch ([!runtimeType.toString()!]) {
      case 'A':
        break;
      default:
        break;
    }
  }
}
''');
  }

  Future<void> test_runtimeTypeToString_insideClass_override() async {
    await assertDiagnosticsFromMarkup('''
class A {
  void m() {
    switch ([!runtimeType.toString()!]) {
      case 'A':
        break;
      default:
        break;
    }
  }

  @override
  MyType get runtimeType => const MyType();
}

class MyType implements Type {
  const MyType();

  @override
  String toString() {
    return 'MyType';
  }
}
''');
  }

  Future<void> test_runtimeTypeToString_noCall() async {
    await assertNoDiagnostics('''
void f(num n) {
  switch (n.runtimeType.toString) {
    case function:
      break;
    default:
      break;
  }
}

void function() {}
''');
  }

  Future<void> test_runtimeTypeToString_noCall_insideClass() async {
    await assertNoDiagnostics('''
class A {
  void m() {
    switch (runtimeType.toString) {
      case function:
        break;
      default:
        break;
    }
  }
}

void function() {}
''');
  }

  Future<void> test_stringAddition() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  switch ([!'type: ' + t.toString()!]) {
    case 'type: int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_stringInterpolation() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  switch ([!'type: $t'!]) {
    case 'type: int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_stringInterpolation_innerConditionalResult() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  switch ([!'type: ${1 == 1 ? '$t' : 'other'}'!]) {
    case 'type: int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_stringInterpolation_innerInterpolation() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  switch ([!'type: ${'inner string $t'}'!]) {
    case 'type: int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_stringInterpolation_innerSwitchResult() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  switch ([!'type: ${switch (1) {_ => '$t',}}'!]) {
    case 'type: int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_stringInterpolation_innerTest() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Type t) {
  switch ([!'type: ${t == int ? 'int' : '$t'}'!]) {
    case 'type: int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_toString_insideClass_implicitThis() async {
    await assertNoDiagnostics('''
class A {
  void m() {
    switch (toString()) {
      case 'A':
        break;
      default:
        break;
    }
  }
}
''');
  }

  Future<void> test_toString_insideClass_withThis() async {
    await assertNoDiagnostics('''
class A {
  void m() {
    switch (this.toString()) {
      case 'A':
        break;
      default:
        break;
    }
  }
}
''');
  }

  Future<void> test_typeParameter() async {
    await assertDiagnosticsFromMarkup('''
void f<T>() {
  switch ([!T!]) {
    case const (int):
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_variable_typeToString() async {
    await assertNoDiagnostics(r'''
void f(Object? o) {
  final type = o.runtimeType.toString();
  switch (type) {
    case 'int':
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_variableType() async {
    await assertDiagnosticsFromMarkup('''
void f(Type t) {
  switch ([!t!]) {
    case const (int):
      break;
    default:
      break;
  }
}
''');
  }
}
