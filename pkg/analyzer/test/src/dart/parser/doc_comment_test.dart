// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocCommentParserTest);
  });
}

@reflectiveTest
class DocCommentParserTest extends ParserDiagnosticsTest {
  test_animationDirective_namedArgument_blankValue() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@animation 600 400 http://google.com arg=}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('animation');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@animation 600 400 http://google.com arg=}
  docDirectives
    SimpleDocDirective
      tag
        offset: [26, 70]
        type: [DocDirectiveType.animation]
        positionalArguments
          600
          400
          http://google.com
        namedArguments
          arg=
''');
  }

  test_animationDirective_namedArgument_missingClosingBrace() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@animation 600 400 http://google.com arg=value
class A {}
''');
    parseResult.assertErrors([
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE, 73, 1),
    ]);

    final node = parseResult.findNode.comment('animation');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@animation 600 400 http://google.com arg=value
  docDirectives
    SimpleDocDirective
      tag
        offset: [26, 74]
        type: [DocDirectiveType.animation]
        positionalArguments
          600
          400
          http://google.com
        namedArguments
          arg=value
''');
  }

  test_animationDirective_namedArgument_missingValueAndClosingBrace() async {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@animation 600 400 http://google.com arg=
class A {}
''');
    parseResult.assertErrors([
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE, 68, 1),
    ]);

    final node = parseResult.findNode.comment('animation');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@animation 600 400 http://google.com arg=
  docDirectives
    SimpleDocDirective
      tag
        offset: [26, 69]
        type: [DocDirectiveType.animation]
        positionalArguments
          600
          400
          http://google.com
        namedArguments
          arg=
''');
  }

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

  test_docImport() {
    final parseResult = parseStringWithErrors(r'''
/// @docImport 'dart:html';
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('docImport');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// @docImport 'dart:html';
  docImports
    DocImport
      offset: 3
      import: ImportDirective
        importKeyword: import
        uri: SimpleStringLiteral
          literal: 'dart:html'
        semicolon: ;
''');
  }

  test_docImport_multiple() {
    final parseResult = parseStringWithErrors(r'''
/// One.
/// @docImport 'dart:html';
/// @docImport 'dart:io';
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('dart:html');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// One.
    /// @docImport 'dart:html';
    /// @docImport 'dart:io';
  docImports
    DocImport
      offset: 12
      import: ImportDirective
        importKeyword: import
        uri: SimpleStringLiteral
          literal: 'dart:html'
        semicolon: ;
    DocImport
      offset: 40
      import: ImportDirective
        importKeyword: import
        uri: SimpleStringLiteral
          literal: 'dart:io'
        semicolon: ;
''');
  }

  test_docImport_nonTerminated() {
    final parseResult = parseStringWithErrors(r'''
/// @docImport 'dart:html'
class A {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 15, 11),
    ]);

    final node = parseResult.findNode.comment('docImport');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// @docImport 'dart:html'
  docImports
    DocImport
      offset: 3
      import: ImportDirective
        importKeyword: import
        uri: SimpleStringLiteral
          literal: 'dart:html'
        semicolon: ; <synthetic>
''');
  }

  test_docImport_parseError() {
    final parseResult = parseStringWithErrors(r'''
/// @docImport html
class A {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 8, 6),
      error(ParserErrorCode.EXPECTED_STRING_LITERAL, 15, 4),
      error(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 15, 4),
      error(ParserErrorCode.EXPECTED_TOKEN, 15, 4),
    ]);

    final node = parseResult.findNode.comment('docImport');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// @docImport html
  docImports
    DocImport
      offset: 3
      import: ImportDirective
        importKeyword: import
        uri: SimpleStringLiteral
          literal: "" <synthetic>
        semicolon: ; <synthetic>
''');
  }

  test_docImport_prefixed() {
    final parseResult = parseStringWithErrors(r'''
