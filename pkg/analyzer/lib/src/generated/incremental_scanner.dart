// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.incremental_scanner;

import "dart:math" as math;

import 'error.dart';
import 'scanner.dart';
import 'source.dart';
import 'utilities_collection.dart' show TokenMap;

/**
 * An `IncrementalScanner` is a scanner that scans a subset of a string and
 * inserts the resulting tokens into the middle of an existing token stream.
 */
class IncrementalScanner {
  /**
   * The source being scanned.
   */
  final Source source;

  /**
   * The reader used to access the characters in the source.
   */
  final CharacterReader reader;

  /**
   * The error listener that will be informed of any errors that are found
   * during the scan.
   *
   * TODO(brianwilkerson) Replace this with a list of errors so that we can
   * update the errors.
   */
  final AnalysisErrorListener errorListener;

  /**
   * A map from tokens that were copied to the copies of the tokens.
   */
  TokenMap _tokenMap = new TokenMap();

  /**
   * The token immediately to the left of the range of tokens that were
   * modified.
   */
  Token leftToken;

  /**
   * The token immediately to the right of the range of tokens that were
   * modified.
   */
  Token rightToken;

  /**
   * A flag indicating whether there were any non-comment tokens changed (other
   * than having their position updated) as a result of the modification.
   */
  bool hasNonWhitespaceChange = false;

  /**
   * Initialize a newly created scanner to scan characters within the given
   * [source]. The content of the source can be read using the given [reader].
   * Any errors that are found will be reported to the given [errorListener].
   */
  IncrementalScanner(this.source, this.reader, this.errorListener);

  /**
   * Return a map from tokens that were copied to the copies of the tokens.
   *
   * @return a map from tokens that were copied to the copies of the tokens
   */
  TokenMap get tokenMap => _tokenMap;

  /**
   * Given the [stream] of tokens scanned from the original source, the modified
   * source (the result of replacing one contiguous range of characters with
   * another string of characters), and a specification of the modification that
   * was made, update the token stream to reflect the modified source. Return
   * the first token in the updated token stream.
   *
   * The [stream] is expected to be the first non-EOF token in the token stream.
   *
   * The modification is specified by the [index] of the first character in both
   * the original and modified source that was affected by the modification, the
   * number of characters removed from the original source (the [removedLength])
   * and the number of characters added to the modified source (the
   * [insertedLength]).
   */
  Token rescan(Token stream, int index, int removedLength, int insertedLength) {
    Token leftEof = stream.previous;
    //
    // Compute the delta between the character index of characters after the
    // modified region in the original source and the index of the corresponding
    // character in the modified source.
    //
    int delta = insertedLength - removedLength;
    //
    // Skip past the tokens whose end is less than the replacement start. (If
    // the replacement start is equal to the end of an existing token, then it
    // means that the existing token might have been modified, so we need to
    // rescan it.)
    //
    while (stream.type != TokenType.EOF && stream.end < index) {
      _tokenMap.put(stream, stream);
      stream = stream.next;
    }
    Token oldFirst = stream;
    Token oldLeftToken = stream.previous;
    leftToken = oldLeftToken;
    //
    // Skip past tokens until we find a token whose offset is greater than the
    // end of the removed region. (If the end of the removed region is equal to
    // the beginning of an existing token, then it means that the existing token
    // might have been modified, so we need to rescan it.)
    //
    int removedEnd = index + (removedLength == 0 ? 0 : removedLength - 1);
    while (stream.type != TokenType.EOF && stream.offset <= removedEnd) {
      stream = stream.next;
    }
    //
    // Figure out which region of characters actually needs to be re-scanned.
    //
    Token oldLast;
    Token oldRightToken;
    if (stream.type != TokenType.EOF && removedEnd + 1 == stream.offset) {
      oldLast = stream;
      stream = stream.next;
      oldRightToken = stream;
    } else {
      oldLast = stream.previous;
      oldRightToken = stream;
    }
    //
    // Compute the range of characters that are known to need to be rescanned.
    // If the index is within an existing token, then we need to start at the
    // beginning of the token.
    //
    int scanStart = math.max(oldFirst.previous.end, 0);
    int scanEnd = oldLast.end + delta;
    //
    // Rescan the characters that need to be rescanned.
    //
    Token replacementStart = _scanRange(scanStart, scanEnd);
    oldLeftToken.setNext(replacementStart);
    Token replacementEnd = _findEof(replacementStart).previous;
    replacementEnd.setNext(stream);
    //
    // Apply the delta to the tokens after the last new token.
    //
    _updateOffsets(stream, delta);
    rightToken = stream;
    //
    // If the index is immediately after an existing token and the inserted
    // characters did not change that original token, then adjust the leftToken
    // to be the next token. For example, in "a; c;" --> "a;b c;", the leftToken
    // was ";", but this code advances it to "b" since "b" is the first new
    // token.
    //
    Token newFirst = leftToken.next;
    while (!identical(newFirst, rightToken) &&
        !identical(oldFirst, oldRightToken) &&
        newFirst.type != TokenType.EOF &&
        _equalTokens(oldFirst, newFirst)) {
      _tokenMap.put(oldFirst, newFirst);
      oldLeftToken = oldFirst;
      oldFirst = oldFirst.next;
      leftToken = newFirst;
      newFirst = newFirst.next;
    }
    Token newLast = rightToken.previous;
    while (!identical(newLast, leftToken) &&
        !identical(oldLast, oldLeftToken) &&
        newLast.type != TokenType.EOF &&
        _equalTokens(oldLast, newLast)) {
      _tokenMap.put(oldLast, newLast);
      oldRightToken = oldLast;
      oldLast = oldLast.previous;
      rightToken = newLast;
      newLast = newLast.previous;
    }
    hasNonWhitespaceChange = !identical(leftToken.next, rightToken) ||
        !identical(oldLeftToken.next, oldRightToken);
    //
    // TODO(brianwilkerson) Begin tokens are not getting associated with the
    // corresponding end tokens (because the end tokens have not been copied
    // when we're copying the begin tokens). This could have implications for
    // parsing.
    // TODO(brianwilkerson) Update the lineInfo.
    //
    return leftEof.next;
  }

  /**
   * Return `true` if the [oldToken] and the [newToken] are equal to each other.
   * For the purposes of the incremental scanner, two tokens are equal if they
   * have the same type and lexeme.
   */
  bool _equalTokens(Token oldToken, Token newToken) =>
      oldToken.type == newToken.type &&
          oldToken.length == newToken.length &&
          oldToken.lexeme == newToken.lexeme;

  /**
   * Given a [token], return the EOF token that follows the token.
   */
  Token _findEof(Token token) {
    while (token.type != TokenType.EOF) {
      token = token.next;
    }
    return token;
  }

  /**
   * Scan the token between the [start] (inclusive) and [end] (exclusive)
   * offsets.
   */
  Token _scanRange(int start, int end) {
    Scanner scanner = new Scanner(
        source,
        new CharacterRangeReader(reader, start, end),
        errorListener);
    return scanner.tokenize();
  }

  /**
   * Update the offsets of every token from the given [token] to the end of the
   * stream by adding the given [delta].
   */
  void _updateOffsets(Token token, int delta) {
    while (token.type != TokenType.EOF) {
      _tokenMap.put(token, token);
      token.offset += delta;
      Token comment = token.precedingComments;
      while (comment != null) {
        comment.offset += delta;
        comment = comment.next;
      }
      token = token.next;
    }
    _tokenMap.put(token, token);
    token.offset += delta;
  }
}
