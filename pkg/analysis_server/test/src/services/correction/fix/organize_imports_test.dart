// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OrganizeImportsBulkTest);
    defineReflectiveTests(OrganizeImportsTest);
  });
}

@reflectiveTest
class OrganizeImportsBulkTest extends BulkFixProcessorTest {
  Future<void> test_single_file() async {
    await parseTestCode('''
import 'dart:io';
import 'dart:async';

Future a;
''');

    await assertOrganize('''
import 'dart:async';
import 'dart:io';

Future a;
''');
  }
}

@reflectiveTest
class OrganizeImportsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ORGANIZE_IMPORTS;

  @override
  String get lintCode => LintNames.directives_ordering;

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
}
