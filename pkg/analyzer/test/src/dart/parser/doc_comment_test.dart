// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocCommentParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DocCommentParserTest extends ParserDiagnosticsTest {
  test_animationDirective_namedArgument_blankValue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@animation 600 400 http://google.com arg=}
class A {}
''');

    var node = parseResult.findNode.comment('animation');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@animation 600 400 http://google.com arg=value
// [diag.docDirectiveMissingClosingBrace][column 52][length 1] Doc directive is missing a closing curly brace ('}').
class A {}
''');

    var node = parseResult.findNode.comment('animation');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@animation 600 400 http://google.com arg=
// [diag.docDirectiveMissingClosingBrace][column 47][length 1] Doc directive is missing a closing curly brace ('}').
class A {}
''');

    var node = parseResult.findNode.comment('animation');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// `a[i]` and [b].
class A {}
''');

    var node = parseResult.findNode.comment('a[i]');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** [:xxx [a] yyy:] [b] zzz */
class A {}
''');

    var node = parseResult.findNode.comment('[a]');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** `a[i] and [b] */
class A {}
''');

    var node = parseResult.findNode.comment('a[');
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

  void test_commentReference_beforeAbstractClass() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** [String] */ abstract class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    references
      CommentReference
        expression: SimpleIdentifier
          token: String @5
    tokens
      /** [String] */ @0
  abstractKeyword: abstract @16
  classKeyword: class @25
  namePart: NameWithTypeParameters
    typeName: A @31
  body: BlockClassBody
    leftBracket: { @33
    rightBracket: } @34
''', withOffsets: true);
  }

  void test_commentReference_beforeAnnotatedClass() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// See [int] and [String]
/// and [Object].
@Annotation
abstract class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    references
      CommentReference
        expression: SimpleIdentifier
          token: int @9
      CommentReference
        expression: SimpleIdentifier
          token: String @19
      CommentReference
        expression: SimpleIdentifier
          token: Object @36
    tokens
      /// See [int] and [String] @0
      /// and [Object]. @27
  metadata
    Annotation
      atSign: @ @45
      name: SimpleIdentifier
        token: Annotation @46
  abstractKeyword: abstract @57
  classKeyword: class @66
  namePart: NameWithTypeParameters
    typeName: A @72
  body: BlockClassBody
    leftBracket: { @74
    rightBracket: } @75
''', withOffsets: true);
  }

  test_commentReference_blockComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** [a]. */
class A {}
''');

    var node = parseResult.findNode.comment('[a]');
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

  void test_commentReference_complexBeforeClass() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// This dartdoc comment [should] be ignored
@Annotation
/// This dartdoc comment is [included].
// a non dartdoc comment [inbetween]
/// See [int] and [String] but `not [a]`
/// ```
/// This [code] block should be ignored
/// ```
/// and [Object].
abstract class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    references
      CommentReference
        expression: SimpleIdentifier
          token: included @86
      CommentReference
        expression: SimpleIdentifier
          token: int @143
      CommentReference
        expression: SimpleIdentifier
          token: String @153
      CommentReference
        expression: SimpleIdentifier
          token: Object @240
    tokens
      /// This dartdoc comment is [included]. @57
      /// See [int] and [String] but `not [a]` @134
      /// ``` @175
      /// This [code] block should be ignored @183
      /// ``` @223
      /// and [Object]. @231
    codeBlocks
      MdCodeBlock
        infoString: <empty>
        type: CodeBlockType.fenced
        lines
          MdCodeBlockLine
            offset: 178
            length: 4
          MdCodeBlockLine
            offset: 186
            length: 36
          MdCodeBlockLine
            offset: 226
            length: 4
  metadata
    Annotation
      atSign: @ @45
      name: SimpleIdentifier
        token: Annotation @46
  abstractKeyword: abstract @249
  classKeyword: class @258
  namePart: NameWithTypeParameters
    typeName: A @264
  body: BlockClassBody
    leftBracket: { @266
    rightBracket: } @267
''', withOffsets: true);
  }

  test_commentReference_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [].
class A {}
''');

    var node = parseResult.findNode.comment('[]');
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

  test_commentReference_followedByColon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Regarding [a]: it's an A.
class A {}
''');

    var node = parseResult.findNode.comment('[a]');
    assertParsedNodeText(node, r'''
Comment
  references
    CommentReference
      expression: SimpleIdentifier
        token: a
  tokens
    /// Regarding [a]: it's an A.
''');
  }

  test_commentReference_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [a] and [b].
class A {}
''');

    var node = parseResult.findNode.comment('[a]');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** [a] and [b]. */
class A {}
''');

    var node = parseResult.findNode.comment('[a]');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [new a.A].
class B {}
''');

    var node = parseResult.findNode.comment('new');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [new A].
class B {}
''');

    var node = parseResult.findNode.comment('new');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [operator ==].
class A {}
''');

    var node = parseResult.findNode.comment('==');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [Object.operator ==].
class A {}
''');

    var node = parseResult.findNode.comment('==');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [==].
class A {}
''');

    var node = parseResult.findNode.comment('==');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [Object.==].
class A {}
''');

    var node = parseResult.findNode.comment('==');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [a.b].
