// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules/directives_ordering.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DirectivesOrderingTest);
  });

  group('compareDirectives', () {
    void checkSection(List<String> correctlyOrderedImports) {
      for (int i = 0; i < correctlyOrderedImports.length; i++) {
        var a = correctlyOrderedImports[i];
        expect(
          compareDirectives(a, a),
          0,
          reason: '"$a" sorts the same as itself',
        );

        for (int j = i + 1; j < correctlyOrderedImports.length; j++) {
          var b = correctlyOrderedImports[j];
          expect(
            compareDirectives(a, b),
            lessThan(0),
            reason: '"$a" sorts before "$b"',
          );
          expect(
            compareDirectives(b, a),
            greaterThan(0),
            reason: '"$b" sorts after "$a"',
          );
        }
      }
    }

    test('dart: imports', () {
      checkSection(const ['dart:aaa', 'dart:bbb']);
    });

    test('package: imports', () {
      checkSection(const [
        'package:aa/bb.dart',
        'package:aaa/aaa.dart',
        'package:aaa/ccc.dart',
        'package:bbb/bbb.dart',
      ]);
    });

    test('relative imports', () {
      checkSection(const [
        '/foo5.dart',
        '../../foo4.dart',
        '../foo2/a.dart',
        '../foo3.dart',
        './foo2.dart',
        'a.dart',
        'aaa/aaa.dart',
        'bbb/bbb.dart',
        'foo1.dart',
      ]);
    });
  });
}

@reflectiveTest
class DirectivesOrderingTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.directives_ordering;

  @override
  void setUp() {
    newPackage('foo').addFile('lib/foo.dart', '');
    super.setUp();
  }

  test_dartDirectivesGoFirst_docImports() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnosticsFromMarkup(r'''
/// @docImport 'dart:math';
/// @docImport 'a.dart';
/// @doc/*[0*/Import 'dart:html';/*0]*/
/// @doc/*[1*/Import 'dart:isolate';/*1]*/
library;
''');
  }

  test_dartDirectivesGoFirst_exports() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export 'dart:math';
export 'a.dart';
/*[0*/export 'dart:html';/*0]*/
/*[1*/export 'dart:isolate';/*1]*/
// ignore_for_file: unused_import
''');
  }

  test_dartDirectivesGoFirst_imports() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnosticsFromMarkup(r'''
import 'dart:math';
import 'a.dart';
/*[0*/import 'dart:html';/*0]*/
/*[1*/import 'dart:isolate';/*1]*/
// ignore_for_file: unused_import
''');
  }

  test_importsGoBeforeExports() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    newFile('$testPackageLibPath/c.dart', '');
    await assertDiagnosticsFromMarkup(r'''
import 'a.dart';

/*[0*/export 'a.dart';/*0]*/

import 'b.dart';

/*[1*/export 'b.dart';/*1]*/

import 'c.dart';

export 'c.dart';
// ignore_for_file: unused_import
''');
  }

  test_multipleSchemaImportsSortedByPath() async {
    newFile('$testPackageLibPath/a.dart', '');
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

  test_packageDirectivesGoBeforeRelative_docImports() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    await assertDiagnosticsFromMarkup(r'''
/// @docImport 'dart:math';
/// @docImport 'package:foo/foo.dart';
/// @docImport 'a.dart';
/// @doc[!Import 'package:meta/meta.dart';!]
/// @docImport 'b.dart';
library;
''');
  }

  test_packageDirectivesGoBeforeRelative_exports() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export 'dart:math';
export 'a.dart';
/*[0*/export 'package:foo/foo.dart';/*0]*/
/*[1*/export 'package:meta/meta.dart';/*1]*/
export 'b.dart';
// ignore_for_file: unused_import
''');
  }

  test_packageDirectivesGoBeforeRelative_imports() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    await assertDiagnosticsFromMarkup(r'''
import 'dart:math';
import 'package:foo/foo.dart';
import 'a.dart';
[!import 'package:meta/meta.dart';!]
import 'b.dart';
// ignore_for_file: unused_import
''');
  }

  test_packageImportsSortedByPath() async {
    newFile('$testPackageLibPath/a.dart', '');
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

  test_partOrder_sorted() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    await assertNoDiagnostics(r'''
part 'a.dart';
part 'b.dart';
''');
  }

  test_partOrder_unsorted() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    // Because parts can contain augmentations, whose order of
    // application matters, we do *not* want to enforce part sorting.
    // See: https://github.com/dart-lang/linter/issues/4945
    await assertNoDiagnostics(r'''
part 'b.dart';
part 'a.dart';
''');
  }

  test_reportOneNodeOnlyOnce() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
