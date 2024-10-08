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
    defineReflectiveTests(MoveDocCommentToLibraryDirectiveTest);
  });
}

@reflectiveTest
class MoveDocCommentToLibraryDirectiveTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MOVE_DOC_COMMENT_TO_LIBRARY_DIRECTIVE;

  @override
  String get lintCode => LintNames.dangling_library_doc_comments;

  Future<void> test_commentsAreFirst() async {
    await resolveTestCode('''
// Comment 1.

// Comment 2.

/// Doc comment.
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
// Comment 1.

// Comment 2.

/// Doc comment.
library;

import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void> test_commentsAreFirst_andAnnotations() async {
    await resolveTestCode('''
// Comment 1.

// Comment 2.

@deprecated
/// Doc comment.
import 'dart:async';

void f(Completer c) {}
''');
    // TODO(srawlins): Fix the 4 newlines below; should be 2.
    await assertHasFix('''
// Comment 1.

// Comment 2.

/// Doc comment.
library;



@deprecated
import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void> test_docCommentIsFirst_aboveDeclaration() async {
    await resolveTestCode('''
/// Doc comment.

void f() {}
''');
    await assertHasFix('''
/// Doc comment.
library;

void f() {}
''');
  }

  Future<void> test_docCommentIsFirst_aboveDeclarationWithComment() async {
    await resolveTestCode('''
/// Library comment.

// Regular comment.
class C {}
''');
    await assertHasFix('''
/// Library comment.
library;

// Regular comment.
class C {}
''');
  }

  Future<void> test_docCommentIsFirst_aboveDeclarationWithDocComment() async {
    await resolveTestCode('''
/// Library comment.

/// Class comment.
class C {}
''');
    await assertHasFix('''
/// Library comment.
library;

/// Class comment.
class C {}
''');
  }

  Future<void> test_docCommentIsFirst_aboveDirective() async {
    await resolveTestCode('''
/// Doc comment.
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
/// Doc comment.
library;
import 'dart:async';

void f(Completer c) {}
''');
  }
}
