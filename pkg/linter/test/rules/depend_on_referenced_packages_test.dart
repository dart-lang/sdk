// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DependOnReferencedPackagesTest);
  });
}

@reflectiveTest
class DependOnReferencedPackagesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.depend_on_referenced_packages;

  String get sourceReferencingMeta => r'''
import 'package:meta/meta.dart';

@visibleForTesting
class C {}
''';

  test_referencedInBin_listedInDevDeps() async {
    newFile(testPackagePubspecPath, r'''
name: fancy
version: 1.1.1

dev_dependencies:
  meta: any
''');
    await assertDiagnosticsInBinFromMarkup(r'''
import [!'package:meta/meta.dart'!];

@visibleForTesting
class C {}
''');
  }

  void test_referencedInBuildHook_listedInDeps() async {
    newFile(testPackagePubspecPath, r'''
name: fancy
version: 1.1.1

dependencies:
  meta: any
''');
    await assertNoDiagnosticsInHook('build.dart', sourceReferencingMeta);
  }

  void test_referencedInBuildHook_listedInDevDeps() async {
    newFile(testPackagePubspecPath, r'''
name: fancy
version: 1.1.1

dev_dependencies:
  meta: any
''');
    await assertDiagnosticsInHookFromMarkup('build.dart', r'''
import [!'package:meta/meta.dart'!];

@visibleForTesting
class C {}
''');
  }

  void test_referencedInBuildHook_missingFromPubspec() async {
    newFile(testPackagePubspecPath, r'''
name: fancy
version: 1.1.1
''');
    await assertDiagnosticsInHookFromMarkup('build.dart', r'''
import [!'package:meta/meta.dart'!];

@visibleForTesting
class C {}
''');
  }

  test_referencedInLib_flutterGen() async {
    var packageConfigBuilder = PackageConfigFileBuilder();
    packageConfigBuilder.add(
      name: 'flutter_gen',
      rootFolder: getFolder('$workspaceRootPath/flutter_gen'),
    );
    writeTestPackageConfig(packageConfigBuilder);
    newFile(testPackagePubspecPath, r'''
name: test
version: 1.1.1
''');
    newFile('$workspaceRootPath/flutter_gen/lib/gen.dart', 'var x = 1;');
    await assertNoDiagnostics(r'''
import 'package:flutter_gen/gen.dart';

var y = x;
''');
  }

  test_referencedInLib_listedInDeps() async {
    newFile(testPackagePubspecPath, r'''
name: fancy
version: 1.1.1

dependencies:
  meta: any
''');
    await assertNoDiagnostics(sourceReferencingMeta);
  }

  test_referencedInLib_listedInDevDeps() async {
    newFile(testPackagePubspecPath, r'''
name: fancy
version: 1.1.1

dev_dependencies:
  meta: any
''');
    await assertDiagnosticsFromMarkup(r'''
import [!'package:meta/meta.dart'!];

@visibleForTesting
class C {}
''');
  }

  test_referencedInLib_missingFromPubspec() async {
    newFile(testPackagePubspecPath, r'''
name: fancy
version: 1.1.1
''');
    await assertDiagnosticsFromMarkup(r'''
import [!'package:meta/meta.dart'!];

@visibleForTesting
class C {}
''');
  }

  test_referencedInLib_selfPackage() async {
    newFile(testPackagePubspecPath, r'''
name: test
version: 1.1.1
''');
    newFile('$testPackageRootPath/lib/lib.dart', 'var x = 1;');
    await assertNoDiagnostics(r'''
import 'package:test/lib.dart';

var y = x;
''');
  }

  void test_referencedInLinkHook_listedInDevDeps() async {
    newFile(testPackagePubspecPath, r'''
name: fancy
version: 1.1.1

dev_dependencies:
  meta: any
''');
    await assertDiagnosticsInHookFromMarkup('link.dart', r'''
import [!'package:meta/meta.dart'!];

@visibleForTesting
class C {}
''');
  }

  test_referencedInTest_listedInDevDeps() async {
    newFile(testPackagePubspecPath, r'''
name: fancy
version: 1.1.1

dev_dependencies:
  meta: any
''');
    await assertNoDiagnosticsInTestDir(sourceReferencingMeta);
  }
}
