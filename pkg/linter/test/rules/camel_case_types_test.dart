// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CamelCaseTypesTest);
  });
}

@reflectiveTest
class CamelCaseTypesTest extends LintRuleTest {
  @override
  String get lintRule => 'camel_case_types';

  test_augmentationClass_lowerCase() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class a { }
''');

    await assertNoDiagnostics(r'''
augment library 'a.dart';

augment class a { }
''');
  }

  @FailingTest(
      issue: 'https://github.com/dart-lang/linter/issues/4881',
      reason:
          "ParserErrorCode.EXTRANEOUS_MODIFIER [27, 7, Can't have modifier 'augment' here.]")
  test_augmentationEnum_lowerCase() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

enum e {
  a;
}
''');

    await assertNoDiagnostics(r'''
augment library 'a.dart';

augment enum e {
  augment b;
}
''');
  }

  test_augmentationExtensionType_lowerCase() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

extension type et(int i) { }
''');

    await assertNoDiagnostics(r'''
augment library 'a.dart';

augment extension type et(int i) { }
''');
  }

  test_augmentationMixin_lowerCase() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

mixin m { }
''');

    await assertNoDiagnostics(r'''
augment library 'a.dart';

augment mixin m { }
''');
  }

  test_extensionType_lowerCase() async {
    // No need to test all the variations. Name checking is shared with other
    // declaration types.
    await assertDiagnostics(r'''
extension type fooBar(int i) {}
''', [
      lint(15, 6),
    ]);
  }

  test_extensionType_wellFormed() async {
    await assertNoDiagnostics(r'''
extension type FooBar(int i) {}
''');
  }

  test_macroClass_lowerCase() async {
    await assertDiagnostics(r'''
macro class a { }
''', [
      lint(12, 1),
    ]);
  }

  test_mixin_lowerCase() async {
    await assertDiagnostics(r'''
mixin m { }
''', [
      lint(6, 1),
    ]);
  }
}
