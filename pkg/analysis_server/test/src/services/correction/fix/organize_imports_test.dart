// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OrganizeImportsBulkTest);
    defineReflectiveTests(OrganizeImportsDirectivesOrderingTest);
  });
}

@reflectiveTest
class OrganizeImportsBulkTest extends BulkFixProcessorTest {
  Future<void> test_comments() async {
    await parseTestCode('''
import 'dart:io'; // comment1

// comment2
import 'dart:async';

Future? a;
''');

    await assertOrganize('''
// comment2
import 'dart:async';
import 'dart:io'; // comment1

Future? a;
''');
  }

  Future<void> test_partFile() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await resolveTestCode('''
part of 'a.dart';

import 'dart:io';
import 'dart:async';

Future? a;
''');

    await assertOrganize('''
part of 'a.dart';

import 'dart:async';
import 'dart:io';

Future? a;
''');
  }

  Future<void> test_single_file() async {
    await parseTestCode('''
import 'dart:io';
import 'dart:async';

Future? a;
''');

    await assertOrganize('''
import 'dart:async';
import 'dart:io';

Future? a;
''');
  }

  Future<void> test_withParts() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await parseTestCode('''
import 'dart:io';
import 'dart:async';

part 'a.dart';

Future? a;
''');

    await assertOrganize('''
import 'dart:async';
import 'dart:io';

part 'a.dart';

Future? a;
''');
  }
}

@reflectiveTest
class OrganizeImportsDirectivesOrderingTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.organizeImports;

  @override
  String get lintCode => LintNames.directives_ordering;

  bool Function(Diagnostic diagnostic) get _firstUnusedShownNameErrorFilter {
    var firstError = true;
    return (Diagnostic diagnostic) {
      if (firstError && diagnostic.diagnosticCode == diag.unusedShownName) {
        firstError = false;
        return true;
      }
      return false;
    };
  }

  Future<void> test_organizeImports() async {
    await resolveTestCode('''
//ignore_for_file: unused_import
import 'dart:io';

import 'dart:async';

void f(Stream<String> args) { }
''');
    await assertHasFix('''
//ignore_for_file: unused_import
import 'dart:async';
import 'dart:io';

void f(Stream<String> args) { }
''');
  }

  Future<void> test_organizeImports_docImports() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCode('''
/// @docImport 'a.dart';
/// @docImport 'dart:math';
library;
''');
    await assertHasFix('''
/// @docImport 'dart:math';
///
/// @docImport 'a.dart';
library;
''');
  }

  Future<void> test_organizeImports_docImports_blockComment() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCode('''
/**
 * @docImport 'a.dart';
 * @docImport 'dart:math';
 */
library;
''');
    await assertHasFix('''
/**
 * @docImport 'dart:math';
 *
 * @docImport 'a.dart';
 */
library;
''');
  }

  Future<void> test_organizeImports_docImports_blockComment_weird() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCode('''
/** @docImport 'a.dart';
 * @docImport 'dart:math';*/
library;
''');
    // The `@docImport`s aren't recognized here: the first shares its line with
    // the opening `/**` and the second with the closing `*/`, so neither is
    // parsed as a doc import and `directives_ordering` never fires. There is
    // no fix to offer.
    expect(
      testAnalysisResult.diagnostics.where(lintNameFilter(lintCode)),
      isEmpty,
    );
  }

  Future<void> test_organizeImports_docImports_multiple() async {
    // TODO(FMorschel): Move docImports with preceding comments together. Since
    //  they might be ignores or information related to it.
    await resolveTestCode('''
/// Text
/// @docImport 'dart:math';
/// one
/// @docImport 'dart:async';
/// two
/// @docImport 'dart:io';
/// three
library;
''');
    await assertHasFix('''
/// Text
/// @docImport 'dart:async';
/// @docImport 'dart:io';
/// @docImport 'dart:math';
/// one
/// two
/// three
library;
''');
  }

  Future<void> test_organizeImports_docImports_noTextBefore() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCode('''
/// @docImport 'a.dart';
/// middle
/// @docImport 'dart:math';
/// end
library;
''');
    await assertHasFix('''
/// @docImport 'dart:math';
///
/// @docImport 'a.dart';
/// middle
/// end
library;
''');
  }

  Future<void> test_organizeImports_docImports_other() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCode('''
/// Text
/// @docImport 'a.dart';
/// all
/// @docImport 'dart:math';
/// over
library;
''');
    await assertHasFix('''
/// Text
/// @docImport 'dart:math';
///
/// @docImport 'a.dart';
/// all
/// over
library;
''');
  }

  Future<void> test_organizeImports_docImports_packageImport() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCode('''
/// Text
/// @docImport 'package:test/a.dart';
/// middle
/// @docImport 'dart:math';
/// end
library;
''');
    await assertHasFix('''
/// Text
/// @docImport 'dart:math';
///
/// @docImport 'package:test/a.dart';
/// middle
/// end
library;
''');
  }

  Future<void>
  test_organizeImports_docImports_removesRedundantBlankLine() async {
    await resolveTestCode('''
/// @docImport 'dart:math';
///
/// @docImport 'dart:async';
library;
''');
    await assertHasFix('''
/// @docImport 'dart:async';
/// @docImport 'dart:math';
library;
''');
  }

  Future<void> test_organizeImports_docImports_textBeforeAndAfter() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCode('''
/// Text
/// @docImport 'a.dart';
/// @docImport 'dart:math';
/// End
library;
''');
    await assertHasFix('''
/// Text
/// @docImport 'dart:math';
///
/// @docImport 'a.dart';
/// End
library;
''');
  }

  Future<void> test_organizeImports_wildcards() async {
    await resolveTestCode('''
//ignore_for_file: unused_import
import 'dart:io' as _;
import 'dart:math' as math;

import 'dart:async';

void f(Stream<String> args) { }
''');
    await assertHasFix('''
//ignore_for_file: unused_import
import 'dart:async';
import 'dart:io' as _;
import 'dart:math' as math;

void f(Stream<String> args) { }
''');
  }

  Future<void> test_organizePathImports() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static void m() {}
}
''');
    newFile('$testPackageLibPath/a/b.dart', '''
