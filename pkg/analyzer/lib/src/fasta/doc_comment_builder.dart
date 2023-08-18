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
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/src/dart/ast/ast.dart';

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
bool isLinkText(String comment, int rightIndex) {
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

/// A class which temporarily stores data for a [CommentType.DOCUMENTATION]-type
/// [Comment], which is ultimately built with [build].
class DocCommentBuilder {
  final Parser parser;
  final List<CommentReferenceImpl> references = [];
  final List<MdFencedCodeBlock> fencedCodeBlocks = [];
  final Token startToken;
  final _CharacterSequence characterSequence;

  DocCommentBuilder(this.parser, this.startToken)
      : characterSequence = _CharacterSequence(startToken);

  CommentImpl build() {
    parseDocComment();
    var tokens = [startToken];
    Token? token = startToken;
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
      references: references,
      fencedCodeBlocks: fencedCodeBlocks,
    );
  }

  /// Parses a documentation comment.
  ///
  /// All parsed data is added to the fields on this builder.
  void parseDocComment() {
    // Track whether the previous line is empty, in order to correctly parse an
    // indented code block.
    var isPreviousLineEmpty = true;
    var lineInfo = characterSequence.next();
    while (lineInfo != null) {
      var (:offset, :content) = lineInfo;

      // TODO(srawlins): This only starts a fenced code block if the first non-
      // whitespace characters are "```". Fix.
      var fencedCodeBlockIndex = content.indexOf('```');
      if (fencedCodeBlockIndex > -1) {
        _parseFencedCodeBlock(
          fencedCodeBlockIndex: fencedCodeBlockIndex,
          content: content,
        );
      } else {
        // TODO(srawlins): I don't think the indented block decision should be
        // different for single-line doc comments vs multi-line. But it might
        // change behavior so... treading lightly.
        var isIndentedCodeBlock = characterSequence._isFromSingleLineComment
            ? isPreviousLineEmpty && content.startsWith('    ')
            : content.startsWith('    ');
        if (!isIndentedCodeBlock) {
          _parseDocCommentLine(offset, content);
        }
        // Mark the previous line as being empty if this function is called with
        // a comment Token derived from a single-line comment Token, and the
        // line is empty.
        isPreviousLineEmpty = content.isEmpty;
      }
      lineInfo = characterSequence.next();
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
            if (isLinkText(content, index)) {
              // TODO(brianwilkerson) Handle the case where there's a library
              // URI in the link text.
            } else {
              final reference = _parseOneCommentReference(
                content.substring(referenceStart, index),
                offset + referenceStart,
              );
              if (reference != null) {
                references.add(reference);
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

  void _parseFencedCodeBlock({
    required int fencedCodeBlockIndex,
    required String content,
  }) {
    String? fencedCodeBlockInfoString =
        content.substring(fencedCodeBlockIndex + '```'.length).trim();
    if (fencedCodeBlockInfoString.isEmpty) {
      fencedCodeBlockInfoString = null;
    }
    var fencedCodeBlockLines = <MdFencedCodeBlockLine>[
      MdFencedCodeBlockLine(
        offset: characterSequence._offset,
        length: content.length,
      ),
    ];

    var lineInfo = characterSequence.next();
    while (lineInfo != null) {
      var (:offset, :content) = lineInfo;

      fencedCodeBlockLines.add(
        MdFencedCodeBlockLine(
          offset: offset,
          length: content.length,
        ),
      );

      var fencedCodeBlockIndex = content.indexOf('```');
      if (fencedCodeBlockIndex > -1) {
        // End the fenced code block.
        fencedCodeBlocks.add(
          MdFencedCodeBlock(
            infoString: fencedCodeBlockInfoString,
            lines: fencedCodeBlockLines,
          ),
        );
        return;
      }

      lineInfo = characterSequence.next();
    }

    // Non-terminating fenced code block.
    fencedCodeBlocks.add(
      MdFencedCodeBlock(
        infoString: fencedCodeBlockInfoString,
        lines: fencedCodeBlockLines,
      ),
    );
    return;
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
        parser.rewriter.replaceTokenFollowing(
            secondPeriod,
            StringToken(TokenType.IDENTIFIER, identifier.lexeme,
                identifier.charOffset));
      }
      token = secondPeriod.next!;
    }
    if (token.isEof) {
      // Recovery: Insert a synthetic identifier for code completion
      token = parser.rewriter.insertSyntheticIdentifier(
          secondPeriod ?? newKeyword ?? parser.syntheticPreviousToken(token));
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

  /// Whether this character sequence is extracted from a single-line doc
  /// comment.
  // TODO(srawlins): This should be unnecessary, but the current implementation
  // requires this knowledge for parsing indented code blocks.
  bool get _isFromSingleLineComment;

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
  bool get _isFromSingleLineComment => false;

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

    if (lexeme.startsWith('* ', _offset - tokenOffset)) {
      _offset += '* '.length;
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
  bool get _isFromSingleLineComment => true;

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