/// @docImport 'dart:html' as html;
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('docImport');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// @docImport 'dart:html' as html;
  docImports
    DocImport
      offset: 3
      import: ImportDirective
        importKeyword: import
        uri: SimpleStringLiteral
          literal: 'dart:html'
        asKeyword: as
        prefix: SimpleIdentifier
          token: html
        semicolon: ;
''');
  }

  test_docImport_show() {
    final parseResult = parseStringWithErrors(r'''
/// @docImport 'dart:html' show Element, HtmlElement;
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('docImport');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// @docImport 'dart:html' show Element, HtmlElement;
  docImports
    DocImport
      offset: 3
      import: ImportDirective
        importKeyword: import
        uri: SimpleStringLiteral
          literal: 'dart:html'
        combinators
          ShowCombinator
            keyword: show
            shownNames
              SimpleIdentifier
                token: Element
              SimpleIdentifier
                token: HtmlElement
        semicolon: ;
''');
  }

  test_docImport_unterminatedString() {
    final parseResult = parseStringWithErrors(r'''
/// @docImport 'dart:html;
class A {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 15, 11),
      error(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 17, 1),
    ]);

    final node = parseResult.findNode.comment('docImport');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// @docImport 'dart:html;
  docImports
    DocImport
      offset: 3
      import: ImportDirective
        importKeyword: import
        uri: SimpleStringLiteral
          literal: 'dart:html;' <synthetic>
        semicolon: ; <synthetic>
''');
  }

  test_docImport_withOtherData() {
    final parseResult = parseStringWithErrors(r'''
/// ```dart
/// x;
/// ```
/// @docImport 'dart:html';
/// ```dart
/// y;
/// ```
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('docImport');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// ```dart
    /// x;
    /// ```
    /// @docImport 'dart:html';
    /// ```dart
    /// y;
    /// ```
  codeBlocks
    MdCodeBlock
      infoString: dart
      lines
        MdCodeBlockLine
          offset: 3
          length: 8
        MdCodeBlockLine
          offset: 15
          length: 3
        MdCodeBlockLine
          offset: 22
          length: 4
    MdCodeBlock
      infoString: dart
      lines
        MdCodeBlockLine
          offset: 58
          length: 8
        MdCodeBlockLine
          offset: 70
          length: 3
        MdCodeBlockLine
          offset: 77
          length: 4
  docImports
    DocImport
      offset: 30
      import: ImportDirective
        importKeyword: import
        uri: SimpleStringLiteral
          literal: 'dart:html'
        semicolon: ;
''');
  }

  test_endTemplate_missingOpeningTag() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@endtemplate}
/// More text.
class A {}
''');
    parseResult.assertErrors([
      error(WarningCode.DOC_DIRECTIVE_MISSING_OPENING_TAG, 26, 15),
    ]);

    final node = parseResult.findNode.comment('endtemplate');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@endtemplate}
    /// More text.
  docDirectives
    SimpleDocDirective
      tag
        offset: [26, 41]
        type: [DocDirectiveType.endTemplate]
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
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 15
          length: 3
        MdCodeBlockLine
          offset: 22
          length: 12
        MdCodeBlockLine
          offset: 38
          length: 3
    MdCodeBlock
      infoString: dart
      lines
        MdCodeBlockLine
          offset: 53
          length: 7
        MdCodeBlockLine
          offset: 64
          length: 5
        MdCodeBlockLine
          offset: 73
          length: 3
''');
  }

  test_fencedCodeBlock_empty() {
    final parseResult = parseStringWithErrors(r'''
/// ```
/// ```
/// Text.
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('Text.');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// ```
    /// ```
    /// Text.
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 3
          length: 4
        MdCodeBlockLine
          offset: 11
          length: 4
''');
  }

  test_fencedCodeBlock_leadingSpaces() {
    final parseResult = parseStringWithErrors(r'''
///   ```
///   a[i] = b[i];
///   ```
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    ///   ```
    ///   a[i] = b[i];
    ///   ```
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 3
          length: 6
        MdCodeBlockLine
          offset: 13
          length: 15
        MdCodeBlockLine
          offset: 32
          length: 6
