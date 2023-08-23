// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DanglingLibraryDocCommentsTest);
  });
}

@reflectiveTest
class DanglingLibraryDocCommentsTest extends LintRuleTest {
  @override
  String get lintRule => 'dangling_library_doc_comments';

  test_docComment_aboveDeclaration() async {
    await assertDiagnostics(
      r'''
/// Doc comment.

class C {}
''',
      [lint(0, 16)],
    );
  }

  test_docComment_aboveDeclaration_endingInReference() async {
    await assertNoDiagnostics(r'''
/// Doc comment [C]
class C {}
''');
  }

  test_docComment_aboveDeclarationWithAnnotation() async {
    await assertNoDiagnostics(r'''
/// Doc comment.
@deprecated
class C {}
''');
  }

  test_docComment_aboveDeclarationWithDocComment() async {
    await assertDiagnostics(
      r'''
/// Library comment.

/// Class comment.
class C {}
''',
      [lint(0, 20)],
    );
  }

  test_docComment_aboveDeclarationWithOtherComment1() async {
    await assertNoDiagnostics(r'''
/// Doc comment.
// Comment.
class C {}
''');
  }

  test_docComment_aboveDeclarationWithOtherComment2() async {
    await assertDiagnostics(
      r'''
/// Doc comment.

// Comment.
class C {}
''',
      [lint(0, 16)],
    );
  }

  test_docComment_aboveDeclarationWithOtherComment3() async {
    await assertDiagnostics(
      r'''
/// Doc comment.
// Comment.

class C {}
''',
      [lint(0, 16)],
    );
  }

  test_docComment_aboveDeclarationWithOtherComment4() async {
    await assertNoDiagnostics(r'''
/// Doc comment.
// Comment.
/* Comment 2. */
class C {}
''');
  }

  test_docComment_atEndOfFile() async {
    await assertDiagnostics(
      r'''
/// Doc comment with [int].
''',
      [lint(0, 27)],
    );
  }

  test_docComment_atEndOfFile_precededByComment() async {
    await assertDiagnostics(
      r'''
// Copyright something.

/// Doc comment with [int].
''',
      [lint(25, 27)],
    );
  }

  test_docComment_attachedToDeclaration() async {
    await assertNoDiagnostics(r'''
/// Doc comment.
class C {}
''');
  }

  test_docComment_onFirstDirective() async {
    await assertDiagnostics(
      r'''
/// Doc comment.
export 'dart:math';
''',
      [lint(0, 16)],
    );
  }

  test_docComment_onLaterDirective() async {
    await assertNoDiagnostics(r'''
export 'dart:math';
/// Doc comment for some reason.
export 'dart:io';
''');
  }

  test_docComment_onLibraryDirective() async {
    await assertNoDiagnostics(r'''
/// Doc comment.
library l;
''');
  }
}
