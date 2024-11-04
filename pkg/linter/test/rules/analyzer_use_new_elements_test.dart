// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart';
import 'package:linter/src/rules/analyzer_use_new_elements.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalyzerUseNewElementsTest);
  });
}

@reflectiveTest
class AnalyzerUseNewElementsTest extends LintRuleTest {
  @override
  String get lintRule => AnalyzerUseNewElements.code.name;

  @override
  void setUp() {
    super.setUp();

    var physicalProvider = PhysicalResourceProvider.INSTANCE;
    var pkgPath = physicalProvider.pathContext.normalize(packageRoot);
    var analyzerLibSource = physicalProvider
        .getFolder(pkgPath)
        .getChildAssumingFolder('analyzer')
        .getChildAssumingFolder('lib');

    var analyzerFolder = newFolder('/packages/analyzer');
    analyzerLibSource.copyTo(analyzerFolder);

    newPackageConfigJsonFileFromBuilder(
      testPackageRootPath,
      PackageConfigFileBuilder()
        ..add(
          name: 'analyzer',
          rootPath: analyzerFolder.path,
        ),
    );

    AnalyzerUseNewElements.resetCaches();

    // No opt-outs in the most tests.
    _writeOptOuts('');
  }

  test_enablement_optedOut() async {
    _writeOptOuts(r'''
lib/test.dart
''');

    await assertDiagnostics(r'''
import 'package:analyzer/dart/element/element.dart';

ClassElement f() {
  throw 42;
}
''', []);
  }

  test_methodInvocation_hasFormalParameter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:analyzer/dart/element/element.dart';

void foo([List<ClassElement>? elements]) {}
''');

    await assertNoDiagnostics(r'''
import 'a.dart';

void f() {
  foo();
}
''');
  }

  test_methodInvocation_hasType() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:analyzer/dart/element/element.dart';

List<ClassElement> getAllClasses() => [];
''');

    await assertDiagnostics(r'''
import 'a.dart';

void f() {
  getAllClasses();
}
''', [
      lint(31, 13),
    ]);
  }

  test_namedType() async {
    await assertDiagnostics(r'''
import 'package:analyzer/dart/element/element.dart';

ClassElement f() {
  throw 42;
}
''', [
      lint(54, 12),
    ]);
  }

  test_propertyAccess() async {
    await assertDiagnostics(r'''
import 'package:analyzer/dart/ast/ast.dart';

void f(ClassDeclaration a) {
  a.declaredElement;
}
''', [
      lint(79, 15),
    ]);
  }

  test_propertyAccess_declaredElement_src() async {
    await assertDiagnostics(r'''
import 'package:analyzer/src/dart/ast/ast.dart';

void f(ClassDeclarationImpl a) {
  a.declaredElement;
}
''', [
      lint(87, 15),
    ]);
  }

  test_propertyAccess_nestedType() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:analyzer/dart/element/element.dart';

List<ClassElement> get allClasses => [];
''');

    await assertDiagnostics(r'''
import 'a.dart';

void f() {
  allClasses;
}
''', [
      lint(31, 10),
    ]);
  }

  void _writeOptOuts(String lines) {
    newFile('$testPackageRootPath/analyzer_use_new_elements.txt', lines);
  }
}
