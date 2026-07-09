// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidPositionalBooleanParametersTest);
  });
}

@reflectiveTest
class AvoidPositionalBooleanParametersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_positional_boolean_parameters;

  test_anonymousFunction() async {
    await assertNoDiagnostics(r'''
void f(List<bool> list) {
  list.where((bool e) => e);
}
''');
  }

  test_augmentationConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  A(bool b);
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment A(bool b);
}
''');
  }

  test_augmentationFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f(bool b) { }
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment void f(bool b);
''');
  }

  test_augmentationMethod() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void f(bool b) { }
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment void f(bool b);
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

  test_constructor_fieldFormalParameter_positional() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  bool p;
  C.named([!this.p!]);
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C {
  C.named([!bool a!]) {
  }
}
''');
  }

  test_constructor_primary_declaringParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class C([!final bool p!]);
''');
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
    await assertDiagnosticsFromMarkup(r'''
extension Ext on int {
  void f([[!bool p = false!]]) {}
}
''');
  }

  test_extensionMethod_unnamed() async {
    await assertDiagnosticsFromMarkup(r'''
extension on int {
  // ignore: unused_element, unused_element_parameter
  void f([[!bool p = false!]]) {}
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m([[!bool p = false!]]) {}
}
class D extends C {
  @override
  void m([bool p = false]) {}
}
''');
  }

  test_instanceMethod_overrideImplements_positionalOptional() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m([[!bool p = false!]]) {}
}
abstract class D implements C {
  @override
  void m([bool p = false]) {}
}
''');
  }

  test_instanceMethod_positional() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  void m([!bool p!]) {}
}
''');
  }

  test_instanceMethod_positionalOptional() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m([[!bool p = false!]]) {}
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class B {
  static void m([!bool p!]) {}
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f([!bool p!]) {}
''');
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
    await assertDiagnosticsFromMarkup(r'''
typedef T = Function([!bool p!]);
''');
  }
}
