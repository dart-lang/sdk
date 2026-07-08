// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAnnotatingWithDynamicTest);
  });
}

@reflectiveTest
class AvoidAnnotatingWithDynamicTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_annotating_with_dynamic;

  test_augmentationClass() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A { }
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

augment class A {
  void f([!dynamic o!]) { }
}
''');
    await assertNoDiagnosticsInFile(a.path);
  }

  test_augmentationTopLevelFunction() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

void f([!dynamic o!]) { }
''');
    await assertNoDiagnosticsInFile(a.path);
  }

  test_augmentationTopLevelFunction_localDynamic() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f(int i);
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

augment void f(int i) {
  var g = ([!dynamic x!]) {};
  g(i);
}
''');
    await assertNoDiagnosticsInFile(a.path);
  }

  test_augmentedMethod() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  augment void f(dynamic o);
}
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

class A {
  void f([!dynamic o!]) { }
}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentedTopLevelFunction() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment void f(dynamic o);
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

void f([!dynamic o!]) { }
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentedTopLevelFunction_multiple() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment void f(dynamic o);
augment void f(dynamic o);
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

void f([!dynamic o!]) { }
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_fieldFormals() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  var a;
  A([!dynamic this.a!]);
}
''');
  }

  test_functionTypedParameter() async {
    await assertDiagnosticsFromMarkup(r'''
void f(void g([!dynamic x!])) {}
''');
  }

  test_genericTypedef() async {
    await assertDiagnosticsFromMarkup(r'''
typedef F = void Function([!dynamic x!]);
''');
  }

  test_implicitDynamic() async {
    await assertNoDiagnostics(r'''
void f(p) {}
''');
  }

  test_optionalNamedParameter() async {
    await assertDiagnosticsFromMarkup(r'''
void f({[!dynamic p!]}) {}
''');
  }

  test_optionalParameter() async {
    await assertDiagnosticsFromMarkup(r'''
void f([[!dynamic p!]]) {}
''');
  }

  test_parameter_defaultValue() async {
    await assertDiagnosticsFromMarkup(r'''
void f([[!dynamic x = 1!]]) {}
''');
  }

  test_primaryConstructor_declaringParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class C([!final dynamic a!]);
''');
  }

  test_primaryConstructor_fieldFormalParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class C([!dynamic this.a!]) {
  var a;
}
''');
  }

  test_primaryConstructor_simpleParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class C([!dynamic a!]);
''');
  }

  test_primaryConstructor_superParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class A(this.a, this.b) {
  var a;
  var b;
}
class B(/*[0*/dynamic super.a/*0]*/, /*[1*/dynamic super.b/*1]*/) extends A;
''');
  }

  test_requiredParameter() async {
    await assertDiagnosticsFromMarkup(r'''
void f([!dynamic p!]) {}
''');
  }

  test_returnType() async {
    await assertNoDiagnostics(r'''
dynamic f() {
  return null;
}
''');
  }

  test_super() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  var a;
  var b;
  A(this.a, this.b);
}
class B extends A {
  B(/*[0*/dynamic super.a/*0]*/, /*[1*/dynamic super.b/*1]*/);
}
''');
  }

  test_typedef() async {
    await assertDiagnosticsFromMarkup(r'''
typedef void F([!dynamic x!]);
''');
  }
}
