// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryElementTest_featureSet);
    defineReflectiveTests(LibraryElementTest_scope);
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

  test_language208_experimentNonNullable() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.8',
    );

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(experiments: [
        EnableString.non_nullable,
      ]),
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

  test_language209_experimentNonNullable_override210() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.9',
    );

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(experiments: [
        EnableString.non_nullable,
      ]),
    );

    await resolveTestCode('// @dart = 2.10');

    // Valid override, even if greater than the package language version.
    _assertLanguageVersion(
      package: Version.parse('2.9.0'),
      override: Version.parse('2.10.0'),
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

  test_language209_override299() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.9',
    );

    await resolveTestCode('// @dart = 2.99');

    // Invalid override: minor is greater than the latest minor.
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

  test_language209_override300() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.9',
    );

    await resolveTestCode('// @dart = 3.00');

    // Invalid override: major is greater than the latest major.
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

  test_language210_experimentNonNullable() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.10',
    );

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(experiments: [
        EnableString.non_nullable,
      ]),
    );

    await resolveTestCode('');

    _assertLanguageVersion(
      package: Version.parse('2.10.0'),
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

  test_language210_experimentNonNullable_override209() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.10',
    );

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(experiments: [
        EnableString.non_nullable,
      ]),
    );

    await resolveTestCode('// @dart = 2.9');

    _assertLanguageVersion(
      package: Version.parse('2.10.0'),
      override: Version.parse('2.9.0'),
    );

    _assertFeatureSet([
      Feature.constant_update_2018,
      Feature.control_flow_collections,
      Feature.extension_methods,
      Feature.set_literals,
      Feature.spread_collections,
    ]);
  }

  void _assertFeatureSet(List<Feature> expected) {
    var featureSet = result.libraryElement.featureSet;

    var actual = ExperimentStatus.knownFeatures.values
        .where(featureSet.isEnabled)
        .toSet();

    expect(actual, unorderedEquals(expected));
  }

  void _assertLanguageVersion({
    @required Version package,
    @required Version override,
  }) async {
    var element = result.libraryElement;
    expect(element.languageVersion.package, package);
    expect(element.languageVersion.override, override);
  }
}

@reflectiveTest
class LibraryElementTest_scope extends PubPackageResolutionTest {
  test_lookup2() async {
    await assertNoErrorsInCode(r'''
int foo;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('foo').getter,
      findElement.topGet('foo'),
    );
    assertElement(
      scope.lookup2('foo').setter,
      findElement.topSet('foo'),
    );
  }

  test_lookup2_implicitCoreImport() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('int').getter,
      intElement,
    );
  }

  test_lookup2_notFound() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElementNull(
      scope.lookup2('noSuchGetter').getter,
    );

    assertElementNull(
      scope.lookup2('noSuchSetter').setter,
    );
  }

  test_lookup2_prefersLocal() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math';

int sin() => 3;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('sin').getter,
      findElement.topFunction('sin'),
    );

    assertElement(
      scope.lookup2('cos').getter,
      findElement.importFind('dart:math').topFunction('cos'),
    );
  }

  test_lookup2_prefix() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('math').getter,
      findElement.prefix('math'),
    );
  }

  test_lookup2_respectsCombinator_hide() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' hide sin;
''');

    var scope = result.libraryElement.scope;

    assertElementNull(
      scope.lookup2('sin').getter,
    );

    var mathFind = findElement.importFind('dart:math');
    assertElement(
      scope.lookup2('cos').getter,
      mathFind.topFunction('cos'),
    );
    assertElement(
      scope.lookup2('tan').getter,
      mathFind.topFunction('tan'),
    );
  }

  test_lookup2_respectsCombinator_show() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' show sin;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('sin').getter,
      findElement.importFind('dart:math').topFunction('sin'),
    );

    assertElementNull(
      scope.lookup2('cos').getter,
    );
  }

  test_lookup_implicitCoreImport() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'int', setter: false),
      intElement,
    );
  }

  test_lookup_lookup() async {
    await assertNoErrorsInCode(r'''
int foo;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: false),
      findElement.topGet('foo'),
    );
    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: true),
      findElement.topSet('foo'),
    );
  }

  test_lookup_notFound() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'noSuchGetter', setter: false),
    );

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'noSuchSetter', setter: true),
    );
  }

  test_lookup_prefersLocal() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math';

int sin() => 3;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'sin', setter: false),
      findElement.topFunction('sin'),
    );

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'cos', setter: false),
      findElement.importFind('dart:math').topFunction('cos'),
    );
  }

  test_lookup_prefix() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'math', setter: false),
      findElement.prefix('math'),
    );
  }

  test_lookup_respectsCombinator_hide() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' hide sin;
''');

    var scope = result.libraryElement.scope;

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'sin', setter: false),
    );

    var mathFind = findElement.importFind('dart:math');
    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'cos', setter: false),
      mathFind.topFunction('cos'),
    );
    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'tan', setter: false),
      mathFind.topFunction('tan'),
    );
  }

  test_lookup_respectsCombinator_show() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' show sin;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'sin', setter: false),
      findElement.importFind('dart:math').topFunction('sin'),
    );

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'cos', setter: false),
    );
  }
}
