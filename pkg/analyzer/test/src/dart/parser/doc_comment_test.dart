// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocCommentParserTest);
  });
}

@reflectiveTest
class DocCommentParserTest extends ParserDiagnosticsTest {
  test_code() {
    final parseResult = parseStringWithErrors(r'''
/// `a[i]` and [b].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    // TODO(srawlins): Parse code into its own node.
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: b
  tokens
    /// `a[i]` and [b].
''');
  }

  test_code_legacy_block() {
    // TODO(srawlins): I believe we should drop support for `[:` `:]`.
    final parseResult = parseStringWithErrors(r'''
/** [:xxx [a] yyy:] [b] zzz */
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[a]');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: b
  tokens
    /** [:xxx [a] yyy:] [b] zzz */
''');
  }

  test_code_unterminated() {
    final parseResult = parseStringWithErrors(r'''
/** `a[i] and [b] */
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: i
    CommentReference
      expression: SimpleIdentifier
        token: b
  tokens
    /** `a[i] and [b] */
''');
  }

  test_codeBlock_backticks() {
    final parseResult = parseStringWithErrors(r'''
/// First.
/// ```dart
/// a[i] = b[i];
/// ```
/// Last.
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    // TODO(srawlins): Parse a backtick code block into its own node.
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// First.
    /// ```dart
    /// a[i] = b[i];
    /// ```
    /// Last.
''');
  }

  test_codeBlock_backticks_block() {
    final parseResult = parseStringWithErrors(r'''
/**
 * First.
 * ```dart
 * a[i] = b[i];
 * ```
 * Last.
 */
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    // TODO(srawlins): Parse a backtick code block into its own node.
    assertParsedNodeText(node, r'''
Comment
  tokens
    /**
 * First.
 * ```dart
 * a[i] = b[i];
 * ```
 * Last.
 */
''');
  }

  test_codeBlock_indented_afterBlankLine() {
    final parseResult = parseStringWithErrors(r'''
/// Text.
///
///    a[i] = b[i];
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('Text');
    // TODO(srawlins): Parse a backtick code block into its own node.
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    ///
    ///    a[i] = b[i];
''');
  }

  test_codeBlock_indented_afterTextLine_notCodeBlock() {
    final parseResult = parseStringWithErrors(r'''
/// Text.
///    a[i] = b[i];
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('Text');
    // TODO(srawlins): Parse an indented code block into its own node.
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: i
    CommentReference
      expression: SimpleIdentifier
        token: i
  tokens
    /// Text.
    ///    a[i] = b[i];
''');
  }

  test_codeBlock_indented_firstLine() {
    final parseResult = parseStringWithErrors(r'''
///    a[i] = b[i];
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    // TODO(srawlins): Parse an indented code block into its own node.
    assertParsedNodeText(node, r'''
Comment
  tokens
    ///    a[i] = b[i];
''');
  }

  test_codeBlock_indented_firstLine_block() {
    final parseResult = parseStringWithErrors(r'''
/**
 *     a[i] = b[i];
 * [c].
 */
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    // TODO(srawlins): Parse an indented code block into its own node.
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: c
  tokens
    /**
 *     a[i] = b[i];
 * [c].
 */
''');
  }

  test_commentReference_block() {
    final parseResult = parseStringWithErrors(r'''
/** [a]. */
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[a]');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: a
  tokens
    /** [a]. */
''');
  }

  test_commentReference_empty() {
    final parseResult = parseStringWithErrors(r'''
/// [].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[]');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: <empty> <synthetic>
  tokens
    /// [].
''');
  }

  test_commentReference_multiple() {
    final parseResult = parseStringWithErrors(r'''
/// [a] and [b].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[a]');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: a
    CommentReference
      expression: SimpleIdentifier
        token: b
  tokens
    /// [a] and [b].
''');
  }

  test_commentReference_multiple_block() {
    final parseResult = parseStringWithErrors(r'''
/** [a] and [b]. */
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[a]');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: a
    CommentReference
      expression: SimpleIdentifier
        token: b
  tokens
    /** [a] and [b]. */
''');
  }

  test_commentReference_new_prefixed() {
    final parseResult = parseStringWithErrors(r'''
/// [new a.A].
class B {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('new');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      newKeyword: new
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: a
        period: .
        identifier: SimpleIdentifier
          token: A
  tokens
    /// [new a.A].
''');
  }

  test_commentReference_new_simple() {
    final parseResult = parseStringWithErrors(r'''
/// [new A].
class B {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('new');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      newKeyword: new
      expression: SimpleIdentifier
        token: A
  tokens
    /// [new A].
''');
  }

  test_commentReference_operator_withKeyword_notPrefixed() {
    final parseResult = parseStringWithErrors(r'''
/// [operator ==].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('==');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: ==
  tokens
    /// [operator ==].
''');
  }

  test_commentReference_operator_withKeyword_prefixed() {
    final parseResult = parseStringWithErrors(r'''
/// [Object.operator ==].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('==');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: Object
        period: .
        identifier: SimpleIdentifier
          token: ==
  tokens
    /// [Object.operator ==].
''');
  }

  test_commentReference_operator_withoutKeyword_notPrefixed() {
    final parseResult = parseStringWithErrors(r'''
/// [==].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('==');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: ==
  tokens
    /// [==].
''');
  }

  test_commentReference_operator_withoutKeyword_prefixed() {
    final parseResult = parseStringWithErrors(r'''
/// [Object.==].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('==');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: Object
        period: .
        identifier: SimpleIdentifier
          token: ==
  tokens
    /// [Object.==].
''');
  }

  test_commentReference_prefixedIdentifier() {
    final parseResult = parseStringWithErrors(r'''
/// [a.b].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a.b');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: a
        period: .
        identifier: SimpleIdentifier
          token: b
  tokens
    /// [a.b].
''');
  }

  test_commentReference_simpleIdentifier() {
    final parseResult = parseStringWithErrors(r'''
/// [a].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[a]');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: a
  tokens
    /// [a].
''');
  }

  test_commentReference_this() {
    final parseResult = parseStringWithErrors(r'''
/// [this].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('this');
    // TODO(srawlins): I think there is an intention to parse this as a comment
    // reference.
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// [this].
''');
  }

  test_inlineLink() {
    final parseResult = parseStringWithErrors(r'''
/// [a](http://www.google.com) [b].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[a]');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: b
  tokens
    /// [a](http://www.google.com) [b].
''');
  }

  test_linkReference() {
    final parseResult = parseStringWithErrors(r'''
/// [a]: http://www.google.com Google [b]
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[a]');
    // TODO(srawlins): Ideally this should not parse `[b]` as a comment
    // reference.
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: b
  tokens
    /// [a]: http://www.google.com Google [b]
''');
  }

  test_referenceLink() {
    final parseResult = parseStringWithErrors(r'''
/// [a link][c] [b].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[a');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: b
  tokens
    /// [a link][c] [b].
''');
  }

  test_referenceLink_multiline() {
    final parseResult = parseStringWithErrors(r'''
/// [a link split across multiple
/// lines][c] [b].
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('[a');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: a
    CommentReference
      expression: SimpleIdentifier
        token: b
  tokens
    /// [a link split across multiple
    /// lines][c] [b].
''');
  }
}