class A {}
''');

    var node = parseResult.findNode.comment('a.b');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [a].
class A {}
''');

    var node = parseResult.findNode.comment('[a]');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [this].
class A {}
''');

    var node = parseResult.findNode.comment('this');
    // TODO(srawlins): I think there is an intention to parse this as a comment
    // reference.
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// [this].
''');
  }

  test_docImport() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// @docImport 'dart:html';
class A {}
''');

    var node = parseResult.findNode.comment('docImport');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// One.
/// @docImport 'dart:html';
/// @docImport 'dart:io';
class A {}
''');

    var node = parseResult.findNode.comment('dart:html');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// @docImport 'dart:html'
//             ^^^^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
class A {}
''');

    var node = parseResult.findNode.comment('docImport');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// @docImport html
//      ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^
// [diag.expectedStringLiteral] Expected a string literal.
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
class A {}
''');

    var node = parseResult.findNode.comment('docImport');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// @docImport 'dart:html' as html;
class A {}
''');

    var node = parseResult.findNode.comment('docImport');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// @docImport 'dart:html' show Element, HtmlElement;
class A {}
''');

    var node = parseResult.findNode.comment('docImport');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// @docImport 'dart:html;
//             ^^^^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
//               ^
// [diag.unterminatedStringLiteral] Unterminated string literal.
class A {}
''');

    var node = parseResult.findNode.comment('docImport');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// ```dart
/// x;
/// ```
/// @docImport 'dart:html';
/// ```dart
/// y;
/// ```
class A {}
''');

    var node = parseResult.findNode.comment('docImport');
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
      type: CodeBlockType.fenced
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
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@endtemplate}
// [diag.docDirectiveMissingOpeningTag][column 5][length 15] Doc directive is missing an opening tag.
/// More text.
class A {}
''');

    var node = parseResult.findNode.comment('endtemplate');
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

  test_exampleDirective() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@example /path/to/file.dart#region}
class A {}
''');

    var node = parseResult.findNode.comment('example');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@example /path/to/file.dart#region}
  docDirectives
    SimpleDocDirective
      tag
        offset: [26, 63]
        type: [DocDirectiveType.example]
        positionalArguments
          /path/to/file.dart#region
''');
  }

  test_exampleDirective_args() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@example /path/to/file.dart#region lang=dart indent=keep}
class A {}
''');

    var node = parseResult.findNode.comment('example');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@example /path/to/file.dart#region lang=dart indent=keep}
  docDirectives
    SimpleDocDirective
      tag
        offset: [26, 85]
        type: [DocDirectiveType.example]
        positionalArguments
          /path/to/file.dart#region
        namedArguments
          lang=dart
          indent=keep
''');
  }

  test_fencedCodeBlock_blockComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
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

    var node = parseResult.findNode.comment('a[i]');
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
      type: CodeBlockType.fenced
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
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// ```
/// ```
/// Text.
class A {}
''');

    var node = parseResult.findNode.comment('Text.');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// ```
    /// ```
    /// Text.
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
///   ```
///   a[i] = b[i];
///   ```
class A {}
''');

    var node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    ///   ```
    ///   a[i] = b[i];
    ///   ```
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// ````dart
/// A code block can contain multiple backticks, as long as it is fewer than
/// the amount in the opening:
/// ```
/// `````
class A {}
''');

    var node = parseResult.findNode.comment('A code');
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
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
///```
///a[i] = b[i];
///```
class A {}
''');

    var node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    ///```
    ///a[i] = b[i];
    ///```
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// One.
/// ```
// This is not part of the doc comment.
/// a[i] = b[i];

/// ```
/// Two.
class A {}
''');

    var node = parseResult.findNode.comment('a[i]');
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
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// One.
/// ```
/// a[i] = b[i];
class A {}
''');

    var node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// One.
    /// ```
    /// a[i] = b[i];
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// One.
/// ```
/// a[i] = b[i];
/// ```
/// Two.
class A {}
''');

    var node = parseResult.findNode.comment('a[i]');
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
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// One. ```
/// Two.
/// ```
/// Three.
class A {}
''');

    var node = parseResult.findNode.comment('Two.');
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
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
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

    var node = parseResult.findNode.comment('a[i]');
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
      type: CodeBlockType.fenced
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
      type: CodeBlockType.fenced
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

  test_indentedCodeBlock_afterBlankLine() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Text.
///
///    a[i] = b[i];
class A {}
''');

    var node = parseResult.findNode.comment('Text');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    ///
    ///    a[i] = b[i];
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      type: CodeBlockType.indented
      lines
        MdCodeBlockLine
          offset: 17
          length: 16
''');
  }

  test_indentedCodeBlock_afterTextLine_notCodeBlock() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Text.
///    a[i] = b[i];
class A {}
''');

    var node = parseResult.findNode.comment('Text');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
///    a[i] = b[i];
class A {}
''');

    var node = parseResult.findNode.comment('a[i]');
    assertParsedNodeText(node, r'''