import 'a.dart';
[!import 'package:foo/foo.dart';!]
// ignore_for_file: unused_import
''');
  }

  test_sortDirectiveSectionsAlphabetically_dartSchema_docImport() async {
    await assertDiagnosticsFromMarkup(r'''
/// @docImport 'dart:html';
/// @docImport 'dart:isolate';
/// @doc[!Import 'dart:convert';!]
/// @docImport 'dart:math';
library;
''');
  }

  test_sortDirectiveSectionsAlphabetically_dartSchema_export() async {
    await assertDiagnosticsFromMarkup(r'''
export 'dart:isolate';
[!export 'dart:convert';!]
export 'dart:math';
''');
  }

  test_sortDirectiveSectionsAlphabetically_dartSchema_import() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:html';
import 'dart:isolate';
[!import 'dart:convert';!]
import 'dart:math';
// ignore_for_file: unused_import
''');
  }

  test_sortDirectiveSectionsAlphabetically_dotInRelativePath_import() async {
    await assertDiagnosticsFromMarkup(r'''
import './foo1.dart';
[!import '../../foo2.dart';!]
import '../foo3.dart';
import 'foo4.dart';
// ignore_for_file: unused_import, uri_does_not_exist
''');
  }

  test_sortDirectiveSectionsAlphabetically_dotInRelativePath_import_ok() async {
    await assertNoDiagnostics(r'''
import '/foo5.dart';
import '../../foo4.dart';
import '../foo3.dart';
import './foo2.dart';
import 'foo1.dart';
// ignore_for_file: unused_import, uri_does_not_exist
''');
  }

  test_sortDirectiveSectionsAlphabetically_packageSchema_export() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    newFile('$testPackageLibPath/c.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export 'package:foo/foo.dart';
export 'package:meta/meta.dart';
/*[0*/export 'package:flutter/widgets.dart';/*0]*/

export 'package:test/a.dart';
export 'package:test/c.dart';
/*[1*/export 'package:test/b.dart';/*1]*/
''');
  }

  test_sortDirectiveSectionsAlphabetically_packageSchema_import() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    newFile('$testPackageLibPath/c.dart', '');
    await assertDiagnosticsFromMarkup(r'''
import 'package:foo/foo.dart';
import 'package:meta/meta.dart';
/*[0*/import 'package:flutter/widgets.dart';/*0]*/

import 'package:test/a.dart';
import 'package:test/c.dart';
/*[1*/import 'package:test/b.dart';/*1]*/
// ignore_for_file: unused_import
''');
  }

  test_sortDirectiveSectionsAlphabetically_relativePath_export() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    newFile('$testPackageLibPath/c.dart', '');
    newFile('$testPackageLibPath/d.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export 'd.dart';
[!export 'a.dart';!]
export 'b.dart';
export 'c.dart';
''');
  }

  test_sortDirectiveSectionsAlphabetically_relativePath_import() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    newFile('$testPackageLibPath/c.dart', '');
    newFile('$testPackageLibPath/d.dart', '');
    await assertDiagnosticsFromMarkup(r'''
import 'd.dart';
import 'd.dart';
/*[0*/import 'c.dart';/*0]*/
import 'c.dart';
/*[1*/import 'b.dart';/*1]*/
import 'b.dart';
/*[2*/import 'a.dart';/*2]*/
import 'a.dart';
// ignore_for_file: duplicate_import, unused_import
''');
  }
}
