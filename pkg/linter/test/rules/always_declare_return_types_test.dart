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

  /// Augmentation target chain variations tested in `augmentedTopLevelFunction{*}`.
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
}
