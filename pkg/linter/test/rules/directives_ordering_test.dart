// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DirectivesOrderingTest);
  });
}

@reflectiveTest
class DirectivesOrderingTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  bool get addJsPackageDep => true;

  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'directives_ordering';

  test_dartDirectivesGoFirst_exports() async {
    newFile2('$testPackageLibPath/a.dart', '');
    await assertDiagnostics(r'''
export 'dart:math';
export 'a.dart';
export 'dart:html';
export 'dart:isolate';
// ignore_for_file: unused_import
''', [
      lint(37, 19),
      lint(57, 22),
    ]);
  }

  test_dartDirectivesGoFirst_imports() async {
    newFile2('$testPackageLibPath/a.dart', '');
    await assertDiagnostics(r'''
import 'dart:math';
import 'a.dart';
import 'dart:html';
import 'dart:isolate';
// ignore_for_file: unused_import
''', [
      lint(37, 19),
      lint(57, 22),
    ]);
  }

  test_importsGoBeforeExports() async {
    newFile2('$testPackageLibPath/a.dart', '');
    newFile2('$testPackageLibPath/b.dart', '');
    newFile2('$testPackageLibPath/c.dart', '');
    await assertDiagnostics(r'''
import 'a.dart';

export 'a.dart';

import 'b.dart';

export 'b.dart';

import 'c.dart';

export 'c.dart';
// ignore_for_file: unused_import
''', [
      lint(18, 16),
      lint(54, 16),
    ]);
  }

  test_multipleSchemaImportsSortedByPath() async {
    newFile2('$testPackageLibPath/a.dart', '');
    await assertNoDiagnostics(r'''
// From analysis_server/test/services/correction/organize_directives_test.dart
// test named `sort`.
library lib;

import 'dart:aaa';
import 'dart:bbb';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';

import 'http://aaa.com';
import 'http://bbb.com';

import 'aaa/aaa.dart';
import 'bbb/bbb.dart';

export 'dart:aaa';
export 'dart:bbb';

export 'package:aaa/aaa.dart';
export 'package:bbb/bbb.dart';

export 'http://aaa.com';
export 'http://bbb.com';

export 'aaa/aaa.dart';
export 'bbb/bbb.dart';

part 'aaa/aaa.dart';
part 'bbb/bbb.dart';

main() {}

// ignore_for_file: unused_import, uri_does_not_exist
''');
  }

  test_packageDirectivesGoBeforeRelative_exports() async {
    newFile2('$testPackageLibPath/a.dart', '');
    newFile2('$testPackageLibPath/b.dart', '');
    await assertDiagnostics(r'''
export 'dart:math';
export 'a.dart';
export 'package:js/js.dart';
export 'package:meta/meta.dart';
export 'b.dart';
// ignore_for_file: unused_import
''', [
      lint(37, 28),
      lint(66, 32),
    ]);
  }

  test_packageDirectivesGoBeforeRelative_imports() async {
    newFile2('$testPackageLibPath/a.dart', '');
    newFile2('$testPackageLibPath/b.dart', '');
    await assertDiagnostics(r'''
import 'dart:math';
import 'package:js/js.dart';
import 'a.dart';
import 'package:meta/meta.dart';
import 'b.dart';
// ignore_for_file: unused_import
''', [
      lint(66, 32),
    ]);
  }

  test_packageImportsSortedByPath() async {
    newFile2('$testPackageLibPath/a.dart', '');
    await assertNoDiagnostics(r'''
// From analysis_server/test/services/correction/organize_directives_test.dart
// test named `sort_imports_packageAndPath`.

library lib;

import 'package:product.ui/entity.dart';
import 'package:product.ui.api/entity1.dart';
import 'package:product.ui.api/entity2.dart';
import 'package:product.ui.api.aaa/manager2.dart';
import 'package:product.ui.api.bbb/manager1.dart';
import 'package:product2.client/entity.dart';

// ignore_for_file: unused_import, uri_does_not_exist
''');
  }

  test_reportOneNodeOnlyOnce() async {
    newFile2('$testPackageLibPath/a.dart', '');
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
import 'a.dart';
import 'package:js/js.dart';
// ignore_for_file: unused_import
''', [
      lint(50, 28),
    ]);
  }

  test_sortDirectiveSectionsAlphabetically_dartSchema_export() async {
    await assertDiagnostics(r'''
export 'dart:isolate';
export 'dart:convert';
export 'dart:math';
''', [
      lint(23, 22),
    ]);
  }

  test_sortDirectiveSectionsAlphabetically_dartSchema_import() async {
    await assertDiagnostics(r'''
import 'dart:html';
import 'dart:isolate';
import 'dart:convert';
import 'dart:math';
// ignore_for_file: unused_import
''', [
      lint(43, 22),
    ]);
  }

  test_sortDirectiveSectionsAlphabetically_dotInRelativePath_import() async {
    await assertDiagnostics(r'''
import './foo1.dart';
import '../../foo2.dart';
import '../foo3.dart';
import 'foo4.dart';
// ignore_for_file: unused_import, uri_does_not_exist
''', [lint(22, 25)]);
  }

  test_sortDirectiveSectionsAlphabetically_dotInRelativePath_import_ok() async {
    await assertNoDiagnostics(r'''
import '../../foo4.dart';
import '../foo3.dart';
import './foo2.dart';
import 'foo1.dart';
// ignore_for_file: unused_import, uri_does_not_exist
''');
  }

  test_sortDirectiveSectionsAlphabetically_packageSchema_export() async {
    newFile2('$testPackageLibPath/a.dart', '');
    newFile2('$testPackageLibPath/b.dart', '');
    newFile2('$testPackageLibPath/c.dart', '');
    await assertDiagnostics(r'''
export 'package:js/js.dart';
export 'package:meta/meta.dart';
export 'package:flutter/widgets.dart';

export 'package:test/a.dart';
export 'package:test/c.dart';
export 'package:test/b.dart';
''', [
      lint(62, 38),
      lint(162, 29),
    ]);
  }

  test_sortDirectiveSectionsAlphabetically_packageSchema_import() async {
    newFile2('$testPackageLibPath/a.dart', '');
    newFile2('$testPackageLibPath/b.dart', '');
    newFile2('$testPackageLibPath/c.dart', '');
    await assertDiagnostics(r'''
import 'package:js/js.dart';
import 'package:meta/meta.dart';
import 'package:flutter/widgets.dart';

import 'package:test/a.dart';
import 'package:test/c.dart';
import 'package:test/b.dart';
// ignore_for_file: unused_import
''', [
      lint(62, 38),
      lint(162, 29),
    ]);
  }

  test_sortDirectiveSectionsAlphabetically_relativePath_export() async {
    newFile2('$testPackageLibPath/a.dart', '');
    newFile2('$testPackageLibPath/b.dart', '');
    newFile2('$testPackageLibPath/c.dart', '');
    newFile2('$testPackageLibPath/d.dart', '');
    await assertDiagnostics(r'''
export 'd.dart';
export 'a.dart';
export 'b.dart';
export 'c.dart';
''', [
      lint(17, 16),
    ]);
  }

  test_sortDirectiveSectionsAlphabetically_relativePath_import() async {
    newFile2('$testPackageLibPath/a.dart', '');
    newFile2('$testPackageLibPath/b.dart', '');
    newFile2('$testPackageLibPath/c.dart', '');
    newFile2('$testPackageLibPath/d.dart', '');
    await assertDiagnostics(r'''
import 'd.dart';
import 'd.dart';
import 'c.dart';
import 'c.dart';
import 'b.dart';
import 'b.dart';
import 'a.dart';
import 'a.dart';
// ignore_for_file: duplicate_import, unused_import
''', [
      lint(34, 16),
      lint(68, 16),
      lint(102, 16),
    ]);
  }
}
