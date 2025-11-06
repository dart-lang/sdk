// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidLanguageOverrideGreaterTest);
  });
}

@reflectiveTest
class InvalidLanguageOverrideGreaterTest extends PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => null;

  test_greaterThanLatest() async {
    var latestVersion = ExperimentStatus.currentVersion;
    await assertErrorsInCode(
      '''
// @dart = ${latestVersion.major}.${latestVersion.minor + 1}
class A {}
''',
      [error(WarningCode.invalidLanguageVersionOverrideGreater, 0, 15)],
    );
    _assertUnitLanguageVersion(package: latestVersion, override: null);
  }

  test_greaterThanPackage() async {
    _configureTestPackageLanguageVersion('2.5');
    await assertNoErrorsInCode(r'''
// @dart = 2.12
int? a;
''');
    _assertUnitLanguageVersion(
      package: Version.parse('2.5.0'),
      override: Version.parse('2.12.0'),
    );
  }

  test_lessThanPackage() async {
    _configureTestPackageLanguageVersion('2.19');
    await assertNoErrorsInCode(r'''
// @dart = 2.18
class A {}
''');
    _assertUnitLanguageVersion(
      package: Version.parse('2.19.0'),
      override: Version.parse('2.18.0'),
    );
  }

  void _assertUnitLanguageVersion({
    required Version package,
    required Version? override,
  }) {
    var languageVersion = result.unit.languageVersion;
    expect(languageVersion.package, package);
    expect(languageVersion.override, override);
  }

  void _configureTestPackageLanguageVersion(String versionStr) {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: versionStr,
    );
  }
}
