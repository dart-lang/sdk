// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullSafetyExperimentGlobalTest);
    defineReflectiveTests(NullSafetyUsingAllowedExperimentsTest);
    defineReflectiveTests(PackageConfigAndLanguageOverrideTest);
  });
}

@reflectiveTest
class NullSafetyExperimentGlobalTest extends _FeaturesTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  @override
  bool get typeToStringWithNullability => true;

  test_jsonConfig_legacyContext_nonNullDependency() async {
    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    },
    {
      "name": "aaa",
      "rootUri": "${toUriStr('/aaa')}",
      "packageUri": "lib/"
    }
  ]
}
''');

    newFile('/aaa/lib/a.dart', content: r'''
int a = 0;
''');

    await assertNoErrorsInCode('''
import 'dart:math';
import 'package:aaa/a.dart';

var x = 0;
var y = a;
var z = pi;
''');
    assertType(findElement.topVar('x').type, 'int*');
    assertType(findElement.topVar('y').type, 'int*');
    assertType(findElement.topVar('z').type, 'double*');
  }

  test_jsonConfig_nonNullContext_legacyDependency() async {
    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/"
    },
    {
      "name": "aaa",
      "rootUri": "${toUriStr('/aaa')}",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    }
  ]
}
''');

    newFile('/aaa/lib/a.dart', content: r'''
int a = 0;
''');

    await assertNoErrorsInCode('''
import 'dart:math';
import 'package:aaa/a.dart';

var x = 0;
var y = a;
var z = pi;
''');
    assertType(findElement.topVar('x').type, 'int');
    assertType(findElement.topVar('y').type, 'int');
    assertType(findElement.topVar('z').type, 'double');

    var importFind = findElement.importFind('package:aaa/a.dart');
    assertType(importFind.topVar('a').type, 'int*');
  }
}

@reflectiveTest
class NullSafetyUsingAllowedExperimentsTest extends _FeaturesTest {
  @override
  bool get typeToStringWithNullability => true;

  test_jsonConfig_disable_bin() async {
    _configureAllowedExperimentsTestNullSafety();

    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.8"
    }
  ]
}
''');

    var path = convertPath('/test/bin/a.dart');
    await _resolveFile(path, r'''
var x = 0;
''');
    assertErrorsInList(result.errors, []);
    assertType(findElement.topVar('x').type, 'int*');

    // Upgrade the language version to `2.9`, so enabled Null Safety.
    driver.changeFile(path);
    await _resolveFile(path, r'''
// @dart = 2.9
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int');
  }

  test_jsonConfig_disable_lib() async {
    _configureAllowedExperimentsTestNullSafety();

    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.8"
    }
  ]
}
''');

    await assertNoErrorsInCode('''
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int*');

    // Upgrade the language version to `2.9`, so enabled Null Safety.
    _changeTestFile();
    await assertNoErrorsInCode('''
// @dart = 2.9
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int');
  }

  test_jsonConfig_enable_bin() async {
    _configureAllowedExperimentsTestNullSafety();

    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/"
    }
  ]
}
''');

    var path = convertPath('/test/bin/a.dart');
    await _resolveFile(path, r'''
var x = 0;
''');
    assertErrorsInList(result.errors, []);
    assertType(findElement.topVar('x').type, 'int');

    // Downgrade the version to `2.8`, so disable Null Safety.
    driver.changeFile(path);
    await _resolveFile(path, r'''
// @dart = 2.8
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int*');
  }

  test_jsonConfig_enable_lib() async {
    _configureAllowedExperimentsTestNullSafety();

    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/"
    }
  ]
}
''');

    await assertNoErrorsInCode('''
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int');

    // Downgrade the version to `2.8`, so disable Null Safety.
    _changeTestFile();
    await assertNoErrorsInCode('''
// @dart = 2.8
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int*');
  }

  void _changeTestFile() {
    var path = convertPath('/test/lib/test.dart');
    driver.changeFile(path);
  }

  void _configureAllowedExperimentsTestNullSafety() {
    _newSdkExperimentsFile(r'''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  },
  "sdk": {
    "default": {
      "experimentSet": "nullSafety"
    }
  },
  "packages": {
    "test": {
      "experimentSet": "nullSafety"
    }
  }
}
''');
  }

  void _newSdkExperimentsFile(String content) {
    newFile(
      '$sdkRoot/lib/_internal/allowed_experiments.json',
      content: content,
    );
  }

  Future<void> _resolveFile(String path, String content) async {
    newFile(path, content: content);
    result = await resolveFile(path);

    findNode = FindNode(result.content, result.unit);
    findElement = FindElement(result.unit);
  }
}

@reflectiveTest
class PackageConfigAndLanguageOverrideTest extends _FeaturesTest {
  test_jsonConfigDisablesExtensions() async {
    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.3"
    }
  ]
}
''');

    await assertErrorsInCode('''
extension E on int {}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 0, 9),
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 0, 9),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 12, 2),
      error(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 15, 3),
    ]);
  }

  test_jsonConfigDisablesExtensions_languageOverrideEnables() async {
    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.3"
    }
  ]
}
''');

    await assertNoErrorsInCode('''
// @dart = 2.6
extension E on int {}
''');
  }
}

class _FeaturesTest extends DriverResolutionTest {
  void _configureTestWithJsonConfig(String content) {
    newFile('/test/.dart_tool/package_config.json', content: content);

    driver.configure(
      packages: findPackagesFrom(
        resourceProvider,
        getFolder('/test'),
      ),
    );
  }
}
