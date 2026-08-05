// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryElementTest_featureSet);
    defineReflectiveTests(LibraryElementTest_toString);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LibraryElementTest_featureSet extends PubPackageResolutionTest {
  static String get _currentLanguageVersion {
    var currentVersion = ExperimentStatus.currentVersion;
    return '${currentVersion.major}.${currentVersion.minor}';
  }

  test_language205() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.5');

    var result = await resolveTestCodeWithDiagnostics('');

    _assertLanguageVersion(
      result,
      package: Version.parse('2.5.0'),
      override: null,
    );

    _assertFeatureSet(result, [
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language208() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.8');

    var result = await resolveTestCodeWithDiagnostics('');

    _assertLanguageVersion(
      result,
      package: Version.parse('2.8.0'),
      override: null,
    );

    _assertFeatureSet(result, [
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.extension_methods,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language208_override205() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.8');

    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.5
// [diag.illegalLanguageVersionOverride][column 1][length 14] The language version must be >=2.12.0.
''');

    // Valid override, less than the latest supported language version.
    _assertLanguageVersion(
      result,
      package: Version.parse('2.8.0'),
      override: Version.parse('2.5.0'),
    );

    _assertFeatureSet(result, [
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language209() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.9');

    var result = await resolveTestCodeWithDiagnostics('');

    _assertLanguageVersion(
      result,
      package: Version.parse('2.9.0'),
      override: null,
    );

    _assertFeatureSet(result, [
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.extension_methods,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language212_override399() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.12');

    var result = await resolveTestCodeWithDiagnostics('''
// @dart = 3.99
// [diag.invalidLanguageVersionOverrideGreater][column 1][length 15] The language version override can't specify a version greater than the latest known language version: $_currentLanguageVersion.
''');

    // Invalid override: minor is greater than the latest minor.
    _assertLanguageVersion(
      result,
      package: Version.parse('2.12.0'),
      override: null,
    );

    _assertFeatureSet(result, [
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.extension_methods,
      Feature.non_nullable,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language212_override400() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.12');

    var result = await resolveTestCodeWithDiagnostics('''
// @dart = 4.00
// [diag.invalidLanguageVersionOverrideGreater][column 1][length 15] The language version override can't specify a version greater than the latest known language version: $_currentLanguageVersion.
''');

    // Invalid override: major is greater than the latest major.
    _assertLanguageVersion(
      result,
      package: Version.parse('2.12.0'),
      override: null,
    );

    _assertFeatureSet(result, [
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.extension_methods,
      Feature.non_nullable,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  void _assertFeatureSet(
    TestResolvedUnitResult result,
    List<Feature> expected,
  ) {
    var featureSet = result.libraryElement.featureSet;

    var actual = ExperimentStatus.knownFeatures.values
        .where(featureSet.isEnabled)
        .toSet();

    expect(actual, unorderedEquals(expected));
  }

  void _assertLanguageVersion(
    TestResolvedUnitResult result, {
    required Version package,
    required Version? override,
  }) {
    var element = result.libraryElement;
    expect(element.languageVersion.package, package);
    expect(element.languageVersion.override, override);
  }
}

@reflectiveTest
class LibraryElementTest_toString extends PubPackageResolutionTest {
  test_hasLibraryDirective_hasName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library my.name;
''');

    expect(result.libraryElement.toString(), 'library package:test/test.dart');
  }

  test_hasLibraryDirective_noName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library;
''');

    expect(result.libraryElement.toString(), 'library package:test/test.dart');
  }

  test_noLibraryDirective() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
''');

    expect(result.libraryElement.toString(), 'library package:test/test.dart');
  }
}
