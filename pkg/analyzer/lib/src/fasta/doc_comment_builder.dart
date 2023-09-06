// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show optional, Parser;
import 'package:_fe_analyzer_shared/src/parser/util.dart'
    show isLetter, isLetterOrDigit, isWhitespace, optional;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show StringToken;
import 'package:_fe_analyzer_shared/src/scanner/token_constants.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';

/// Given a comment reference without a closing `]`, search for a possible
/// place where `]` should be.
int _findCommentReferenceEnd(String comment, int index, int end) {
  // Find the end of the identifier if there is one.
  if (index >= end || !isLetter(comment.codeUnitAt(index))) {
    return index;
  }
  while (index < end && isLetterOrDigit(comment.codeUnitAt(index))) {
    ++index;
  }

  // Check for a trailing `.`.
  if (index >= end || comment.codeUnitAt(index) != 0x2E /* `.` */) {
    return index;
  }
  ++index;

  // Find end of the identifier after the `.`.
  if (index >= end || !isLetter(comment.codeUnitAt(index))) {
    return index;
  }
  ++index;
  while (index < end && isLetterOrDigit(comment.codeUnitAt(index))) {
    ++index;
  }
  return index;
}

/// Given that we have just found bracketed text within the given [comment],
/// looks to see whether that text is (a) followed by a parenthesized link
/// address, (b) followed by a colon, or (c) followed by optional whitespace
/// and another square bracket.
///
/// [rightIndex] is the index of the right bracket. Return `true` if the
/// bracketed text is followed by a link address.
///
/// This method uses the syntax described by the
/// <a href="http://daringfireball.net/projects/markdown/syntax">markdown</a>
/// project.
bool _isLinkText(String comment, int rightIndex) {
  var length = comment.length;
  var index = rightIndex + 1;
  if (index >= length) {
    return false;
  }
  var ch = comment.codeUnitAt(index);
  if (ch == 0x28 || ch == 0x3A) {
    return true;
  }
  while (isWhitespace(ch)) {
    index = index + 1;
    if (index >= length) {
      return false;
    }
    ch = comment.codeUnitAt(index);
  }
  return ch == 0x5B;
}

/// A class which temporarily stores data for a [CommentType.DOCUMENTATION]-type
/// [Comment], which is ultimately built with [build].
class DocCommentBuilder {
  final Parser _parser;
  final ErrorReporter? _errorReporter;
  final Uri _uri;
  final FeatureSet _featureSet;
  final LineInfo _lineInfo;
  final List<CommentReferenceImpl> _references = [];
  final List<MdCodeBlock> _codeBlocks = [];
  final List<DocImport> _docImports = [];
  final List<DocDirective> _docDirectives = [];
  bool _hasNodoc = false;
  final Token _startToken;
  final _CharacterSequence _characterSequence;

  DocCommentBuilder(
    this._parser,
    this._errorReporter,
    this._uri,
    this._featureSet,
    this._lineInfo,
    this._startToken,
  ) : _characterSequence = _CharacterSequence(_startToken);

  CommentImpl build() {
    _parseDocComment();
    var tokens = [_startToken];
    Token? token = _startToken;
    if (token.lexeme.startsWith('///')) {
      token = token.next;
      while (token != null) {
        if (token.lexeme.startsWith('///')) {
          tokens.add(token);
        }
        token = token.next;
      }
    }
    return CommentImpl(
      tokens: tokens,
      type: CommentType.DOCUMENTATION,
      references: _references,
      codeBlocks: _codeBlocks,
      docImports: _docImports,
      docDirectives: _docDirectives,
      hasNodoc: _hasNodoc,
    );
  }

  /// Determines if [content] can represent a fenced codeblock delimiter
  /// (opening or closing) (starts with optional whitespace, then at least three
  /// backticks).
  ///
  /// Returns the index of the three backticks.
  int _fencedCodeBlockDelimiter(String content, {int minimumTickCount = 3}) {
    if (content.isEmpty) return -1;
    var index = _readWhitespace(content);

    var length = content.length;
    if (index + 3 > length) {
      return -1;
    }
    if (content.substring(index, index + 3) == '`' * minimumTickCount) {
      return index;
    } else {
      return -1;
    }
  }

