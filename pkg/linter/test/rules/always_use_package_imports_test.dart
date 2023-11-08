// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AlwaysUsePackageImportsTest);
  });
}

@reflectiveTest
class AlwaysUsePackageImportsTest extends LintRuleTest {
  @override
  String get lintRule => 'always_use_package_imports';

  test_internalPackage() async {
    var packageConfigBuilder = PackageConfigFileBuilder();
    packageConfigBuilder.add(
      name: 'internal_package',
      rootPath: '$testPackageRootPath/vendor/internal_package',
    );
    writeTestPackageConfig(packageConfigBuilder);

    newFile('$testPackageRootPath/vendor/internal_package/lib/lib.dart', r'''
class C {}
''');
    await assertNoDiagnostics(r'''
/// This provides [C].
import 'package:internal_package/lib.dart';
''');
  }

  test_samePackage_packageSchema() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    await assertNoDiagnostics(r'''
/// This provides [C].
import 'package:test/lib.dart';
''');
  }

  test_samePackage_packageSchema_fromOutsideLib() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    var bin = newFile('$testPackageRootPath/bin/bin.dart', r'''
/// This provides [C].
import 'package:test/lib.dart';
''');
    await resolveTestFile();
    var result = await resolveFile(bin.path);
    await assertNoDiagnosticsIn(result.errors);
  }

  test_samePackage_relativeUri() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    await assertDiagnostics(r'''
/// This provides [C].
import 'lib.dart';
''', [
      lint(30, 10),
    ]);
  }
}