''');
  }

  test_fencedCodeBlock_moreThanThreeBackticks() {
    final parseResult = parseStringWithErrors(r'''
/// ````dart
/// A code block can contain multiple backticks, as long as it is fewer than
/// the amount in the opening:
/// ```
/// `````
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('A code');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// ````dart
    /// A code block can contain multiple backticks, as long as it is fewer than
    /// the amount in the opening:
    /// ```
    /// `````
  codeBlocks
    MdCodeBlock
      infoString: dart
      lines
        MdCodeBlockLine
          offset: 3
          length: 9
        MdCodeBlockLine
          offset: 16
          length: 73
        MdCodeBlockLine
          offset: 93
          length: 27
        MdCodeBlockLine
          offset: 124
          length: 4
        MdCodeBlockLine
          offset: 132
          length: 6
''');
  }

  test_fencedCodeBlock_noLeadingSpaces() {
    final parseResult = parseStringWithErrors(r'''
///```
///a[i] = b[i];
///```
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    ///```
    ///a[i] = b[i];
    ///```
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 3
          length: 3
        MdCodeBlockLine
          offset: 10
          length: 12
        MdCodeBlockLine
          offset: 26
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
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 12
          length: 4
        MdCodeBlockLine
          offset: 60
          length: 13
        MdCodeBlockLine
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
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 12
          length: 4
        MdCodeBlockLine
          offset: 20
          length: 13
''');
  }

  test_fencedCodeBlock_nonZeroOffset() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// One.
/// ```
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
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 24
          length: 4
        MdCodeBlockLine
          offset: 32
          length: 13
        MdCodeBlockLine
          offset: 49
          length: 4
''');
  }

  test_fencedCodeBlock_precededByText() {
    final parseResult = parseStringWithErrors(r'''
/// One. ```
/// Two.
/// ```
/// Three.
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('Two.');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// One. ```
    /// Two.
    /// ```
    /// Three.
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 25
          length: 4
        MdCodeBlockLine
          offset: 33
          length: 7
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
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 12
          length: 4
        MdCodeBlockLine
          offset: 20
          length: 13
        MdCodeBlockLine
          offset: 37
          length: 4
    MdCodeBlock
      infoString: dart
      lines
        MdCodeBlockLine
          offset: 54
          length: 8
        MdCodeBlockLine
          offset: 66
          length: 6
        MdCodeBlockLine
          offset: 76
          length: 4
''');
  }

  test_hideConstantImplementations() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@hideConstantImplementations}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('hideConstantImplementations');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@hideConstantImplementations}
  docDirectives
    SimpleDocDirective
      tag
        offset: [26, 57]
        type: [DocDirectiveType.hideConstantImplementations]
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
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 17
          length: 16
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
    assertParsedNodeText(node, r'''
Comment
  tokens
    ///    a[i] = b[i];
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 3
          length: 16
''');
  }

  test_indentedCodeBlock_firstLine_blockComment() {
    final parseResult = parseStringWithErrors(r'''
/**
 *
 *     a[i] = b[i];
 * [c].
 */
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: c
  tokens
    /**
 *
 *     a[i] = b[i];
 * [c].
 */
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 10
          length: 16
''');
  }

  test_indentedCodeBlock_withFencedCodeBlock() {
    final parseResult = parseStringWithErrors(r'''
/// Text.
///     ```
///     a[i] = b[i];
///     ```
///     More text.
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('Text');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    ///     ```
    ///     a[i] = b[i];
    ///     ```
    ///     More text.
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      lines
        MdCodeBlockLine
          offset: 13
          length: 8
        MdCodeBlockLine
          offset: 25
          length: 17
        MdCodeBlockLine
          offset: 46
          length: 8
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

  test_nodoc_eol() {
    final parseResult = parseStringWithErrors(r'''
/// Text.
///
/// @nodoc
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('Text.');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    ///
    /// @nodoc
  hasNodoc: true
''');
  }

  test_nodoc_more() {
    final parseResult = parseStringWithErrors(r'''
/// Text.
///
/// @nodocxx
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('Text.');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    ///
    /// @nodocxx
''');
  }

  test_nodoc_space() {
    final parseResult = parseStringWithErrors(r'''
/// Text.
///
/// @nodoc This is not super public.
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('Text.');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    ///
    /// @nodoc This is not super public.
  hasNodoc: true
''');
  }

  test_onlyWhitespace() {
    final parseResult = parseStringWithErrors('''
///${"  "}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('  ');
    assertParsedNodeText(node, '''
Comment
  tokens
    ///${"  "}
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

  test_template() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
/// {@endtemplate}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('template name');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@template name}
    /// More text.
    /// {@endtemplate}
  docDirectives
    BlockDocDirective
      openingTag
        offset: [26, 43]
        type: [DocDirectiveType.template]
        positionalArguments
          name
      closingTag
        offset: [62, 77]
        type: [DocDirectiveType.endTemplate]
''');
  }

  test_template_containingInnerTags() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
/// {@example path}
/// {@endtemplate}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('template name');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@template name}
    /// More text.
    /// {@example path}
    /// {@endtemplate}
  docDirectives
    BlockDocDirective
      openingTag
        offset: [26, 43]
        type: [DocDirectiveType.template]
        positionalArguments
          name
      closingTag
        offset: [82, 97]
        type: [DocDirectiveType.endTemplate]
    SimpleDocDirective
      tag
        offset: [62, 78]
        type: [DocDirectiveType.example]
        positionalArguments
          path
''');
  }

  test_template_containingInnerTemplate() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
/// {@template name2}
/// Text three.
/// {@endtemplate}
/// Text four.
/// {@endtemplate}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('template name2');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@template name}
    /// More text.
    /// {@template name2}
    /// Text three.
    /// {@endtemplate}
    /// Text four.
    /// {@endtemplate}
  docDirectives
    BlockDocDirective
      openingTag
        offset: [26, 43]
        type: [DocDirectiveType.template]
        positionalArguments
          name
      closingTag
        offset: [134, 149]
        type: [DocDirectiveType.endTemplate]
    BlockDocDirective
      openingTag
        offset: [62, 80]
        type: [DocDirectiveType.template]
        positionalArguments
          name2
      closingTag
        offset: [100, 115]
        type: [DocDirectiveType.endTemplate]
''');
  }

  test_template_missingClosingTag() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