  bool _isRightCurlyBrace(int character) => character == 0x7D /* '}' */;

  /// Parses a documentation comment.
  ///
  /// All parsed data is added to the fields on this builder.
  void _parseDocComment() {
    // Track whether the previous line is empty, in order to correctly parse an
    // indented code block.
    var isPreviousLineEmpty = true;
    var lineInfo = _characterSequence.next();
    while (lineInfo != null) {
      var (:offset, :content) = lineInfo;
      var whitespaceEndIndex = _readWhitespace(content);
      if (isPreviousLineEmpty && whitespaceEndIndex >= 4) {
        lineInfo = _parseIndentedCodeBlock(content);
        if (lineInfo != null) {
          isPreviousLineEmpty = lineInfo.content.isEmpty;
        }
        continue;
      }

      if (_parseFencedCodeBlock(content: content)) {
        isPreviousLineEmpty = false;
      } else if (_parseDocDirective(
        index: whitespaceEndIndex,
        content: content,
      )) {
        isPreviousLineEmpty = false;
      } else if (_parseDocImport(index: whitespaceEndIndex, content: content)) {
        isPreviousLineEmpty = false;
      } else if (_parseNodoc(index: whitespaceEndIndex, content: content)) {
        isPreviousLineEmpty = false;
      } else {
        _parseDocCommentLine(offset, content);
        isPreviousLineEmpty = content.isEmpty;
      }
      lineInfo = _characterSequence.next();
    }
  }

  /// Parses the comment references in [content] which starts at [offset].
  void _parseDocCommentLine(int offset, String content) {
    var index = 0;
    final end = content.length;
    while (index < end) {
      final ch = content.codeUnitAt(index);
      if (ch == 0x5B /* `[` */) {
        ++index;
        if (index < end && content.codeUnitAt(index) == 0x3A /* `:` */) {
          // Skip old-style code block.
          index = content.indexOf(':]', index + 1) + 1;
          if (index == 0 || index > end) {
            break;
          }
        } else {
          var referenceStart = index;
          index = content.indexOf(']', index);
          if (index == -1 || index >= end) {
            // Recovery: terminating ']' is not typed yet.
            index = _findCommentReferenceEnd(content, referenceStart, end);
          }
          if (ch != 0x27 /* `'` */ && ch != 0x22 /* `"` */) {
            if (_isLinkText(content, index)) {
              // TODO(brianwilkerson) Handle the case where there's a library
              // URI in the link text.
            } else {
              final reference = _parseOneCommentReference(
                content.substring(referenceStart, index),
                offset + referenceStart,
              );
              if (reference != null) {
                _references.add(reference);
              }
            }
          }
        }
      } else if (ch == 0x60 /* '`' */) {
        // Skip inline code block if there is both starting '`' and ending '`'.
        final endCodeBlock = content.indexOf('`', index + 1);
        if (endCodeBlock != -1 && endCodeBlock < end) {
          index = endCodeBlock;
        }
      }
      ++index;
    }
  }

  bool _parseDocDirective({required int index, required String content}) {
    const openingLength = '{@'.length;
    if (!content.startsWith('{@', index)) return false;

    var startOffset = _characterSequence._offset + index;
    index += openingLength;

    var length = content.length;
    if (index >= length) return false;
    var nameIndex = index;
    do {
      var character = content.codeUnitAt(index);
      if (isWhitespace(character) || _isRightCurlyBrace(character)) {
        break;
      }
      index++;
    } while (index < length);

    var nameEnd = index;
    index = _readWhitespace(content, index);

    var name = content.substring(nameIndex, nameEnd);
    if (name == 'youtube') {
      _parseYouTubeDirective(
        offset: startOffset,
        nameOffset: _characterSequence._offset + nameIndex,
        nameEnd: _characterSequence._offset + nameEnd,
        index: index,
        content: content,
      );
      return true;
    }
    // TODO(srawlins): Handle other doc directives: animation, api?,
    // canonicalFor?, category, example, image, macro, samples?, subCategory.
    // TODO(srawlins): Handle block doc directives: inject-html, template.
    // TODO(srawlins): Handle unknown (misspelled?) directive.
    return false;
  }

