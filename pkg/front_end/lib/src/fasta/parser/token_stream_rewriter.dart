// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show SimpleToken, Token, TokenType;

/// Provides the capability of inserting tokens into a token stream. This
/// implementation does this by rewriting the previous token to point to the
/// inserted token.
class TokenStreamRewriter {
  // TODO(brianwilkerson):
  //
  // When we get to the point of removing `token.previous`, the plan is to
  // convert this into an interface and provide two implementations.
  //
  // One, used by Fasta, will connect the inserted tokens to the following token
  // without modifying the previous token.
  //
  // The other, used by 'analyzer', will be created with the first token in the
  // stream (actually with the BOF marker at the beginning of the stream). It
  // will be created only when invoking 'analyzer' specific parse methods (in
  // `Parser`), such as
  //
  // Token parseUnitWithRewrite(Token bof) {
  //   rewriter = AnalyzerTokenStreamRewriter(bof);
  //   return parseUnit(bof.next);
  // }
  //

  /// Initialize a newly created re-writer.
  TokenStreamRewriter();

  /// Insert the chain of tokens starting at the [insertedToken] immediately
  /// after the [previousToken]. Return the [previousToken].
  Token insertTokenAfter(Token previousToken, Token insertedToken) {
    Token afterToken = previousToken.next;
    previousToken.next = insertedToken;
    insertedToken.previous = previousToken;

    Token lastReplacement = _lastTokenInChain(insertedToken);
    lastReplacement.next = afterToken;
    afterToken.previous = lastReplacement;

    return previousToken;
  }

  /// Replace the single token immediately following the [previousToken] with
  /// the chain of tokens starting at the [replacementToken]. Return the
  /// [replacementToken].
  Token replaceTokenFollowing(Token previousToken, Token replacementToken) {
    Token replacedToken = previousToken.next;
    previousToken.next = replacementToken;
    replacementToken.previous = previousToken;

    (replacementToken as SimpleToken).precedingComments =
        replacedToken.precedingComments;

    Token lastReplacement = _lastTokenInChain(replacementToken);
    lastReplacement.next = replacedToken.next;
    replacedToken.next.previous = lastReplacement;

    return replacementToken;
  }

  /// Given the [firstToken] in a chain of tokens to be inserted, return the
  /// last token in the chain.
  ///
  /// As a side-effect, this method also ensures that the tokens in the chain
  /// have their `previous` pointers set correctly.
  Token _lastTokenInChain(Token firstToken) {
    Token previous;
    Token current = firstToken;
    while (current.next != null && current.next.type != TokenType.EOF) {
      if (previous != null) {
        current.previous = previous;
      }
      previous = current;
      current = current.next;
    }
    if (previous != null) {
      current.previous = previous;
    }
    return current;
  }
}
