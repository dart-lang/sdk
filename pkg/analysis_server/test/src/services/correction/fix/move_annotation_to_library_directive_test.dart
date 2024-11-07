// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MoveAnnotationToLibraryDirectiveTest);
  });
}

@reflectiveTest
class MoveAnnotationToLibraryDirectiveTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MOVE_ANNOTATION_TO_LIBRARY_DIRECTIVE;

  @override
  String get lintCode => LintNames.library_annotations;

  Future<void> test_existingLibraryDirective() async {
    await resolveTestCode('''
/// Doc comment.
library;
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
/// Doc comment.
@pragma('dart2js:late:trust')
library;
import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void> test_noExistingLibraryDirective_annotationIsFirst() async {
    await resolveTestCode('''
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
@pragma('dart2js:late:trust')
library;

import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void>
  test_noExistingLibraryDirective_annotherAnnotationIsFirst() async {
    await resolveTestCode('''
@deprecated
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
@pragma('dart2js:late:trust')
library;

@deprecated
import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void> test_noExistingLibraryDirective_commentsAreFirst() async {
    await resolveTestCode('''
// Comment 1.

// Comment 2.

@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
// Comment 1.

// Comment 2.

@pragma('dart2js:late:trust')
library;

import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void>
  test_noExistingLibraryDirective_commentsAreFirst_andAnnotations() async {
    await resolveTestCode('''
// Comment 1.

// Comment 2.

@deprecated
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    // TODO(srawlins): Fix the 4 newlines below; should be 2.
    await assertHasFix('''
// Comment 1.

// Comment 2.

@pragma('dart2js:late:trust')
library;



@deprecated
import 'dart:async';

void f(Completer c) {}
''');
  }
}