  /// Tries to parse a doc import at the beginning of a line of a doc comment,
  /// returning whether this was successful.
  ///
  /// A doc import begins with `@docImport ` and then can contain any other
  /// legal syntax that a regular Dart import can contain.
  bool _parseDocImport({required int index, required String content}) {
    const docImportLength = '@docImport '.length;
    const importLength = 'import '.length;
    if (!content.startsWith('@docImport ', index)) {
      return false;
    }

    index = _readWhitespace(content, index + docImportLength);
    var syntheticImport = 'import ${content.substring(index)}';

    // TODO(srawlins): Handle multiple lines.
    var sourceMap = [
      (
        offsetInDocImport: 0,
        offsetInUnit: _characterSequence._offset + (index - importLength),
      )
    ];

    var scanner = DocImportStringScanner(
      syntheticImport,
      configuration: ScannerConfiguration(),
      sourceMap: sourceMap,
    );

    var tokens = scanner.tokenize();
    var result = ScannerResult(tokens, scanner.lineStarts, scanner.hasErrors);
    // Fasta pretends there is an additional line at EOF.
    result.lineStarts.removeLast();
    // For compatibility, there is already a first entry in lineStarts.
    result.lineStarts.removeAt(0);

    var token = result.tokens;
    var docImportListener = AstBuilder(
      _errorReporter,
      _uri,
      true /* isFullAst */,
      _featureSet,
      _lineInfo,
    );
    var parser = Parser(docImportListener);
    docImportListener.parser = parser;
    parser.parseUnit(token);

    if (docImportListener.directives.isEmpty) {
      return false;
    }
    var directive = docImportListener.directives.first;

    if (directive is ImportDirectiveImpl) {
      _docImports.add(
        DocImport(offset: _characterSequence._offset, import: directive),
      );
      return true;
    }

    return false;
  }

  /// Parses a fenced code block, starting with [content].
  ///
  /// The backticks of the opening delimiter start at [index].
  ///
  /// When this method returns, [characterSequence] is postioned at the closing
  /// delimiter line (`.next()` must be called to move to the next line).
  bool _parseFencedCodeBlock({
    required String content,
  }) {
    var index = _fencedCodeBlockDelimiter(content);
    if (index == -1) {
      return false;
    }
    var tickCount = 0;
    var length = content.length;
    while (content.codeUnitAt(index) == 0x60 /* '`' */) {
      tickCount++;
      index++;
      if (index >= length) {
        break;
      }
    }

    var infoString =
        index == length ? null : _InfoString.parse(content.substring(index));
    var fencedCodeBlockLines = <MdCodeBlockLine>[
      MdCodeBlockLine(
        offset: _characterSequence._offset,
        length: content.length,
      ),
    ];

    var lineInfo = _characterSequence.next();
    while (lineInfo != null) {
      var (:offset, :content) = lineInfo;
      fencedCodeBlockLines.add(
        MdCodeBlockLine(offset: offset, length: content.length),
      );
      var fencedCodeBlockIndex =
          _fencedCodeBlockDelimiter(content, minimumTickCount: tickCount);
      if (fencedCodeBlockIndex > -1) {
        // End the fenced code block.
        break;
      }
      lineInfo = _characterSequence.next();
    }

    _codeBlocks.add(
      MdCodeBlock(infoString: infoString, lines: fencedCodeBlockLines),
    );
    return true;
  }

