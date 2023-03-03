// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidRelativeLibImportsTest);
  });
}

@reflectiveTest
class AvoidRelativeLibImportsTest extends LintRuleTest {
  @override
  bool get addJsPackageDep => true;

  @override
  String get lintRule => 'avoid_relative_lib_imports';

  test_externalPackage() async {
    await assertNoDiagnostics(r'''
/// This provides [JS].
import 'package:js/js.dart';
''');
  }

  test_samePackage_relativeUri() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    var test = newFile('$testPackageRootPath/test/test.dart', r'''
/// This provides [C].
import '../lib/lib.dart';
''');
    var lib2Result = await resolveFile(test.path);
    await assertDiagnosticsIn(lib2Result.errors, [
      lint(30, 17),
    ]);
  }
}
