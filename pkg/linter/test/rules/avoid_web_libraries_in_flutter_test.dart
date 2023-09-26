// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules/avoid_web_libraries_in_flutter.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidWebLibrariesInFlutterTest);
  });
}

@reflectiveTest
class AvoidWebLibrariesInFlutterTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'avoid_web_libraries_in_flutter';

  @override
  void setUp() {
    super.setUp();
    // This cache needs to be cleared between test cases.
    AvoidWebLibrariesInFlutter.clearCache();
  }

  test_nonFlutterPackage() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: non_flutter_app
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
''');
    var mainFile = newFile('$testPackageRootPath/lib/main.dart', r'''
// ignore: unused_import
import 'dart:html';
''');
    result = await resolveFile(mainFile.path);
    await assertNoDiagnosticsIn(result.errors);
  }

  test_nonWebApp() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: sample_project
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^0.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''');
    var mainFile = newFile('$testPackageRootPath/lib/main.dart', r'''
// ignore: unused_import
import 'dart:html';
''');
    result = await resolveFile(mainFile.path);
    await assertDiagnosticsIn(result.errors, [
      lint(25, 19),
    ]);
  }

  test_noPubspec() async {
    var mainFile = newFile('$testPackageRootPath/lib/main.dart', r'''
// ignore: unused_import
import 'dart:html';
''');
    result = await resolveFile(mainFile.path);
    await assertNoDiagnosticsIn(result.errors);
  }

  test_webApp() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: sample_project
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^0.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''');
    var mainFile = newFile('$testPackageRootPath/lib/main.dart', r'''
// ignore: unused_import
import 'dart:html';
''');
    newFile('$testPackageRootPath/web/README', 'Placeholder.');
    result = await resolveFile(mainFile.path);
    await assertDiagnosticsIn(result.errors, [
      // Even in a package with a `web/` directory, do not use web libraries.
      // Note(srawlins): This seems weird to me, but this is the expectation
      // from the previous version of this test.
      lint(25, 19),
    ]);
  }

  test_webPlugin() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: sample_project
version: 1.0.0+1

environment:
  sdk: ">=2.1.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^0.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  plugin:
    platforms:
      web:
        pluginClass: SamplePlugin
        fileName: main.dart
''');
    var mainFile = newFile('$testPackageRootPath/lib/main.dart', r'''
// ignore: unused_import
import 'dart:html';
''');
    result = await resolveFile(mainFile.path);
    await assertNoDiagnosticsIn(result.errors);
  }
}
