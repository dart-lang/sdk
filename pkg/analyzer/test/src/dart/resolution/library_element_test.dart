// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryElementTest_featureSet);
    defineReflectiveTests(LibraryElementTest_toString);
  });
}

@reflectiveTest
class LibraryElementTest_featureSet extends PubPackageResolutionTest {
  test_language205() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.5',
    );

    await resolveTestCode('');

    _assertLanguageVersion(
      package: Version.parse('2.5.0'),
      override: null,
    );

    _assertFeatureSet([
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language208() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.8',
    );

    await resolveTestCode('');

    _assertLanguageVersion(
      package: Version.parse('2.8.0'),
      override: null,
    );

    _assertFeatureSet([
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.extension_methods,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language208_override205() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.8',
    );

    await resolveTestCode('// @dart = 2.5');

    // Valid override, less than the latest supported language version.
    _assertLanguageVersion(
      package: Version.parse('2.8.0'),
      override: Version.parse('2.5.0'),
    );

    _assertFeatureSet([
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language209() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.9',
    );

    await resolveTestCode('');

    _assertLanguageVersion(
      package: Version.parse('2.9.0'),
      override: null,
    );

    _assertFeatureSet([
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.extension_methods,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language212_override399() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.12',
    );

    await resolveTestCode('// @dart = 3.99');

    // Invalid override: minor is greater than the latest minor.
    _assertLanguageVersion(
      package: Version.parse('2.12.0'),
      override: null,
    );

    _assertFeatureSet([
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.extension_methods,
      Feature.non_nullable,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  test_language212_override400() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.12',
    );

    await resolveTestCode('// @dart = 4.00');

    // Invalid override: major is greater than the latest major.
    _assertLanguageVersion(
      package: Version.parse('2.12.0'),
      override: null,
    );

    _assertFeatureSet([
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.extension_methods,
      Feature.non_nullable,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  void _assertFeatureSet(List<Feature> expected) {
    var featureSet = result.libraryElement2.featureSet;

    var actual = ExperimentStatus.knownFeatures.values
        .where(featureSet.isEnabled)
        .toSet();

    expect(actual, unorderedEquals(expected));
  }

  void _assertLanguageVersion({
    required Version package,
    required Version? override,
  }) {
    var element = result.libraryElement2;
    expect(element.languageVersion.package, package);
    expect(element.languageVersion.override, override);
  }
}

@reflectiveTest
class LibraryElementTest_toString extends PubPackageResolutionTest {
  test_hasLibraryDirective_hasName() async {
    await assertNoErrorsInCode(r'''
library my.name;
''');

    expect(
      result.libraryElement2.toString(),
      'library package:test/test.dart',
    );
  }

  test_hasLibraryDirective_noName() async {
    await assertNoErrorsInCode(r'''
library;
''');

    expect(
      result.libraryElement2.toString(),
      'library package:test/test.dart',
    );
  }

  test_noLibraryDirective() async {
    await assertNoErrorsInCode(r'''
class A {}
''');

    expect(
      result.libraryElement2.toString(),
      'library package:test/test.dart',
    );
  }
}
