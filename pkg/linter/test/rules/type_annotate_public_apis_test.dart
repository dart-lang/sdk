// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  // TODO(srawlins): Add tests with constructor parameters, enums, unnamed
  // extensions.
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAnnotatePublicApisTest);
  });
}

@reflectiveTest
class TypeAnnotatePublicApisTest extends LintRuleTest {
  @override
  String get lintRule => 'type_annotate_public_apis';

  test_instanceField_onClass_hasInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  final x = 0;
}
''');
  }

  test_instanceField_onClass_hasVar_noInitializer() async {
    await assertDiagnostics(r'''
class A {
  var x;
}
''', [
      lint(16, 1),
    ]);
  }

  test_instanceField_onClass_inDeclarationList() async {
    await assertDiagnostics(r'''
class A {
  // ignore: unused_field
  var x, _y;
}
''', [
      lint(42, 1),
    ]);
  }

  test_instanceField_onClass_noInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  final x = 0;
}
''');
  }

  test_instanceField_onClass_nullInitializer() async {
    await assertDiagnostics(r'''
class A {
  final n = null;
}
''', [
      lint(18, 1),
    ]);
  }

  test_instanceGetter_onClass() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 42;
}
''');
  }

  test_instanceGetter_onClass_noReturnType() async {
    await assertDiagnostics(r'''
class A {
  get x => 42;
}
''', [
      lint(16, 1),
    ]);
  }

  test_instanceGetter_onExtension_noReturnType() async {
    await assertDiagnostics(r'''
extension E on int {
  get x => 0;
}
''', [
      lint(27, 1),
    ]);
  }

  test_instanceMethod_onClass_noReturnType() async {
    await assertDiagnostics(r'''
class A {
  m() {}
}
''', [
      lint(12, 1),
    ]);
  }

  test_instanceMethod_onClass_parameterMissingType() async {
    await assertDiagnostics(r'''
class A {
  void m(x) {}
}
''', [
      lint(19, 1),
    ]);
  }

  test_instanceMethod_onExtension_noReturnType() async {
    await assertDiagnostics(r'''
extension E on int {
  f() {}
}
''', [
      lint(23, 1),
    ]);
  }

  test_instanceMethod_onExtension_parameterMissingType() async {
    await assertDiagnostics(r'''
extension E on int {
  void m(p) {}
}
''', [
      lint(30, 1),
    ]);
  }

  test_instanceMethod_onExtensionType_noReturnType() async {
    // One test should be sufficient to verify extension type
    // support as the logic is implemented commonly for all members.
    await assertDiagnostics(r'''
extension type E(int i) {
  m() {}
}
''', [
      lint(28, 1),
    ]);
  }

  test_instanceMethod_parameterNameIsMultipleUnderscores() async {
    await assertNoDiagnostics(r'''
class A {
  void m(__) {}
}
''');
  }

  test_instanceMethod_parameterNameIsUnderscore() async {
    await assertNoDiagnostics(r'''
class A {
  void m(_) {}
}
''');
  }

  test_instanceSetter_noReturnType() async {
    await assertNoDiagnostics(r'''
class A {
  set x(int p) {}
}
''');
  }

  test_instanceSetter_onClass_parameterMissingType() async {
    await assertDiagnostics(r'''
class A {
  set x(p) {}
}
''', [
      lint(18, 1),
    ]);
  }

  test_instanceSetter_parameterMissingType() async {
    await assertDiagnostics(r'''
extension E on int {
  set x(p) {}
}
''', [
      lint(29, 1),
    ]);
  }

  test_instanceSetter_private_parameterMissingType() async {
    await assertNoDiagnostics(r'''
extension E on int {
  // ignore: unused_element
  set _x(p) {}
}
''');
  }

  test_localFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  // ignore: unused_element
  void g(x) {}
}
''');
  }

  test_staticConstField_hasInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  static const x = '';
}
''');
  }

  test_staticField_hasInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  static final x = 3;
}
''');
  }

  test_staticField_noInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  static final x = 0;
}
''');
  }

  test_staticField_nullInitializer() async {
    await assertDiagnostics(r'''
class A {
  static final x = null;
}
''', [
      lint(25, 1),
    ]);
  }

  test_staticField_withInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  static final x = 0;
}
''');
  }

  test_staticMethod_onClass_noReturnType() async {
    await assertDiagnostics(r'''
class A {
  static m() {}
}
''', [
      lint(19, 1),
    ]);
  }

  test_staticMethod_onClass_parameterHasVar() async {
    await assertDiagnostics(r'''
class A {
  static void m(var p) {}
}
''', [
      lint(26, 5),
    ]);
  }

  test_staticMethod_onClass_parameterMissingType() async {
    await assertDiagnostics(r'''
class A {
  static void m(p) {}
}
''', [
      lint(26, 1),
    ]);
  }

  test_topLevelConst() async {
    await assertNoDiagnostics(r'''
const x = '';
''');
  }

  test_topLevelFunction_noReturnType() async {
    await assertDiagnostics(r'''
f() {}
''', [
      lint(0, 1),
    ]);
  }

  test_topLevelFunction_parameterMissingType() async {
    await assertDiagnostics(r'''
void f(x) {}
''', [
      lint(7, 1),
    ]);
  }

  test_topLevelGetter_hasReturnType() async {
    await assertNoDiagnostics(r'''
int get x => 42;
''');
  }

  test_topLevelGetter_noReturnType() async {
    await assertDiagnostics(r'''
get x => 42;
''', [
      lint(4, 1),
    ]);
  }

  test_topLevelSetter_parameterHasType() async {
    await assertNoDiagnostics(r'''
set x(int p) {}
''');
  }

  test_topLevelSetter_parameterMissingType() async {
    await assertDiagnostics(r'''
set x(p) {}
''', [
      lint(6, 1),
    ]);
  }

  test_typedefLegacy_parameterMissingType() async {
    await assertDiagnostics(r'''
typedef F(x);
''', [
      lint(8, 1),
    ]);
  }

  test_typedefLegacy_private_parameterHasType() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element
typedef _F(int value);
''');
  }

  test_typedefLegacy_private_parameterMissingType() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element
typedef void _F(value);
''');
  }
}