  ({int offset, String content})? _parseIndentedCodeBlock(String content) {
    var codeBlockLines = <MdCodeBlockLine>[
      MdCodeBlockLine(
        offset: _characterSequence._offset,
        length: content.length,
      ),
    ];

    var lineInfo = _characterSequence.next();
    while (lineInfo != null) {
      var (:offset, :content) = lineInfo;
      var whitespaceEndIndex = _readWhitespace(content);
      if (whitespaceEndIndex >= 4) {
        codeBlockLines.add(
          MdCodeBlockLine(offset: offset, length: content.length),
        );
      } else {
        // End the code block.
        _codeBlocks.add(
          MdCodeBlock(infoString: null, lines: codeBlockLines),
        );
        return lineInfo;
      }

      lineInfo = _characterSequence.next();
    }

    // The indented code block ends the comment.
    _codeBlocks.add(
      MdCodeBlock(infoString: null, lines: codeBlockLines),
    );
    return lineInfo;
  }

  /// Tries to parse a `@nodoc` doc directive at the beginning of a line of a
  /// doc comment, returning whether this was successful.
  bool _parseNodoc({required int index, required String content}) {
    const nodocLength = '@nodoc'.length;
    if (!content.startsWith('@nodoc', index)) {
      return false;
    }
    if (content.length == index + nodocLength ||
        content.codeUnitAt(index + nodocLength) == 0x20 /* ' ' */) {
      _hasNodoc = true;
      return true;
    }
    return false;
  }

  /// Parses the [source] text, found at [offset] in a single comment reference.
  ///
  /// Returns `null` if the text could not be parsed as a comment reference.
  CommentReferenceImpl? _parseOneCommentReference(String source, int offset) {
    var result = scanString(source);
    if (result.hasErrors) {
      return null;
    }
    var token = result.tokens;
    var begin = token;
    Token? newKeyword;
    if (optional('new', token)) {
      newKeyword = token;
      token = token.next!;
    }
    Token? firstToken, firstPeriod, secondToken, secondPeriod;
    if (token.isIdentifier && optional('.', token.next!)) {
      secondToken = token;
      secondPeriod = token.next!;
      if (secondPeriod.next!.isIdentifier &&
          optional('.', secondPeriod.next!.next!)) {
        firstToken = secondToken;
        firstPeriod = secondPeriod;
        secondToken = secondPeriod.next!;
        secondPeriod = secondToken.next!;
      }
      var identifier = secondPeriod.next!;
      if (identifier.kind == KEYWORD_TOKEN && optional('new', identifier)) {
        // Treat `new` after `.` is as an identifier so that it can represent an
        // unnamed constructor. This support is separate from the
        // constructor-tearoffs feature.
        _parser.rewriter.replaceTokenFollowing(
            secondPeriod,
            StringToken(TokenType.IDENTIFIER, identifier.lexeme,
                identifier.charOffset));
      }
      token = secondPeriod.next!;
    }
    if (token.isEof) {
      // Recovery: Insert a synthetic identifier for code completion
      token = _parser.rewriter.insertSyntheticIdentifier(
          secondPeriod ?? newKeyword ?? _parser.syntheticPreviousToken(token));
      if (begin == token.next!) {
        begin = token;
      }
    }
    Token? operatorKeyword;
    if (optional('operator', token)) {
      operatorKeyword = token;
      token = token.next!;
    }
    if (token.isUserDefinableOperator) {
      if (token.next!.isEof) {
        return _parseOneCommentReferenceRest(
          begin,
          offset,
          newKeyword,
          firstToken,
          firstPeriod,
          secondToken,
          secondPeriod,
          token,
        );
      }
    } else {
      token = operatorKeyword ?? token;
      if (token.next!.isEof) {
        if (token.isIdentifier) {
          return _parseOneCommentReferenceRest(
            begin,
            offset,
            newKeyword,
            firstToken,
            firstPeriod,
            secondToken,
            secondPeriod,
            token,
          );
        }
        var keyword = token.keyword;
        if (newKeyword == null &&
            secondToken == null &&
            (keyword == Keyword.THIS ||
                keyword == Keyword.NULL ||
                keyword == Keyword.TRUE ||
                keyword == Keyword.FALSE)) {
          // TODO(brianwilkerson) If we want to support this we will need to
          // extend the definition of CommentReference to take an expression
          // rather than an identifier. For now we just ignore it to reduce the
          // number of errors produced, but that's probably not a valid long
          // term approach.
        }
      }
    }
    return null;
  }

