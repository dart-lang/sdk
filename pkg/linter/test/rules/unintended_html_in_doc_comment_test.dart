// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnintendedHtmlInDocCommentTest);
  });
}

@reflectiveTest
class UnintendedHtmlInDocCommentTest extends LintRuleTest {
  @override
  String get lintRule => 'unintended_html_in_doc_comment';

  test_autolink() async {
    await assertNoDiagnostics(r'''
/// <http://foo.bar.baz>
class C {}
''');
  }

  test_codeBlock_fenced() async {
    await assertNoDiagnostics(r'''
/// ```dart
/// List<int>
/// test comment
/// Iterable<bool>
/// ```
class C {}
''');
  }

  test_codeBlock_indented() async {
    await assertNoDiagnostics(r'''
/// Example:
///
///     var x = List<int>();
///
class C {}
''');
  }

  test_codeSpan() async {
    await assertNoDiagnostics(r'''
/// `List<int> <tag>`
class C {}
''');
  }

  test_hangingAngleBracket_left() async {
    await assertNoDiagnostics(r'''
/// n < 12
class C {}
''');
  }

  test_hangingAngleBracket_right() async {
    await assertNoDiagnostics(r'''
/// n > 12
class C {}
''');
  }

  test_notDocComment() async {
    await assertNoDiagnostics(r'''
// List<int> <tag>
class C {}
''');
  }

  test_unintendedHtml() async {
    await assertDiagnostics(r'''
/// Text List<int>.
class C {}
''', [
      lint(13, 5), // <int>
    ]);
  }

  test_unintendedHtml_javaDoc() async {
    await assertDiagnostics(r'''
/** Text List<int>. */
class C {}
''', [
      lint(13, 5), // <int>
    ]);
  }

  test_unintendedHtml_javaDoc_codeSpan() async {
    await assertNoDiagnostics(r'''
/** Text `List<int>`. */
class C {}
''');
  }

  test_unintendedHtml_javaDoc_multiline() async {
    await assertDiagnostics(r'''
/**
 *  Text List<int>.
 */
class C {}
''', [
      lint(17, 5), // <int>
    ]);
  }

  test_unintendedHtml_multipleDocComments() async {
    await assertDiagnostics(r'''
/// Text List.
class A {}

/// Text List<int>.
class C {}
''', [
      lint(40, 5), // <int>
    ]);
  }

  test_unintendedHtml_multipleLines() async {
    await assertDiagnostics(r'''
/// Text List.
/// Text List<int>.
class C {}
''', [
      lint(28, 5), // <int>
    ]);
  }

  test_unintendedHtml_multipleTags() async {
    await assertDiagnostics(r'''
/// <assignment> -> <variable> = <expression>
class C {}
''', [
      lint(4, 12), // <assignment>
      lint(20, 10), // <variable>
      lint(33, 12), // <expression>
    ]);
  }

  test_unintendedHtml_nested() async {
    await assertDiagnostics(r'''
/// Text List<List<int>>.
class C {}
''', [
      // This is how HTML parses the tag, from the first opening angle bracket
      // to the first closing angle bracket.
      lint(13, 10), // <List<int>
    ]);
  }

  test_unintendedHtml_notIdentifier() async {
    await assertDiagnostics(r'''
/// n < 0 || n > 512
class C {}
''', [
      lint(6, 10), // < 0 || n >
    ]);
  }

  test_unintendedHtml_reference() async {
    await assertDiagnostics(r'''
/// Text [List<int>].
class C {}
''', [
      lint(14, 5), // <int>
    ]);
  }

  test_unintendedHtml_spaces() async {
    await assertDiagnostics(r'''
/// Text <your name here>.
class C {}
''', [
      lint(9, 16), // <your name here>
    ]);
  }

  test_validHtmlTag() async {
    await assertNoDiagnostics(r'''
/// <h1> Test. </h1>
class C {}
''');
  }
}
