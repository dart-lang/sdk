// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFinalFieldsExtensionTypesTest);
    defineReflectiveTests(PreferFinalFieldsTest);
  });
}

@reflectiveTest
class PreferFinalFieldsExtensionTypesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_final_fields;

  test_field_instance() async {
    await assertDiagnostics(r'''
extension type E(Object o) {
  int _i = 0;
}
''', [
      // No Lint.
      error(CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_INSTANCE_FIELD, 35, 2),
      error(WarningCode.UNUSED_FIELD, 35, 2),
    ]);
  }

  test_field_static() async {
    await assertDiagnostics(r'''
extension type E(Object o) {
  static int _i = 0;
}
''', [
      error(WarningCode.UNUSED_FIELD, 42, 2),
      lint(42, 6),
    ]);
  }

  test_field_static_writtenInConstructor() async {
    await assertDiagnostics(r'''
extension type E(Object o) {
  static Object _o = 0;
  E.e(this.o) {
    _o = o;
  }
}
''', [
      // No lint.
      error(WarningCode.UNUSED_FIELD, 45, 2),
    ]);
  }
}

@reflectiveTest
class PreferFinalFieldsTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_FIELD,
        WarningCode.UNUSED_LOCAL_VARIABLE,
      ];

  @override
  String get lintRule => LintNames.prefer_final_fields;

  test_assignedInConstructorInitializer() async {
    await assertDiagnostics(r'''
class C {
  int _x;
  C() : _x = 7;
}
''', [
      lint(16, 2),
    ]);
  }

  test_assignedInConstructorInitializer_butNotAll() async {
    await assertNoDiagnostics(r'''
class C {
  var _x;
  C(this._x);
  C.named();
}
''');
  }

  test_assignedInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';
int f(C c) {
  c._x = 1;
  return c._x;
}
''');
    await assertNoDiagnostics(r'''
part 'part.dart';
class C {
  int _x = 0;
}
''');
  }

  test_assignedInTopLevelFunction() async {
    await assertNoDiagnostics(r'''
class C {
  int _x = 0;
}

void f() {
  var c = C();
  c._x = 42;
}
''');
  }

  test_assignment_plusEquals() async {
    await assertNoDiagnostics(r'''
class C {
  var _x = 1;
  void f() {
    _x += 2;
  }
}
''');
  }

  test_declaredInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';
class C {
  int _x = 0;
}
''');
    await assertNoDiagnostics(r'''
part 'part.dart';
int f(C c) {
  c._x = 1;
  return c._x;
}
''');
  }

  test_enum() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  int _x = 0;
  int get x => _x;
}
''', [
      // No Lint.
      error(CompileTimeErrorCode.NON_FINAL_FIELD_IN_ENUM, 24, 2),
    ]);
  }

  test_final_multiple() async {
    await assertNoDiagnostics(r'''
class C {
  final _x = 1, _y = 2;
}
''');
  }

  test_final_public_multiple() async {
    await assertNoDiagnostics(r'''
class C {
  final x = 1, y = 2;
}
''');
  }

  test_indexAssignment() async {
    await assertDiagnostics(r'''
class C {
  var _x = [];

  void f() {
    _x[0] = 3;
  }
}
''', [
      lint(16, 7),
    ]);
  }

  test_overrideField_extends() async {
    await assertNoDiagnostics(r'''
class A {
  bool _a = false;
  void m() {
    _a = true;
    print(_a);
  }
}

class B extends A {
  @override
  bool _a = false;

  @override
  void m() {
    print(_a);
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3760
  test_overrideField_implements() async {
    await assertNoDiagnostics(r'''
class A {
  bool _a = false;
  void m() {
    _a = true;
    print(_a);
  }
}

class B implements A {
  @override
  bool _a = false;

  @override
  void m() {
    print(_a);
  }
}
''');
  }

  test_overrideSetter_extends() async {
    await assertNoDiagnostics(r'''
class A {
  set _a(bool a) {}
  void m() {
    _a = true;
  }
}

class B extends A {
  @override
  bool _a = false;

  @override
  void m() {
    print(_a);
  }
}
''');
  }

  test_overrideSetter_implements() async {
    await assertNoDiagnostics(r'''
class A {
  set _a(bool a) {}
  void m() {
    _a = true;
  }
}

class B implements A {
  @override
  bool _a = false;

  @override
  void m() {
    print(_a);
  }
}
''');
  }

  test_postfixExpression_decrement() async {
    await assertNoDiagnostics(r'''
class C {
  int _x = 1;
  void f() {
    _x--;
  }
}
''');
  }

  test_postfixExpression_increment() async {
    await assertNoDiagnostics(r'''
class C {
  int _x = 1;
  void f() {
    _x++;
  }
}
''');
  }

  test_prefixExpression_decrement() async {
    await assertNoDiagnostics(r'''
class C {
  int _x = 1;
  void f() {
    --_x;
  }
}
''');
  }

  test_prefixExpression_increment() async {
    await assertNoDiagnostics(r'''
class C {
  int _x = 1;
  void f() {
    ++_x;
  }
}
''');
  }

  test_prefixExpression_not() async {
    await assertDiagnostics(r'''
class C {
  bool _x = false;
  void f() {
    !_x;
  }
}
''', [
      lint(17, 10),
    ]);
  }

  test_prefixExpression_tilde() async {
    await assertDiagnostics(r'''
class C {
  int _x = 0xffff;
  void f() {
    ~_x;
  }
}
''', [
      lint(16, 11),
    ]);
  }

  test_propertyAccess() async {
    await assertDiagnostics(r'''
class C {
  int _x = 1;
  void f() {
    _x.isEven;
  }
}
''', [
      lint(16, 6),
    ]);
  }

  test_readInInstanceMethod() async {
    await assertDiagnostics(r'''
class C {
  int _x = 0;

  void f() {
    var a = _x;
  }
}
''', [
      lint(16, 6),
    ]);
  }

  test_reassigned() async {
    await assertNoDiagnostics(r'''
class C {
  var _x = 1;
  void f() {
    _x = 2;
  }
}
''');
  }

  test_referencedInFieldFormalParameters() async {
    await assertDiagnostics(r'''
class C {
  int _x;
  C(this._x);
  C.named(this._x);
}
''', [
      lint(16, 2),
    ]);
  }

  test_subclassOnGenericClass() async {
    await assertNoDiagnostics(r'''
abstract class C<T> {
  int _x = 0;
}

class D extends C<int> {
  void f() {
    _x = 1;
  }
}
''');
  }

  test_unused() async {
    await assertDiagnostics(r'''
class C {
  var _x = 1;
}
''', [
      lint(16, 6),
    ]);
  }

  test_unused_multiple() async {
    await assertDiagnostics(r'''
class C {
  var _x = 1, _y = 2;
  void f() {
    _x = 2;
  }
}
''', [
      lint(24, 6),
    ]);
  }

  test_unused_public() async {
    await assertNoDiagnostics(r'''
class C {
  var x = 1;
}
''');
  }

  test_unused_uninitialized() async {
    await assertNoDiagnostics(r'''
class C {
  int? _x;
}
''');
  }
}
