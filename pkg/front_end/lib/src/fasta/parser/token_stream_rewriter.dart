// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/errors.dart';
import 'package:front_end/src/fasta/scanner/token.dart';
import 'package:front_end/src/scanner/token.dart' show Token;

/// Provides the capability of inserting tokens into a token stream by rewriting
/// the previous token to point to the inserted token.
///
/// This class has been designed to take advantage of "previousToken" pointers
/// when they are present, but not to depend on them.  When they are not
/// present, it uses heuristics to try to find the find the previous token as
/// quickly as possible by walking through tokens starting at the start of the
/// file.
class TokenStreamRewriter {
  /// Synthetic token whose "next" pointer points to the first token in the
  /// stream.
  final Token _head;

  /// The token whose "next" pointer was updated in the last call to
  /// [insertTokenBefore].  This can often be used as a starting point to find
  /// the a future insertion point quickly.
  Token _lastPreviousToken;

  /// Creates a [TokenStreamRewriter] which is prepared to rewrite the token
  /// stream whose first token is [firstToken].
  TokenStreamRewriter(Token firstToken)
      : _head =
            firstToken.previous ?? (new SymbolToken.eof(-1)..next = firstToken);

  /// Gets the first token in the stream (which may not be the same token that
  /// was passed to the constructor, if something was inserted before it).
  Token get firstToken => _head.next;

  /// Inserts [newToken] into the token stream just before [insertionPoint], and
  /// fixes up all "next" and "previous" pointers.
  ///
  /// Caller is required to ensure that [insertionPoint] is actually present in
  /// the token stream.
  void insertTokenBefore(Token newToken, Token insertionPoint) {
    Token previous = _findPreviousToken(insertionPoint);
    _lastPreviousToken = previous;
    newToken.next = insertionPoint;
    previous.next = newToken;
    {
      // Note: even though previousToken is deprecated, we need to hook it up in
      // case any uses of it remain.  Once previousToken is removed it should be
      // safe to remove this block of code.
      insertionPoint.previous = newToken;
      newToken.previous = previous;
    }
  }

  /// Finds the token that immediately precedes [target].
  Token _findPreviousToken(Token target) {
    // First see if the target has a previous token pointer.  If it does, then
    // we can find the previous token with no extra effort.  Note: it's ok that
    // we're accessing the deprecated member previousToken here, because we have
    // a fallback if it is not available.  Once previousToken is removed, we can
    // remove the "if" test below, and always use the fallback code.
    if (target.previous != null) {
      return target.previous;
    }

    // Look for the previous token by scanning forward from [lastPreviousToken],
    // if it makes sense to do so.
    if (_lastPreviousToken != null &&
        target.charOffset >= _lastPreviousToken.charOffset) {
      Token previous = _scanForPreviousToken(target, _lastPreviousToken);
      if (previous != null) return previous;
    }

    // Otherwise scan forward from the start of the token stream.
    Token previous = _scanForPreviousToken(target, _head);
    if (previous == null) {
      internalError('Could not find previous token');
    }
    return previous;
  }

  /// Searches for the token that immediately precedes [target], using [pos] as
  /// a starting point.
  ///
  /// Uses heuristics to skip matching `{}`, `[]`, `()`, and `<>` if possible.
  ///
  /// If no such token is found, returns `null`.
  Token _scanForPreviousToken(Token target, Token pos) {
    while (!identical(pos.next, target)) {
      Token nextPos;
      if (pos is BeginGroupToken &&
          pos.endGroup != null &&
          pos.endGroup.charOffset < target.charOffset) {
        nextPos = pos.endGroup;
      } else {
        nextPos = pos.next;
        if (nextPos == null || nextPos.charOffset > target.charOffset) {
          return null;
        }
      }
      pos = nextPos;
    }
    return pos;
  }
}