  /// Parses the parameters into a [CommentReferenceImpl].
  ///
  /// If the reference begins with `new `, then pass the Token associated with
  /// that text as [newToken].
  ///
  /// If the reference contains a single identifier or operator (aside from the
  /// optional [newToken]), then pass the associated Token as
  /// [identifierOrOperator].
  ///
  /// If the reference contains two identifiers separated by a period, then pass
  /// the associated Tokens as [secondToken], [secondPeriod], and
  /// [identifierOrOperator], in lexical order.
  // TODO(srawlins): Rename the parameters or refactor this code to avoid the
  // confusion of `null` values for the "first*" parameters and non-`null`
  // values for the "second*" parameters.
  ///
  /// If the reference contains three identifiers, each separated by a period,
  /// then pass the associated Tokens as [firstToken], [firstPeriod],
  /// [secondToken], [secondPeriod], and [identifierOrOperator].
  CommentReferenceImpl _parseOneCommentReferenceRest(
    Token begin,
    int referenceOffset,
    Token? newKeyword,
    Token? firstToken,
    Token? firstPeriod,
    Token? secondToken,
    Token? secondPeriod,
    Token identifierOrOperator,
  ) {
    // Adjust the token offsets to match the enclosing comment token.
    var token = begin;
    do {
      token.offset += referenceOffset;
      token = token.next!;
    } while (!token.isEof);

    var identifier = SimpleIdentifierImpl(identifierOrOperator);
    if (firstToken != null) {
      var target = PrefixedIdentifierImpl(
        prefix: SimpleIdentifierImpl(firstToken),
        period: firstPeriod!,
        identifier: SimpleIdentifierImpl(secondToken!),
      );
      var expression = PropertyAccessImpl(
        target: target,
        operator: secondPeriod!,
        propertyName: identifier,
      );
      return CommentReferenceImpl(
        newKeyword: newKeyword,
        expression: expression,
      );
    } else if (secondToken != null) {
      var expression = PrefixedIdentifierImpl(
        prefix: SimpleIdentifierImpl(secondToken),
        period: secondPeriod!,
        identifier: identifier,
      );
      return CommentReferenceImpl(
        newKeyword: newKeyword,
        expression: expression,
      );
    } else {
      return CommentReferenceImpl(
        newKeyword: newKeyword,
        expression: identifier,
      );
    }
  }

  /// Parses a YouTube doc directive, returning whether one was successfully
  /// parsed.
  void _parseYouTubeDirective({
    required int offset,
    required int nameOffset,
    required int nameEnd,
    required String content,
    required int index,
  }) {
    var contentOffset = _characterSequence._offset;
    var length = content.length;

    int? end;
    if (index == length) {
      end = offset + index;
    }

    (int?, int?) parseArgument() {
      int? argumentOffset;
      int? argumentEnd;
      if (end == null) {
        if (_isRightCurlyBrace(content.codeUnitAt(index))) {
          index++;
          end = offset + index;
        } else {
          argumentOffset = contentOffset + index;
          index = _readDirectiveArgument(content, index);
          argumentEnd = contentOffset + index;
          index = _readWhitespace(content, index);
        }
      }
      if (end == null && index == length) {
        // We've hit EOL without closing brace.
        end = offset + index;
        _errorReporter?.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE,
          index - 1,
          1,
        );
      }
      return (argumentOffset, argumentEnd);
    }

