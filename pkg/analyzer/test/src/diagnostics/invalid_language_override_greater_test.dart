// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
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

  /// The analyzer is newer than the SDK, so the language version of the SDK
  /// is the latest one, as for the compiler of this SDK.
  test_equalToSdk_sdkOlderThanAnalyzer() async {
    sdkLanguageVersion = Version.parse('3.13.0');
    _configureTestPackageLanguageVersion('3.12');
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.13
class A {}
''');
    _assertUnitLanguageVersion(
      result,
      package: Version.parse('3.12.0'),
      override: Version.parse('3.13.0'),
    );
  }

  /// The analyzer is older than the SDK, so the language version of the SDK
  /// is the latest one, even though it is newer than the analyzer.
  test_greaterThanAnalyzer_sdkNewerThanAnalyzer() async {
    var analyzerVersion = ExperimentStatus.currentVersion;
    var sdkVersion = Version(
      analyzerVersion.major,
      analyzerVersion.minor + 1,
      0,
    );
    sdkLanguageVersion = sdkVersion;
    _configureTestPackageLanguageVersion(
      '${analyzerVersion.major}.${analyzerVersion.minor}',
    );
    var result = await resolveTestCodeWithDiagnostics('''
// @dart = ${sdkVersion.major}.${sdkVersion.minor}
class A {}
''');
    _assertUnitLanguageVersion(
      result,
      package: analyzerVersion,
      override: sdkVersion,
    );
  }

  test_greaterThanLatest() async {
    var latestVersion = ExperimentStatus.currentVersion;
    var result = await resolveTestCodeWithDiagnostics('''
// @dart = ${latestVersion.major}.${latestVersion.minor + 1}
// [diag.invalidLanguageVersionOverrideGreater][column 1][length 15] The language version override can't specify a version greater than the latest known language version: ${latestVersion.major}.${latestVersion.minor}.
class A {}
''');
    _assertUnitLanguageVersion(result, package: latestVersion, override: null);
  }

  test_greaterThanPackage() async {
    _configureTestPackageLanguageVersion('2.5');
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.12
int? a;
''');
    _assertUnitLanguageVersion(
      result,
      package: Version.parse('2.5.0'),
      override: Version.parse('2.12.0'),
    );
  }

  /// The analyzer is newer than the SDK, so the language version of the SDK
  /// is the latest one, as for the compiler of this SDK.
  test_greaterThanSdk_sdkOlderThanAnalyzer() async {
    sdkLanguageVersion = Version.parse('3.13.0');
    _configureTestPackageLanguageVersion('3.12');
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.14
// [diag.invalidLanguageVersionOverrideGreater][column 1][length 15] The language version override can't specify a version greater than the latest known language version: 3.13.
class A {}
''');
    _assertUnitLanguageVersion(
      result,
      package: Version.parse('3.12.0'),
      override: null,
    );
  }

  test_lessThanPackage() async {
    _configureTestPackageLanguageVersion('2.19');
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.18
class A {}
''');
    _assertUnitLanguageVersion(
      result,
      package: Version.parse('2.19.0'),
      override: Version.parse('2.18.0'),
    );
  }

  void _assertUnitLanguageVersion(
    TestResolvedUnitResult result, {
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