class A {}
''');
    parseResult.assertErrors([
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_TAG, 26, 17),
    ]);

    final node = parseResult.findNode.comment('template name');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@template name}
    /// More text.
  docDirectives
    BlockDocDirective
      openingTag
        offset: [26, 43]
        type: [DocDirectiveType.template]
        positionalArguments
          name
''');
  }

  test_template_missingClosingTag_multiple() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
/// {@template name2}
/// More text.
class A {}
''');
    parseResult.assertErrors([
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_TAG, 26, 17),
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_TAG, 62, 18),
    ]);

    final node = parseResult.findNode.comment('template name2');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@template name}
    /// More text.
    /// {@template name2}
    /// More text.
  docDirectives
    BlockDocDirective
      openingTag
        offset: [26, 43]
        type: [DocDirectiveType.template]
        positionalArguments
          name
    BlockDocDirective
      openingTag
        offset: [62, 80]
        type: [DocDirectiveType.template]
        positionalArguments
          name2
''');
  }

  test_template_missingClosingTag_withInnerTag() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
/// {@animation 600 400 http://google.com}
class A {}
''');
    parseResult.assertErrors([
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_TAG, 26, 17),
    ]);

    final node = parseResult.findNode.comment('template name');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@template name}
    /// More text.
    /// {@animation 600 400 http://google.com}
  docDirectives
    BlockDocDirective
      openingTag
        offset: [26, 43]
        type: [DocDirectiveType.template]
        positionalArguments
          name
    SimpleDocDirective
      tag
        offset: [62, 101]
        type: [DocDirectiveType.animation]
        positionalArguments
          600
          400
          http://google.com
''');
  }

  test_template_outOfOrderClosingTag() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
