// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart';
import 'package:linter/src/rules/analyzer_use_new_elements.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
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
        ..add(name: 'analyzer', rootPath: analyzerFolder.path),
    );
  }

  test_enablement_optedOut() async {
    await assertDiagnostics(
      r'''
// ignore_for_file: analyzer_use_new_elements
import 'package:analyzer/dart/element/element.dart';

ClassElement f() {
  throw 42;
}
''',
      [error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 100, 12)],
    );
  }

  test_interfaceTypeImpl_element() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/dart/element/type.dart';

void f(InterfaceTypeImpl type) {
  type.element;
}
''',
      [error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 95, 7), lint(95, 7)],
    );
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

    await assertDiagnostics(
      r'''
import 'a.dart';

void f() {
  getAllClasses();
}
''',
      [lint(31, 13)],
    );
  }

  test_methodInvocation_inDeprecated() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:analyzer/dart/element/element.dart';

List<ClassElement> getAllClasses() => [];
''');

    await assertNoDiagnostics(r'''
import 'a.dart';

@deprecated
void f() {
  getAllClasses();
}
''');
  }

  test_methodInvocation_inDeprecated2() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/dart/element/element.dart';

@deprecated
void f(Element element) {
  var foo = element.nonSynthetic;
  print(foo);
}
''');
  }

  test_namedType() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/dart/element/element.dart';

ClassElement f() {
  throw 42;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 54, 12),
        lint(54, 12),
      ],
    );
  }

  test_propertyAccess() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/dart/ast/ast.dart';

void f(ClassDeclaration a) {
  a.declaredElement;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 79, 15),
        lint(79, 15),
      ],
    );
  }

  test_propertyAccess_declaredElement_src() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/dart/ast/ast.dart';

void f(ClassDeclarationImpl a) {
  a.declaredElement;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 87, 15),
        lint(87, 15),
      ],
    );
  }

  test_propertyAccess_nestedType() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:analyzer/dart/element/element.dart';

List<ClassElement> get allClasses => [];
''');

    await assertDiagnostics(
      r'''
import 'a.dart';

void f() {
  allClasses;
}
''',
      [lint(31, 10)],
    );
  }
}
