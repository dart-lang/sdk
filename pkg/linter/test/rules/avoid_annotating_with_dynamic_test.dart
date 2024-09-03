// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAnnotatingWithDynamicTest);
  });
}

@reflectiveTest
class AvoidAnnotatingWithDynamicTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_annotating_with_dynamic';

  test_augmentationClass() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A { }
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  void f(dynamic o) { }
}
''');

    result = await resolveFile(a.path);
    await assertNoDiagnosticsIn(errors);

    result = await resolveFile(b.path);
    await assertDiagnosticsIn(errors, [
      lint(46, 9),
    ]);
  }

  test_augmentationTopLevelFunction() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

void f(dynamic o) { }
''');

    result = await resolveFile(a.path);
    await assertNoDiagnosticsIn(errors);

    result = await resolveFile(b.path);
    await assertDiagnosticsIn(errors, [
      lint(26, 9),
    ]);
  }

  test_augmentationTopLevelFunction_localDynamic() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

void f(int i) {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment void f(int i) {
  var g = (dynamic x) {};
  g(i);
}
''');

    result = await resolveFile(a.path);
    await assertNoDiagnosticsIn(errors);

    result = await resolveFile(b.path);
    await assertDiagnosticsIn(errors, [
      lint(54, 9),
    ]);
  }

  test_augmentedMethod() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  void f(dynamic o) { }
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  augment void f(dynamic o) { }
}
''');

    result = await resolveFile(a.path);
    await assertDiagnosticsIn(errors, [
      lint(35, 9),
    ]);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  test_augmentedTopLevelFunction() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

void f(dynamic o) { }
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment void f(dynamic o) { }
''');

    result = await resolveFile(a.path);
    await assertDiagnosticsIn(errors, [
      lint(23, 9),
    ]);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  test_augmentedTopLevelFunction_multiple() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

void f(dynamic o) { }
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment void f(dynamic o) { }
augment void f(dynamic o) { }
''');

    result = await resolveFile(a.path);
    await assertDiagnosticsIn(errors, [
      lint(23, 9),
    ]);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  // TODO(srawlins): Test parameter of function-typed typedef (both old and
  // new style).
  // Test parameter of function-typed parameter (`f(void g(dynamic x))`).
  // Test parameter with a default value.

  test_fieldFormals() async {
    await assertDiagnostics(r'''
class A {
  var a;
  A(dynamic this.a);
}
''', [
      lint(23, 14),
    ]);
  }

  test_implicitDynamic() async {
    await assertNoDiagnostics(r'''
void f(p) {}
''');
  }

  test_optionalNamedParameter() async {
    await assertDiagnostics(r'''
void f({dynamic p}) {}
''', [
      lint(8, 9),
    ]);
  }

  test_optionalParameter() async {
    await assertDiagnostics(r'''
void f([dynamic p]) {}
''', [
      lint(8, 9),
    ]);
  }

  test_requiredParameter() async {
    await assertDiagnostics(r'''
void f(dynamic p) {}
''', [
      lint(7, 9),
    ]);
  }

  test_returnType() async {
    await assertNoDiagnostics(r'''
dynamic f() {
  return null;
}
''');
  }

  test_super() async {
    await assertDiagnostics(r'''
class A {
  var a;
  var b;
  A(this.a, this.b);
}
class B extends A {
  B(dynamic super.a, dynamic super.b);
}
''', [
      lint(75, 15),
      lint(92, 15),
    ]);
  }
}
