// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferTypingUninitializedVariablesTest);
  });
}

@reflectiveTest
class PreferTypingUninitializedVariablesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_typing_uninitialized_variables;

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/56174',
    reason: 'There is a diagnostic in b.dart.',
  )
  // TODO(scheglov): implement augmentation
  test_field_augmented() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  augment var x;
}
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

class A {
  var [!x!];
}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_field_final_noInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  final [!x!];
  C(this.x);
}
''');
  }

  test_field_typed() async {
    await assertNoDiagnostics(r'''
class C {
  String? x;
}
''');
  }

  test_field_var_noInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  var [!x!];
}
''');
  }

  test_field_var_noInitializer_notFirst() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  var a = 5,
      [!b!];
}
''');
  }

  test_field_var_noInitializer_static() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static var [!x!];
}
''');
  }

  test_forEachLoopVariable_final() async {
    await assertNoDiagnostics(r'''
void f() {
  for (final e in <String>[]) {}
}
''');
  }

  test_forLoopVariable_var_noInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for (var [!i!], j = 0; j < 5; i = j, j++) {}
}
''');
  }

  test_localVariable_var_initializer() async {
    await assertNoDiagnostics(r'''
void f() {
  // ignore: unused_local_variable
  var x = 1;
}
''');
  }

  test_localVariable_var_noInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  // ignore: unused_local_variable
  var [!x!];
}
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/56174',
    reason: 'There is a diagnostic in b.dart.',
  )
  // TODO(scheglov): implement augmentation
  test_topLevelVariable_augmented() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment var x;
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

var [!x!];
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_topLevelVariable_var_initializer() async {
    await assertNoDiagnostics(r'''
var x = 4;
''');
  }

  test_topLevelVariable_var_noInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
var [!x!];
''');
  }
}
