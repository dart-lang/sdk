// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
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
  FixKind get kind => DartFixKind.ORGANIZE_IMPORTS;

  @override
  String get lintCode => LintNames.directives_ordering;

  bool Function(Diagnostic diagnostic) get _firstUnusedShownNameErrorFilter {
    var firstError = true;
    return (Diagnostic diagnostic) {
      if (firstError &&
          diagnostic.diagnosticCode == WarningCode.unusedShownName) {
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
''', errorFilter: _firstUnusedShownNameErrorFilter);
  }
}