class B {
  static void m() {}
}
''');

    await resolveTestCode('''
import 'dart:async';
import 'a/b.dart';
import 'a.dart';

void f(Stream<String> args) {
  A.m();
  B.m();
}
''');
    await assertHasFix('''
import 'dart:async';

import 'a.dart';
import 'a/b.dart';

void f(Stream<String> args) {
  A.m();
  B.m();
}
''');
  }

  Future<void> test_organizePathImports_thatSpanTwoLines() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static void m() {}
}
''');
    newFile('$testPackageLibPath/a/b.dart', '''
class B {
  static void m() {}
}
''');
    newFile('$testPackageLibPath/a/c.dart', '''
class C {
  static void m() {}
}
''');

    await resolveTestCode('''
import 'dart:async';
import 'a/b.dart';
import 'a.dart'
  show A;
import 'a/c.dart';

void f(Stream<String> args) {
  A.m();
  B.m();
  C.m();
}
''');
    await assertHasFix('''
import 'dart:async';

import 'a.dart'
  show A;
import 'a/b.dart';
import 'a/c.dart';

void f(Stream<String> args) {
  A.m();
  B.m();
  C.m();
}
''');
  }

  Future<void> test_removeNameFromCombinator_first() async {
    await resolveTestCode('''
import 'dart:math' show max, Random;

void foo(Random r) {}
''');
    await assertHasFix('''
import 'dart:math' show Random;

void foo(Random r) {}
''');
  }

  Future<void> test_removeNameFromCombinator_last() async {
    await resolveTestCode('''
import 'dart:math' show Random, max;

void foo(Random r) {}
''');
    await assertHasFix('''
import 'dart:math' show Random;

void foo(Random r) {}
''');
  }

  Future<void> test_removeNameFromCombinator_multiple() async {
    await resolveTestCode('''
import 'dart:math' show max, min, Random;

void foo(Random r) {}
''');
    await assertHasFix('''
import 'dart:math' show Random;

void foo(Random r) {}
''', filter: _firstUnusedShownNameErrorFilter);
  }
}