    var (widthOffset, widthEnd) = parseArgument();
    var (heightOffset, heightEnd) = parseArgument();
    var (urlOffset, urlEnd) = parseArgument();
    if (end == null) {
      // Read until the closing delimiter, `}` is found.
      if (index >= length) {
        // Reached EOL without finding a `}`.
        end = offset + length;
      }
      while (!_isRightCurlyBrace(content.codeUnitAt(index))) {
        index++;
        if (index >= length) {
          // Reached EOL without finding a `}`.
          // TODO(srawlins): Minimal recovery and error-reporting for extra
          // arguments.
          return;
        }
      }
      index++;
      end = offset + index;
    }
    _docDirectives.add(YouTubeDocDirective(
      offset: offset,
      end: end!,
      nameOffset: nameOffset,
      nameEnd: nameEnd,
      widthOffset: widthOffset,
      widthEnd: widthEnd,
      heightOffset: heightOffset,
      heightEnd: heightEnd,
      urlOffset: urlOffset,
      urlEnd: urlEnd,
    ));
  }

  /// Reads past any directive argument text in [content], returning the index
  /// after the last character.
  ///
  /// A directive argument is a sequence of non-whitespace,
  /// non-right-curly-brace characters.
  int _readDirectiveArgument(String content, int index) {
    var length = content.length;
    //if (index >= length) return index;
    while (index < length) {
      var character = content.codeUnitAt(index);
      if (isWhitespace(character)) return index;
      if (_isRightCurlyBrace(character)) return index;
      index++;
    }
    return index;
  }

  /// Reads past any opening whitespace in [content], returning the index after
  /// the last whitespace character.
  int _readWhitespace(String content, [int index = 0]) {
    var length = content.length;
    if (index >= length) return index;
    while (isWhitespace(content.codeUnitAt(index))) {
      index++;
      if (index >= length) {
        return index;
      }
    }
    return index;
  }
}

class DocImportStringScanner extends StringScanner {
  /// A list of offset pairs; each contains an offset in [source], and the
  /// associated offset in the source text from which [source] is derived.
  ///
  /// Always contains a mapping from 0 to the offset of the `@docImport` text.
  ///
  /// Additionally contains a mapping for the start of each new line.
  ///
  /// For example, given the unit text:
  ///
  /// ```dart
  /// int x = 0;
  /// /// Text.
  /// /// @docImport 'dart:math'
  /// // ignore: some_linter_rule
  /// ///     as math
  /// ///     show max;
  /// int y = 0;
  /// ```
  ///
  /// The source map for scanning the doc import will contain the following
  /// pairs:
  ///
  /// * (0, 29) (29 is the offset of the `I` in `@docImport`.)
  /// * (19, 80) (The offsets of the first character in the line with `as`.)
  /// * (31, 96) (The offsets of the first character in the line with `show`.)
  final List<({int offsetInDocImport, int offsetInUnit})> _sourceMap;

  DocImportStringScanner(
    super.source, {
    super.configuration,
    required List<({int offsetInDocImport, int offsetInUnit})> sourceMap,
  }) : _sourceMap = sourceMap;

  @override

  /// The position of the start of the next token _in the unit_, not in
  /// [source].
  ///
  /// This is used for constructing [Token] objects, for a Token's offset.
  int get tokenStart => _toOffsetInUnit(super.tokenStart);

  /// Maps [offset] to the corresponding offset in the unit.
  int _toOffsetInUnit(int offset) {
    for (var index = _sourceMap.length - 1; index > 0; index--) {
      var (:offsetInDocImport, :offsetInUnit) = _sourceMap[index];
      if (offset >= offsetInDocImport) {
        var delta = offset - offsetInDocImport;
        return offsetInUnit + delta;
      }
    }
    var (:offsetInDocImport, :offsetInUnit) = _sourceMap[0];
    var delta = offset - offsetInDocImport;
    return offsetInUnit + delta;
  }
}