Comment
  tokens
    ///    a[i] = b[i];
  codeBlocks
    MdCodeBlock
      infoString: <empty>
      type: CodeBlockType.indented
      lines
        MdCodeBlockLine
          offset: 3
          length: 16
''');
  }

  test_indentedCodeBlock_firstLine_blockComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/**
 *
 *     a[i] = b[i];
 * [c].
 */
class A {}
''');

    var node = parseResult.findNode.comment('a[i]');
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
      type: CodeBlockType.indented
      lines
        MdCodeBlockLine
          offset: 10
          length: 16
''');
  }

  test_indentedCodeBlock_withFencedCodeBlock() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Text.
///     ```
///     a[i] = b[i];
///     ```
///     More text.
class A {}
''');

    var node = parseResult.findNode.comment('Text');
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
      type: CodeBlockType.fenced
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [a](http://www.google.com) [b].
class A {}
''');

    var node = parseResult.findNode.comment('[a]');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [a]: http://www.google.com Google [b]
class A {}
''');

    var node = parseResult.findNode.comment('[a]');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Text.
///
/// @nodoc
class A {}
''');

    var node = parseResult.findNode.comment('Text.');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Text.
///
/// @nodocxx
class A {}
''');

    var node = parseResult.findNode.comment('Text.');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    ///
    /// @nodocxx
''');
  }

  test_nodoc_space() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// Text.
///
/// @nodoc This is not super public.
class A {}
''');

    var node = parseResult.findNode.comment('Text.');
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
    var parseResult = parseTestCodeWithDiagnostics('''
///${"  "}
class A {}
''');

    var node = parseResult.findNode.comment('  ');
    assertParsedNodeText(node, '''
Comment
  tokens
    ///${"  "}
''');
  }

  test_referenceLink() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [a link][c] [b].
class A {}
''');

    var node = parseResult.findNode.comment('[a');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// [a link split across multiple
/// lines][c] [b].
class A {}
''');

    var node = parseResult.findNode.comment('[a');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
/// {@endtemplate}
class A {}
''');

    var node = parseResult.findNode.comment('template name');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
/// {@macro name}
/// {@endtemplate}
class A {}
''');

    var node = parseResult.findNode.comment('template name');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@template name}
    /// More text.
    /// {@macro name}
    /// {@endtemplate}
  docDirectives
    BlockDocDirective
      openingTag
        offset: [26, 43]
        type: [DocDirectiveType.template]
        positionalArguments
          name
      closingTag
        offset: [80, 95]
        type: [DocDirectiveType.endTemplate]
    SimpleDocDirective
      tag
        offset: [62, 76]
        type: [DocDirectiveType.macro]
        positionalArguments
          name
''');
  }

  test_template_containingInnerTemplate() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
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

    var node = parseResult.findNode.comment('template name2');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@template name}
// [diag.docDirectiveMissingClosingTag][column 5][length 17] Doc directive is missing a closing tag.
/// More text.
class A {}
''');

    var node = parseResult.findNode.comment('template name');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@template name}
// [diag.docDirectiveMissingClosingTag][column 5][length 17] Doc directive is missing a closing tag.
/// More text.
/// {@template name2}
// [diag.docDirectiveMissingClosingTag][column 5][length 18] Doc directive is missing a closing tag.
/// More text.
class A {}
''');

    var node = parseResult.findNode.comment('template name2');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@template name}
// [diag.docDirectiveMissingClosingTag][column 5][length 17] Doc directive is missing a closing tag.
/// More text.
/// {@animation 600 400 http://google.com}
class A {}
''');

    var node = parseResult.findNode.comment('template name');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@template name}
/// More text.
/// {@inject-html}
// [diag.docDirectiveMissingClosingTag][column 5][length 15] Doc directive is missing a closing tag.
/// HTML.
/// {@endtemplate}
/// {@end-inject-html}
// [diag.docDirectiveMissingOpeningTag][column 5][length 19] Doc directive is missing an opening tag.
class A {}
''');

    var node = parseResult.findNode.comment('template name');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@tool snippets one two three}
/// More text.
/// {@end-tool}
class A {}
''');

    var node = parseResult.findNode.comment('tool snippets');
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

  test_unknownDocDirective() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@yotube 123}
//    ^^^^^^
// [diag.docDirectiveUnknown] Doc directive 'yotube' is unknown.
class A {}
''');

    var node = parseResult.findNode.comment('yotube');
    assertParsedNodeText(node, r'''
Comment
  tokens
    /// Text.
    /// {@yotube 123}
''');
  }

  test_youTubeDirective() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int x = 0;

/// Text.
/// {@youtube 600 400 http://google.com}
class A {}
''');

    var node = parseResult.findNode.comment('youtube');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// {@youtube 600 400 http://google.com
// [diag.docDirectiveMissingClosingBrace][column 40][length 1] Doc directive is missing a closing curly brace ('}').
class A {}
''');

    var node = parseResult.findNode.comment('youtube');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// {@youtube 600 400}
class A {}
''');

    var node = parseResult.findNode.comment('youtube');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// {@youtube 600}
class A {}
''');

    var node = parseResult.findNode.comment('youtube');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// {@youtube }
class A {}
''');

    var node = parseResult.findNode.comment('youtube');
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
