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
 * Instances of the class `IncrementalScanner` implement a scanner that scans a subset of a
 * string and inserts the resulting tokens into the middle of an existing token stream.
 */
class IncrementalScanner extends Scanner {
  /**
   * The reader used to access the characters in the source.
   */
  CharacterReader _reader;

  /**
   * A map from tokens that were copied to the copies of the tokens.
   */
  TokenMap _tokenMap = new TokenMap();

  /**
   * The token in the new token stream immediately to the left of the range of tokens that were
   * inserted, or the token immediately to the left of the modified region if there were no new
   * tokens.
   */
  Token _leftToken;

  /**
   * The token in the new token stream immediately to the right of the range of tokens that were
   * inserted, or the token immediately to the right of the modified region if there were no new
   * tokens.
   */
  Token _rightToken;

  /**
   * A flag indicating whether there were any tokens changed as a result of the modification.
   */
  bool _hasNonWhitespaceChange = false;

  /**
   * Initialize a newly created scanner.
   *
   * @param source the source being scanned
   * @param reader the character reader used to read the characters in the source
   * @param errorListener the error listener that will be informed of any errors that are found
   */
  IncrementalScanner(Source source, CharacterReader reader,
      AnalysisErrorListener errorListener)
      : super(source, reader, errorListener) {
    this._reader = reader;
  }

  /**
   * Return `true` if there were any tokens either added or removed (or both) as a result of
   * the modification.
   *
   * @return `true` if there were any tokens changed as a result of the modification
   */
  bool get hasNonWhitespaceChange => _hasNonWhitespaceChange;

  /**
   * Return the token in the new token stream immediately to the left of the range of tokens that
   * were inserted, or the token immediately to the left of the modified region if there were no new
   * tokens.
   *
   * @return the token to the left of the inserted tokens
   */
  Token get leftToken => _leftToken;

  /**
   * Return the token in the new token stream immediately to the right of the range of tokens that
   * were inserted, or the token immediately to the right of the modified region if there were no
   * new tokens.
   *
   * @return the token to the right of the inserted tokens
   */
  Token get rightToken => _rightToken;

  /**
   * Return a map from tokens that were copied to the copies of the tokens.
   *
   * @return a map from tokens that were copied to the copies of the tokens
   */
  TokenMap get tokenMap => _tokenMap;

