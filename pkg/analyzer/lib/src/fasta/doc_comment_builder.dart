// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show optional, Parser;
import 'package:_fe_analyzer_shared/src/parser/util.dart'
    show isLetter, isLetterOrDigit, isWhitespace, optional;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show DocumentationCommentToken, StringToken;
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

  DocCommentBuilder(this.parser, this.startToken);

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
    // TODO(srawlins): This could be refactored into something more like a
    // proper state machine.
    var fromSingleLine = false;
    var token = startToken;
    if (token.lexeme.startsWith('///')) {
      token = _joinSingleLineDocCommentTokens(token);
      fromSingleLine = true;
    }
    var comment = token.lexeme;
    if (!fromSingleLine) {
      assert(comment.startsWith('/**'));
    }
    var length = comment.length;
    // The offset, from the beginning of [comment], of the start of each line.
    var start = 0;
    // The offset, from the beginning of [comment], of the start of the content
    // of each line.
    var contentStart = 0;
    int? fencedCodeBlockOffset;
    String? fencedCodeBlockInfoString;
    var isPreviousLineEmpty = true;
    var fencedCodeBlockLines = <MdFencedCodeBlockLine>[];
    var possibleFencedCodeBlockIndex = comment.indexOf('```');
    if (possibleFencedCodeBlockIndex == -1) {
      // This indicates that there is no fenced code block before the end of the
      // comment.
      possibleFencedCodeBlockIndex = length;
    }
    while (start < length) {
      if (isWhitespace(comment.codeUnitAt(start))) {
        ++start;
        continue;
      }
      var end = comment.indexOf('\n', start);
      if (end == -1) {
        end = length;
      }
      if (fromSingleLine && !comment.startsWith('///', start)) {
        // This must be a non-doc comment line, like a blank line or a `//`
        // comment.
        start = end + 1;
        continue;
      }
      if (fromSingleLine) {
        contentStart = start + 3;
      } else {
        contentStart =
            comment.startsWith('* ', start) ? start + '* '.length : start;
      }
      if (fencedCodeBlockOffset != null) {
        fencedCodeBlockLines.add(
          MdFencedCodeBlockLine(
            offset: contentStart,
            length: end - contentStart,
          ),
        );
      }
      if (possibleFencedCodeBlockIndex < end) {
        if (fencedCodeBlockOffset == null) {
          // This is the start of a fenced code block.
          fencedCodeBlockOffset =
              token.charOffset + possibleFencedCodeBlockIndex;
          fencedCodeBlockInfoString = comment
              .substring(possibleFencedCodeBlockIndex + '```'.length, end)
              .trim();
          if (fencedCodeBlockInfoString.isEmpty) {
            fencedCodeBlockInfoString = null;
          }
          fencedCodeBlockLines.add(
            MdFencedCodeBlockLine(
              offset: contentStart,
              length: end - contentStart,
            ),
          );
        } else {
          // This ends a fenced code block.
          fencedCodeBlocks.add(
            MdFencedCodeBlock(
              infoString: fencedCodeBlockInfoString,
              lines: fencedCodeBlockLines,
            ),
          );
          fencedCodeBlockOffset = null;
          fencedCodeBlockInfoString = null;
          fencedCodeBlockLines.clear();
        }
        // Set the index of the next fenced code block delimiters.
        possibleFencedCodeBlockIndex = comment.indexOf('```', end);
        if (possibleFencedCodeBlockIndex == -1) {
          possibleFencedCodeBlockIndex = length;
        }
      }
      if (fencedCodeBlockOffset == null) {
        var isIndentedCodeBlock = fromSingleLine
            ? isPreviousLineEmpty && comment.startsWith('///    ', start)
            : comment.startsWith('*     ', start);
        if (!isIndentedCodeBlock) {
          _parseDocCommentLine(token, start, end);
        }
      }
      // Mark the previous line as being empty if this function is called with
      // a comment Token derived from a single-line comment Token, and the
      // line is 3 characters long, which is exactly
      isPreviousLineEmpty =
          fromSingleLine && comment.substring(start, end) == '///';
      start = end + 1;
    }

    // Recover a non-terminating code block.
    if (fencedCodeBlockOffset != null) {
      fencedCodeBlocks.add(
        MdFencedCodeBlock(
          infoString: fencedCodeBlockInfoString,
          lines: fencedCodeBlockLines,
        ),
      );
    }
  }

  /// Joins [startToken] with all of its following tokens.
  ///
  /// This should only be used to parse the contents of the doc comment text.
  Token _joinSingleLineDocCommentTokens(
    Token startToken,
  ) {
    var offset = startToken.offset;
    var buffer = StringBuffer();
    buffer.writeln(startToken.lexeme);
    var end = startToken.end;
    var token = startToken.next;
    while (token != null && !token.isEof) {
      var gap = token.offset - (end + 1);
      buffer.write('\n' * gap);
      buffer.writeln(token.lexeme);
      end = token.end;
      token = token.next;
    }
    return DocumentationCommentToken(
      TokenType.SINGLE_LINE_COMMENT,
      buffer.toString(),
      offset,
    );
  }

  /// Parses the comment references in the text between [start] inclusive
  /// and [end] exclusive.
  void _parseDocCommentLine(
    Token commentToken,
    int start,
    int end,
  ) {
    var comment = commentToken.lexeme;
    var index = start;
    while (index < end) {
      var ch = comment.codeUnitAt(index);
      if (ch == 0x5B /* `[` */) {
        ++index;
        if (index < end && comment.codeUnitAt(index) == 0x3A /* `:` */) {
          // Skip old-style code block.
          index = comment.indexOf(':]', index + 1) + 1;
          if (index == 0 || index > end) {
            break;
          }
        } else {
          var referenceStart = index;
          index = comment.indexOf(']', index);
          if (index == -1 || index >= end) {
            // Recovery: terminating ']' is not typed yet.
            index = _findCommentReferenceEnd(comment, referenceStart, end);
          }
          if (ch != 0x27 /* `'` */ && ch != 0x22 /* `"` */) {
            if (isLinkText(comment, index)) {
              // TODO(brianwilkerson) Handle the case where there's a library
              // URI in the link text.
            } else {
              var reference = _parseOneCommentReference(
                comment.substring(referenceStart, index),
                commentToken.charOffset + referenceStart,
              );
              if (reference != null) {
                references.add(reference);
              }
            }
          }
        }
      } else if (ch == 0x60 /* '`' */) {
        // Skip inline code block if there is both starting '`' and ending '`'.
        var endCodeBlock = comment.indexOf('`', index + 1);
        if (endCodeBlock != -1 && endCodeBlock < end) {
          index = endCodeBlock;
        }
      }
      ++index;
    }
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
