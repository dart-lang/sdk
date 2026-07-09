// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PublicMemberApiDocsExtensionTypesTest);
    defineReflectiveTests(PublicMemberApiDocsTest);
    defineReflectiveTests(PublicMemberApiDocsTestDirTest);
    defineReflectiveTests(PublicMemberApiDocsTestPackageTest);
  });
}

@reflectiveTest
class PublicMemberApiDocsExtensionTypesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.public_member_api_docs;

  test_extensionTypeDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
extension type [!E!](int i) { }
''');
  }

  test_field_instance() async {
    await assertDiagnostics(
      r'''
/// Doc.
extension type E(int i) {
  int? f;
}
''',
      [error(diag.extensionTypeDeclaresInstanceField, 42, 1)],
    );
  }

  test_field_static() async {
    await assertDiagnosticsFromMarkup(r'''
/// Doc.
extension type E(int i) {
  static int? [!f!];
}
''');
  }

  test_method() async {
    await assertDiagnosticsFromMarkup(r'''
/// Doc.
extension type E(int i) {
  void [!m!]() { }
}
''');
  }

  test_method_private() async {
    await assertNoDiagnostics(r'''
/// Doc.
extension type E(int i) {
  void _m() { }
}
''');
  }
}

@reflectiveTest
class PublicMemberApiDocsTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.public_member_api_docs;

  /// https://github.com/dart-lang/linter/issues/4526
  test_abstractFinalConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
abstract final class /*[0*/S/*0]*/ {
  S();
}

final class /*[1*/A/*1]*/ extends S {}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4526
  test_abstractInterfaceConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
abstract interface class /*[0*/S/*0]*/ {
  S();
}

final class /*[1*/A/*1]*/ extends S {}
''');
  }

  test_annotatedEnumValue() async {
    await assertNoDiagnostics(r'''
/// Documented.
enum A {
  /// This represents 'a'.
  @Deprecated("Use 'b'")
  a,

  /// This represents 'b'.
  b;
}
''');
  }

  test_constructor_namedGenerative() async {
    await assertDiagnosticsFromMarkup(r'''
class /*[0*/C/*0]*/ {
  C./*[1*/c/*1]*/();
}
''');
  }

  test_constructor_newSyntax() async {
    await assertDiagnosticsFromMarkup(r'''
class /*[0*/C/*0]*/ {
  /*[1*/new/*1]*/();
}
''');
  }

  test_constructor_unnamedFactory() async {
    await assertDiagnosticsFromMarkup(r'''
class /*[0*/C/*0]*/ {
  C._();

  factory /*[1*/C/*1]*/() => C._();
}
''');
  }

  test_constructor_unnamedGenerative() async {
    await assertDiagnosticsFromMarkup(r'''
class /*[0*/C/*0]*/ {
  /*[1*/C/*1]*/();
}
''');
  }

  test_enum() async {
    await assertDiagnosticsFromMarkup(r'''
enum /*[0*/A/*0]*/ {
  /*[1*/a/*1]*/,/*[2*/b/*2]*/,/*[3*/c/*3]*/;
  int /*[4*/x/*4]*/() => 0;
  int get /*[5*/y/*5]*/ => 1;
}
''');
  }

  test_enum_privateConstant() async {
    await assertNoDiagnostics(r'''
/// Documented.
enum A {
  _a;
}
''');
  }

  test_enumConstructor() async {
    await assertNoDiagnostics(r'''
/// Documented.
enum A {
  /// This represents 'a'.
  a(),

  /// This represents 'b'.
  b();

  const A();
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3525
  test_extension() async {
    await assertDiagnosticsFromMarkup(r'''
extension /*[0*/E/*0]*/ on Object {
  void /*[1*/f/*1]*/() { }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4521
  test_internalClass() async {
    await assertDiagnostics(
      r'''
import 'package:meta/meta.dart';

@internal
class C {
  int? f;
  int get i => 0;
  C();
  void m() {}
}
''',
      [
        // Technically not in the private API but we can ignore that for testing.
        error(diag.invalidInternalAnnotation, 35, 8),
      ],
    );
  }

  /// https://github.com/dart-lang/linter/issues/4521
  test_internalEnum() async {
    await assertDiagnostics(
      r'''
import 'package:meta/meta.dart';

@internal
enum E {
  a, b, c;
  int get i => 0;
  void m() {}

  const E();
}
''',
      [
        // Technically not in the private API but we can ignore that for testing.
        error(diag.invalidInternalAnnotation, 35, 8),
      ],
    );
  }

  /// https://github.com/dart-lang/linter/issues/4521
  test_internalExtension() async {
    await assertDiagnostics(
      r'''
import 'package:meta/meta.dart';

@internal
extension X on Object {
  static int? f;
  static int get i => 0;
  void e() {}
}
''',
      [
        // Technically not in the private API but we can ignore that for testing.
        error(diag.invalidInternalAnnotation, 35, 8),
      ],
    );
  }

  /// https://github.com/dart-lang/linter/issues/5030
  test_internalFunction() async {
    await assertDiagnostics(
      r'''
import 'package:meta/meta.dart';

@internal
void f() {}
''',
      [
        // Technically not in the private API but we can ignore that for testing.
        error(diag.invalidInternalAnnotation, 35, 8),
      ],
    );
  }

  /// https://github.com/dart-lang/linter/issues/4521
  test_internalMixin() async {
    await assertDiagnostics(
      r'''
import 'package:meta/meta.dart';

@internal
mixin M {
  int? f;
  int get i => 0;
  void m() {}
}
''',
      [
        // Technically not in the private API but we can ignore that for testing.
        error(diag.invalidInternalAnnotation, 35, 8),
      ],
    );
  }

  /// https://github.com/dart-lang/linter/issues/5030
  test_internalTopLevelVariable() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@internal
var f = 1;
''');
  }

  test_mixin_method() async {
    await assertDiagnosticsFromMarkup(r'''
/// A mixin M.
mixin M {
  String [!m!]() => '';
}''');
  }

  test_mixin_overridingMethod_OK() async {
    await assertNoDiagnostics(r'''
/// A mixin M.
mixin M {
  @override
  String toString() => '';
}''');
  }

  test_partFile() async {
    newFile('$testPackageRootPath/test/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

class [!A!] { }
''');
  }

  test_primaryConstructor_bodyPartNoDoc() async {
    await assertDiagnosticsFromMarkup(r'''
/// Doc.
class C(int x) {
  [!this!];
}
''');
  }

  test_primaryConstructor_bodyPartWithDoc() async {
    await assertNoDiagnostics(r'''
/// Class doc.
class C(int x) {
  /// Constructor doc.
  this;
}
''');
  }

  test_primaryConstructor_classNoDoc() async {
    await assertDiagnosticsFromMarkup(r'''
class [!C!](var int x);
''');
  }

  test_primaryConstructor_declaringParameterNoDoc() async {
    await assertDiagnosticsFromMarkup(r'''
/// Doc.
class [!C!](var int x);
''');
  }

  /// https://github.com/dart-lang/linter/issues/4526
  test_sealedConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
sealed class /*[0*/S/*0]*/ {
  S();
}

final class /*[1*/A/*1]*/ extends S {}
''');
  }

  test_topLevelMembers() async {
    await assertDiagnosticsFromMarkup(r'''
int /*[0*/g/*0]*/ = 1;
typedef /*[1*/T/*1]*/ = void Function();
int get /*[2*/z/*2]*/ => 0;
''');
  }

  test_topLevelMembers_private() async {
    await assertNoDiagnostics(r'''
int _h = 1;
typedef _T = void Function();
int get _z => 0;
''');
  }
}

@reflectiveTest
class PublicMemberApiDocsTestDirTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.public_member_api_docs;

  @override
  String get testPackageLibPath => '$testPackageRootPath/test';

  test_inTestDir() async {
    await assertNoDiagnostics(r'''
String? b;
typedef T = void Function();
''');
  }
}

@reflectiveTest
class PublicMemberApiDocsTestPackageTest extends LintRuleTest {
  String get filePath => '$fixturePackageLibPath/a.dart';

  String get fixturePackageLibPath => '$myPackageRootPath/test/fixture/lib';

  @override
  String get lintRule => LintNames.public_member_api_docs;

  String get myPackageRootPath => '$workspaceRootPath/myPackage';

  @override
  void setUp() {
    super.setUp();
    writePackageConfig(
      '$myPackageRootPath/.dart_tool/package_config.json',
      PackageConfigFileBuilder(),
    );
    newPubspecYamlFile(
      myPackageRootPath,
      pubspecYamlContent(name: 'myPackage'),
    );
    newAnalysisOptionsYamlFile(
      myPackageRootPath,
      analysisOptionsContent(experiments: experiments, rules: [lintRule]),
    );
    newFolder(fixturePackageLibPath);
    writePackageConfig(
      '$myPackageRootPath/test/fixture/.dart_tool/package_config.json',
      PackageConfigFileBuilder()
        ..add(name: 'fixture', rootFolder: getFolder(fixturePackageLibPath)),
    );
  }

  test_inTestLibDir() async {
    newFile(filePath, '''
String? b;
typedef T = void Function();
''');
    await assertNoDiagnosticsInFile(filePath);
  }
}