/// {@inject-html}
/// HTML.
/// {@endtemplate}
/// {@end-inject-html}
class A {}
''');
    parseResult.assertErrors([
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_TAG, 62, 15),
      error(WarningCode.DOC_DIRECTIVE_MISSING_OPENING_TAG, 110, 19),
    ]);

    final node = parseResult.findNode.comment('template name');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@template name}
    /// More text.
    /// {@inject-html}
    /// HTML.
    /// {@endtemplate}
    /// {@end-inject-html}
  docDirectives
    BlockDocDirective
      openingTag
        offset: [26, 43]
        type: [DocDirectiveType.template]
        positionalArguments
          name
      closingTag
        offset: [91, 106]
        type: [DocDirectiveType.endTemplate]
    BlockDocDirective
      openingTag
        offset: [62, 77]
        type: [DocDirectiveType.injectHtml]
    SimpleDocDirective
      tag
        offset: [110, 129]
        type: [DocDirectiveType.endInjectHtml]
''');
  }

  test_tool_withRestArguments() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@tool snippets one two three}
/// More text.
/// {@end-tool}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('tool snippets');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@tool snippets one two three}
    /// More text.
    /// {@end-tool}
  docDirectives
    BlockDocDirective
      openingTag
        offset: [26, 57]
        type: [DocDirectiveType.tool]
        positionalArguments
          snippets
          one
          two
          three
      closingTag
        offset: [76, 88]
        type: [DocDirectiveType.endTool]
''');
  }

  @FailingTest(reason: 'Not reporting WarningCode.DOC_DIRECTIVE_UNKNOWN yet')
  test_unknownDocDirective() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@yotube 123}
class A {}
''');
    parseResult.assertErrors([
      error(WarningCode.DOC_DIRECTIVE_UNKNOWN, 28, 6),
    ]);

    final node = parseResult.findNode.comment('yotube');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@yotube 123}
''');
  }

  test_youTubeDirective() {
    final parseResult = parseStringWithErrors(r'''
int x = 0;

/// Text.
/// {@youtube 600 400 http://google.com}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('youtube');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@youtube 600 400 http://google.com}
  docDirectives
    SimpleDocDirective
      tag
        offset: [26, 63]
        type: [DocDirectiveType.youtube]
        positionalArguments
          600
          400
          http://google.com
''');
  }

  test_youTubeDirective_missingEndBrace() {
    final parseResult = parseStringWithErrors(r'''
/// {@youtube 600 400 http://google.com
class A {}
''');
    parseResult.assertErrors([
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE, 39, 1),
    ]);

    final node = parseResult.findNode.comment('youtube');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// {@youtube 600 400 http://google.com
  docDirectives
    SimpleDocDirective
      tag
        offset: [4, 40]
        type: [DocDirectiveType.youtube]
        positionalArguments
          600
          400
          http://google.com
''');
  }

  test_youTubeDirective_missingUrl() {
    final parseResult = parseStringWithErrors(r'''
/// {@youtube 600 400}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('youtube');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// {@youtube 600 400}
  docDirectives
    SimpleDocDirective
      tag
        offset: [4, 23]
        type: [DocDirectiveType.youtube]
        positionalArguments
          600
          400
''');
  }

  test_youTubeDirective_missingUrlAndHeight() {
    final parseResult = parseStringWithErrors(r'''
/// {@youtube 600}
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('youtube');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// {@youtube 600}
  docDirectives
    SimpleDocDirective
      tag
        offset: [4, 19]
        type: [DocDirectiveType.youtube]
        positionalArguments
          600
''');
  }

  test_youTubeDirective_missingUrlAndHeightAndWidth() {
    final parseResult = parseStringWithErrors(r'''
/// {@youtube }
class A {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.comment('youtube');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// {@youtube }
  docDirectives
    SimpleDocDirective
      tag
        offset: [4, 16]
        type: [DocDirectiveType.youtube]
''');
  }
}
