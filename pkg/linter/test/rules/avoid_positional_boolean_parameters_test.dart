// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidPositionalBooleanParametersTest);
  });
}

@reflectiveTest
class AvoidPositionalBooleanParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_positional_boolean_parameters';

  test_anonymousFunction() async {
    await assertNoDiagnostics(r'''
void f(List<bool> list) {
  list.where((bool e) => e);
}
''');
  }

  test_constructor_fieldFormalParameter_named() async {
    await assertNoDiagnostics(r'''
class C {
  bool p;
  C.named({this.p = false});
}
''');
  }

  test_constructor_fieldFormalParameter_postional() async {
    await assertDiagnostics(r'''
class C {
  bool p;
  C.named(this.p);
}
''', [
      lint(30, 6),
    ]);
  }

  test_constructor_named_withDefault() async {
    await assertNoDiagnostics(r'''
class C {
  C.named({bool p = false}) {
  }
}
''');
  }

  test_constructor_positional() async {
    await assertDiagnostics(r'''
class C {
  C.named(bool a) {
  }
}
''', [
      lint(20, 6),
    ]);
  }

  test_constructorPrivate_positionalOptional() async {
    await assertNoDiagnostics(r'''
class C {
  // ignore: unused_element_parameter
  C._named([bool p = false]);
}
''');
  }

  test_extensionMethod() async {
    await assertDiagnostics(r'''
extension Ext on int {
  void f([bool p = false]) {}
}
''', [
      lint(33, 14),
    ]);
  }

  test_extensionMethod_unnamed() async {
    await assertDiagnostics(r'''
extension on int {
  // ignore: unused_element, unused_element_parameter
  void f([bool p = false]) {}
}
''', [
      lint(83, 14),
    ]);
  }

  test_instanceMethod_named() async {
    await assertNoDiagnostics(r'''
class C {
  void m({bool p = true}) {}
}
''');
  }

  test_instanceMethod_overrideExtends_positionalOptional() async {
    // TODO(srawlins): Test where the parameter in the override is _not found_
    // in the parent interface.
    // TODO(srawlins): Test where the parameter is renamed.
    await assertDiagnostics(r'''
class C {
  void m([bool p = false]) {}
}
class D extends C {
  @override
  void m([bool p = false]) {}
}
''', [
      lint(20, 14),
    ]);
  }

  test_instanceMethod_overrideImplements_positionalOptional() async {
    await assertDiagnostics(r'''
class C {
  void m([bool p = false]) {}
}
abstract class D implements C {
  @override
  void m([bool p = false]) {}
}
''', [
      lint(20, 14),
    ]);
  }

  test_instanceMethod_positional() async {
    await assertDiagnostics(r'''
class A {
  void m(bool p) {}
}
''', [
      lint(19, 6),
    ]);
  }

  test_instanceMethod_positionalOptional() async {
    await assertDiagnostics(r'''
class C {
  void m([bool p = false]) {}
}
''', [
      lint(20, 14),
    ]);
  }

  test_instanceSetter() async {
    await assertNoDiagnostics(r'''
class C {
  set m(bool p) {}
}
''');
  }

  test_operator_indexAssignment() async {
    await assertNoDiagnostics(r'''
class C {
  void operator []=(int index, bool value) {}
}
''');
  }

  test_operator_minus() async {
    await assertNoDiagnostics(r'''
class C {
  void operator -(bool value) {}
}
''');
  }

  test_operator_plus() async {
    await assertNoDiagnostics(r'''
class C {
  void operator +(bool value) {
  }
}
''');
  }

  test_staticMethod_namedWithDefault() async {
    await assertNoDiagnostics(r'''
class B {
  static void m({bool p = false}) {}
}
''');
  }

  test_staticMethod_positional() async {
    await assertDiagnostics(r'''
class B {
  static void m(bool p) {}
}
''', [
      lint(26, 6),
    ]);
  }

  test_topLevel_namedParameter() async {
    await assertNoDiagnostics(r'''
void f({bool p = false}) {}
''');
  }

  test_topLevel_namedParameter_defaultValue() async {
    await assertNoDiagnostics(r'''
void f({bool p = false}) {}
''');
  }

  test_topLevel_positionalParameter() async {
    await assertDiagnostics(r'''
void f(bool p) {}
''', [
      lint(7, 6),
    ]);
  }

  test_topLevelPrivate() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element
void _f(bool p) {}
''');
  }

  test_typedef_named() async {
    await assertNoDiagnostics(r'''
typedef T = Function({bool p});
''');
  }

  test_typedef_positional() async {
    await assertDiagnostics(r'''
typedef T = Function(bool p);
''', [
      lint(21, 6),
    ]);
  }
}