  /**
   * Given the stream of tokens scanned from the original source, the modified source (the result of
   * replacing one contiguous range of characters with another string of characters), and a
   * specification of the modification that was made, return a stream of tokens scanned from the
   * modified source. The original stream of tokens will not be modified.
   *
   * @param originalStream the stream of tokens scanned from the original source
   * @param index the index of the first character in both the original and modified source that was
   *          affected by the modification
   * @param removedLength the number of characters removed from the original source
   * @param insertedLength the number of characters added to the modified source
   */
  Token rescan(Token originalStream, int index, int removedLength,
      int insertedLength) {
    //
    // Copy all of the tokens in the originalStream whose end is less than the
    // replacement start. (If the replacement start is equal to the end of an
    // existing token, then it means that the existing token might have been
    // modified, so we need to rescan it.)
    //
    while (originalStream.type != TokenType.EOF && originalStream.end < index) {
      originalStream = _copyAndAdvance(originalStream, 0);
    }
    Token oldFirst = originalStream;
    Token oldLeftToken = originalStream.previous;
    _leftToken = tail;
    //
    // Skip tokens in the original stream until we find a token whose offset is
    // greater than the end of the removed region. (If the end of the removed
    // region is equal to the beginning of an existing token, then it means that
    // the existing token might have been modified, so we need to rescan it.)
    //
    int removedEnd = index + (removedLength == 0 ? 0 : removedLength - 1);
    while (originalStream.type != TokenType.EOF &&
        originalStream.offset <= removedEnd) {
      originalStream = originalStream.next;
    }
    Token oldLast;
    Token oldRightToken;
    if (originalStream.type != TokenType.EOF &&
        removedEnd + 1 == originalStream.offset) {
      oldLast = originalStream;
      originalStream = originalStream.next;
      oldRightToken = originalStream;
    } else {
      oldLast = originalStream.previous;
      oldRightToken = originalStream;
    }
    //
    // Compute the delta between the character index of characters after the
    // modified region in the original source and the index of the corresponding
    // character in the modified source.
    //
    int delta = insertedLength - removedLength;
    //
    // Compute the range of characters that are known to need to be rescanned.
    // If the index is within an existing token, then we need to start at the
    // beginning of the token.
    //
    int scanStart = math.min(oldFirst.offset, index);
    int oldEnd = oldLast.end + delta - 1;
    int newEnd = index + insertedLength - 1;
    int scanEnd = math.max(newEnd, oldEnd);
    //
    // Starting at the start of the scan region, scan tokens from the
    // modifiedSource until the end of the just scanned token is greater than or
    // equal to end of the scan region in the modified source. Include trailing
    // characters of any token that was split as a result of inserted text,
    // as in "ab" --> "a.b".
    //
    _reader.offset = scanStart - 1;
    int next = _reader.advance();
    while (next != -1 && _reader.offset <= scanEnd) {
      next = bigSwitch(next);
    }
    //
    // Copy the remaining tokens in the original stream, but apply the delta to
    // the token's offset.
    //
    if (originalStream.type == TokenType.EOF) {
      _copyAndAdvance(originalStream, delta);
      _rightToken = tail;
      _rightToken.setNextWithoutSettingPrevious(_rightToken);
    } else {
      originalStream = _copyAndAdvance(originalStream, delta);
      _rightToken = tail;
      while (originalStream.type != TokenType.EOF) {
        originalStream = _copyAndAdvance(originalStream, delta);
      }
      Token eof = _copyAndAdvance(originalStream, delta);
      eof.setNextWithoutSettingPrevious(eof);
    }
    //
    // If the index is immediately after an existing token and the inserted
    // characters did not change that original token, then adjust the leftToken
    // to be the next token. For example, in "a; c;" --> "a;b c;", the leftToken
    // was ";", but this code advances it to "b" since "b" is the first new
    // token.
    //
    Token newFirst = _leftToken.next;
    while (!identical(newFirst, _rightToken) &&
        !identical(oldFirst, oldRightToken) &&
        newFirst.type != TokenType.EOF &&
        _equalTokens(oldFirst, newFirst)) {
      _tokenMap.put(oldFirst, newFirst);
      oldLeftToken = oldFirst;
      oldFirst = oldFirst.next;
      _leftToken = newFirst;
      newFirst = newFirst.next;
    }
    Token newLast = _rightToken.previous;
    while (!identical(newLast, _leftToken) &&
        !identical(oldLast, oldLeftToken) &&
        newLast.type != TokenType.EOF &&
        _equalTokens(oldLast, newLast)) {
      _tokenMap.put(oldLast, newLast);
      oldRightToken = oldLast;
      oldLast = oldLast.previous;
      _rightToken = newLast;
      newLast = newLast.previous;
    }
    _hasNonWhitespaceChange = !identical(_leftToken.next, _rightToken) ||
        !identical(oldLeftToken.next, oldRightToken);
    //
    // TODO(brianwilkerson) Begin tokens are not getting associated with the
    // corresponding end tokens (because the end tokens have not been copied
    // when we're copying the begin tokens). This could have implications for
    // parsing.
    // TODO(brianwilkerson) Update the lineInfo.
    //
    return firstToken;
  }

  Token _copyAndAdvance(Token originalToken, int delta) {
    Token copiedToken = originalToken.copy();
    _tokenMap.put(originalToken, copiedToken);
    copiedToken.offset += delta;
    appendToken(copiedToken);
    Token originalComment = originalToken.precedingComments;
    Token copiedComment = originalToken.precedingComments;
    while (originalComment != null) {
      _tokenMap.put(originalComment, copiedComment);
      originalComment = originalComment.next;
      copiedComment = copiedComment.next;
    }
    return originalToken.next;
  }

  /**
   * Return `true` if the two tokens are equal to each other. For the purposes of the
   * incremental scanner, two tokens are equal if they have the same type and lexeme.
   *
   * @param oldToken the token from the old stream that is being compared
   * @param newToken the token from the new stream that is being compared
   * @return `true` if the two tokens are equal to each other
   */
  bool _equalTokens(Token oldToken, Token newToken) =>
      oldToken.type == newToken.type &&
          oldToken.length == newToken.length &&
          oldToken.lexeme == newToken.lexeme;
}
