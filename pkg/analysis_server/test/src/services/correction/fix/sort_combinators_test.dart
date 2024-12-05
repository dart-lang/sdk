// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortCombinatorsBulkTest);
    defineReflectiveTests(SortCombinatorsInFileTest);
    defineReflectiveTests(SortCombinatorsTest);
  });
}

@reflectiveTest
class SortCombinatorsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.combinators_ordering;

  Future<void> test_bulk() async {
    await resolveTestCode('''
import 'dart:io' hide FileSystemEntity, Directory;
import 'dart:math' hide min, max;

File io() => File('');
double math() => pi;
''');
    await assertHasFix('''
import 'dart:io' hide Directory, FileSystemEntity;
import 'dart:math' hide max, min;

File io() => File('');
double math() => pi;
''');
  }
}

@reflectiveTest
class SortCombinatorsInFileTest extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode(r'''
import 'dart:io' hide FileSystemEntity, Directory;
import 'dart:math' hide min, max;

File io() => File('');
double math() => pi;
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
import 'dart:io' hide Directory, FileSystemEntity;
import 'dart:math' hide max, min;

File io() => File('');
double math() => pi;
''');
  }
}

@reflectiveTest
class SortCombinatorsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.SORT_COMBINATORS;

  @override
  String get lintCode => LintNames.combinators_ordering;

  Future<void> test_comment() async {
    await resolveTestCode('''
import 'dart:math' hide min, /* e */ max;

double f() => pi;
''');
    await assertHasFix('''
import 'dart:math' hide max, /* e */ min;

double f() => pi;
''');
  }

  Future<void> test_hide() async {
    await resolveTestCode('''
import 'dart:math' hide min, max;

double f() => pi;
''');
    await assertHasFix('''
import 'dart:math' hide max, min;

double f() => pi;
''');
  }

  Future<void> test_show() async {
    await resolveTestCode('''
import 'dart:math' show min, max;

int f() => max(min(1, 2), 1);
''');
    await assertHasFix('''
import 'dart:math' show max, min;

int f() => max(min(1, 2), 1);
''');
  }
}