/// An abstraction of the character sequences in either a single-line doc
/// comment (which consists of a series of [Token]s) or a multi-line doc comment
/// (which consists of a single [Token]).
abstract class _CharacterSequence {
  factory _CharacterSequence(Token token) {
    final isFromSingleLineComment = token.lexeme.startsWith('///');
    return isFromSingleLineComment
        ? _CharacterSequenceFromSingleLineComment(token)
        : _CharacterSequenceFromMultiLineComment(token);
  }

  /// The current offset in the compilation unit, which is found in [_token].
  int get _offset;

  /// Moves the current position of the doc comment to the next line.
  ///
  /// In a single-line doc comment, this procedure skips past non-doc comment
  /// tokens (comment tokens that do not start with `///`).
  ///
  /// Returns a record with  the current `offset` in the compilation unit, and
  /// the `content` of the current line.
  ({int offset, String content})? next();
}

class _CharacterSequenceFromMultiLineComment implements _CharacterSequence {
  final Token _token;

  @override
  int _offset = -1;

  int _end = -1;

  _CharacterSequenceFromMultiLineComment(this._token);

  @override
  ({int offset, String content})? next() {
    final lexeme = _token.lexeme;
    final tokenOffset = _token.charOffset;

    if (_offset == -1) {
      _offset = tokenOffset;
      var endIndex = lexeme.indexOf('\n');
      if (endIndex == -1) {
        endIndex = lexeme.length;
      }
      _end = tokenOffset + endIndex;
      final indexInLexeme = _offset - tokenOffset;
      return (
        offset: _offset,
        content: lexeme.substring(indexInLexeme, endIndex),
      );
    }

    _offset = _end + 1;
    if (_offset - tokenOffset >= lexeme.length) {
      return null;
    }
    while (isWhitespace(lexeme.codeUnitAt(_offset - tokenOffset))) {
      _offset++;
      if (_offset - tokenOffset >= lexeme.length) {
        return null;
      }
    }

    var endIndex = lexeme.indexOf('\n', _offset - tokenOffset);
    if (endIndex == -1) {
      endIndex = lexeme.length;
    }
    _end = tokenOffset + endIndex;

    const starSpaceLength = '* '.length;
    const starLength = '*'.length;
    if (lexeme.startsWith('* ', _offset - tokenOffset)) {
      _offset += starSpaceLength;
    } else if (_end == _offset + 1 &&
        lexeme.codeUnitAt(_offset - tokenOffset) == 0x2A /* '*' */) {
      _offset += starLength;
    }

    return (
      offset: _offset,
      content: lexeme.substring(_offset - tokenOffset, endIndex),
    );
  }
}

class _CharacterSequenceFromSingleLineComment implements _CharacterSequence {
  Token _token;

  @override
  int _offset = -1;

  _CharacterSequenceFromSingleLineComment(this._token);

  @override
  ({int offset, String content})? next() {
    const threeSlashesLength = '///'.length;
    if (_offset == -1) {
      _offset = _token.charOffset;
      assert(_token.lexeme.startsWith('///'));
    } else {
      do {
        final nextToken = _token.next;
        if (nextToken == null) return null;
        _token = nextToken;
        _offset = nextToken.offset;
      }
      // The sequence of single-line doc comment tokens can contain non-doc
      // comment tokens as well, starting with `//` (but not `///`) or `/*`.
      while (!_token.lexeme.startsWith('///'));
    }

    _offset += threeSlashesLength;

    return (
      offset: _offset,
      content: _token.lexeme.substring(threeSlashesLength),
    );
  }
}

/// A canonicalized store of fenced code block info strings.
///
/// Across many doc comments with many fenced code blocks, there are likely
/// very few info strings (usually the name of a programming language, like
/// 'dart' and 'html').
class _InfoString {
  static final Set<String> _infoStrings = {};

  static String? parse(String text) {
    text = text.trim();
    if (text.isEmpty) {
      return null;
    }
    _infoStrings.add(text);
    return _infoStrings.lookup(text);
  }
}
