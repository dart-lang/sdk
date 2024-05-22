// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AlwaysDeclareReturnTypesTest);
  });
}

@reflectiveTest
class AlwaysDeclareReturnTypesTest extends LintRuleTest {
  @override
  String get lintRule => 'always_declare_return_types';

  test_augmentationClass() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';

class A { }
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';

augment class A {
  f() { }
}
''');

    result = await resolveFile(a.path);
    await assertNoDiagnosticsIn(errors);

    result = await resolveFile(b.path);
    await assertDiagnosticsIn(errors, [
      lint(47, 1),
    ]);
  }

  test_augmentationTopLevelFunction() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';

f() { }
''');

    result = await resolveFile(a.path);
    await assertNoDiagnosticsIn(errors);

    result = await resolveFile(b.path);
    await assertDiagnosticsIn(errors, [
      lint(27, 1),
    ]);
  }

  /// Augmentation target chain variations tested in
  /// `augmentedTopLevelFunction{*}`.
  test_augmentedMethod() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';

class A {
  f() { }
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';

augment class A {
  augment f() { }
}
''');

    result = await resolveFile(a.path);
    await assertDiagnosticsIn(errors, [
      lint(38, 1),
    ]);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  test_augmentedTopLevelFunction() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';

f() { }
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';

augment f() { }
''');

    result = await resolveFile(a.path);
    await assertDiagnosticsIn(errors, [
      lint(26, 1),
    ]);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  test_augmentedTopLevelFunction_chain() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';

f() { }
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';

augment dynamic f() { }
augment f() { }
''');

    result = await resolveFile(a.path);
    await assertDiagnosticsIn(errors, [
      lint(26, 1),
    ]);

    result = await resolveFile(b.path);
    await assertNoDiagnosticsIn(errors);
  }

  test_extensionMethod() async {
    await assertDiagnostics(r'''
extension E on int {
  f() {}
}
''', [
      lint(23, 1),
    ]);
  }

  test_instanceSetter() async {
    await assertNoDiagnostics(r'''
class C {
  set f(int p) {}
}
''');
  }

  test_method_expressionBody() async {
    await assertDiagnostics(r'''
class C {
  f() => 42;
}
''', [
      lint(12, 1),
    ]);
  }

  test_method_withReturnType() async {
    await assertNoDiagnostics(r'''
class C {
  int f() => 42;
}
''');
  }

  test_operator() async {
    await assertNoDiagnostics(r'''
class C {
  operator []=(int index, int value) //OK: #300
  {}
}
''');
  }

  test_staticSetter() async {
    await assertNoDiagnostics(r'''
class C {
  static set f(int p) {}
}
''');
  }

  test_topLevelFunction_blockBody_withReturnType() async {
    await assertNoDiagnostics(r'''
int f() => 7;
''');
  }

  test_topLevelFunction_expressionBody() async {
    await assertDiagnostics(r'''
f() => 7;
''', [
      lint(0, 1),
    ]);
  }

  test_topLevelFunction_expressionBody_withReturnType() async {
    await assertNoDiagnostics(r'''
void f() { }
''');
  }

  test_topLevelFunction_noReturn() async {
    await assertDiagnostics(r'''
f() {}
''', [
      lint(0, 1),
    ]);
  }

  test_topLevelSetter() async {
    await assertNoDiagnostics(r'''
set f(int p) {}
''');
  }

  test_typedef_oldStyle() async {
    await assertDiagnostics(r'''
typedef t(int x);
''', [
      lint(8, 1),
    ]);
  }

  test_typedef_oldStyle_withReturnType() async {
    await assertNoDiagnostics(r'''
typedef bool t(int x);
''');
  }
}
