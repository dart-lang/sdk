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
  test_codeSpan() {
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

  test_codeSpan_legacy_blockComment() {
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

  test_codeSpan_unterminated_blockComment() {
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

  test_commentReference_blockComment() {
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

  test_commentReference_multiple_blockComment() {
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

  test_fencedCodeBlock_blockComment() {
    final parseResult = parseStringWithErrors(r'''
/**
 * One.
 * ```
 * a[i] = b[i];
 * ```
 * Two.
 * ```dart
 * code;
 * ```
 * Three.
 */
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /**
 * One.
 * ```
 * a[i] = b[i];
 * ```
 * Two.
 * ```dart
 * code;
 * ```
 * Three.
 */
  fencedCodeBlocks
    MdFencedCodeBlock
      infoString: <empty>
      lines
        MdFencedCodeBlockLine
          offset: 15
          length: 3
        MdFencedCodeBlockLine
          offset: 22
          length: 12
        MdFencedCodeBlockLine
          offset: 38
          length: 3
    MdFencedCodeBlock
      infoString: dart
      lines
        MdFencedCodeBlockLine
          offset: 53
          length: 7
        MdFencedCodeBlockLine
          offset: 64
          length: 5
        MdFencedCodeBlockLine
          offset: 73
          length: 3
''');
  }

  test_fencedCodeBlock_nonDocCommentLines() {
    final parseResult = parseStringWithErrors(r'''
/// One.
/// ```
// This is not part of the doc comment.
/// a[i] = b[i];

/// ```
/// Two.
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// One.
    /// ```
    /// a[i] = b[i];
    /// ```
    /// Two.
  fencedCodeBlocks
    MdFencedCodeBlock
      infoString: <empty>
      lines
        MdFencedCodeBlockLine
          offset: 12
          length: 4
        MdFencedCodeBlockLine
          offset: 60
          length: 13
        MdFencedCodeBlockLine
          offset: 78
          length: 4
''');
  }

  test_fencedCodeBlock_nonTerminating() {
    final parseResult = parseStringWithErrors(r'''
/// One.
/// ```
/// a[i] = b[i];
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// One.
    /// ```
    /// a[i] = b[i];
  fencedCodeBlocks
    MdFencedCodeBlock
      infoString: <empty>
      lines
        MdFencedCodeBlockLine
          offset: 12
          length: 4
        MdFencedCodeBlockLine
          offset: 20
          length: 13
''');
  }

  test_fencedCodeBlocks() {
    final parseResult = parseStringWithErrors(r'''
/// One.
/// ```
/// a[i] = b[i];
/// ```
/// Two.
/// ```dart
/// code;
/// ```
/// Three.
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// One.
    /// ```
    /// a[i] = b[i];
    /// ```
    /// Two.
    /// ```dart
    /// code;
    /// ```
    /// Three.
  fencedCodeBlocks
    MdFencedCodeBlock
      infoString: <empty>
      lines
        MdFencedCodeBlockLine
          offset: 12
          length: 4
        MdFencedCodeBlockLine
          offset: 20
          length: 13
        MdFencedCodeBlockLine
          offset: 37
          length: 4
    MdFencedCodeBlock
      infoString: dart
      lines
        MdFencedCodeBlockLine
          offset: 54
          length: 8
        MdFencedCodeBlockLine
          offset: 66
          length: 6
        MdFencedCodeBlockLine
          offset: 76
          length: 4
''');
  }

  test_indentedCodeBlock_afterBlankLine() {
    final parseResult = parseStringWithErrors(r'''
/// Text.
///
///    a[i] = b[i];
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('Text');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    ///
    ///    a[i] = b[i];
''');
  }

  test_indentedCodeBlock_afterTextLine_notCodeBlock() {
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

  test_indentedCodeBlock_firstLine() {
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

  test_indentedCodeBlock_firstLine_blockComment() {
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
