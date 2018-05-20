// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/util/link.dart';

import '../../scanner/token.dart'
    show
        BeginToken,
        SimpleToken,
        SyntheticStringToken,
        SyntheticToken,
        Token,
        TokenType;

import 'util.dart' show optional;

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

  /// For every `<` in [unbalancedLt] append a synthetic `>`.
  /// Return the first `<`.
  ///
  /// [unbalancedLt] is a collection of `<` without closing `>` in the reverse
  /// order from which they were encountered in the token stream.
  Token balanceLt(final Token beforeLt, Token end, Link<Token> unbalancedLt) {
    assert(optional('<', beforeLt.next));
    assert(unbalancedLt.isNotEmpty);

    BeginToken lt;
    while (unbalancedLt.isNotEmpty) {
      lt = unbalancedLt.head;
      unbalancedLt = unbalancedLt.tail;
      Token next = end.next;
      Token gt;

      if (optional('>', next)) {
        gt = next;
      } else if (optional('>>', next)) {
        gt = new SimpleToken(TokenType.GT, next.charOffset)
          ..setNext(new SimpleToken(TokenType.GT, next.charOffset + 1)
            ..setNext(next.next));
      } else if (optional('>=', next)) {
        gt = new SimpleToken(TokenType.GT, next.charOffset)
          ..setNext(new SimpleToken(TokenType.EQ, next.charOffset + 1)
            ..setNext(next.next));
      } else if (optional('>>=', next)) {
        gt = new SimpleToken(TokenType.GT, next.charOffset)
          ..setNext(new SimpleToken(TokenType.GT, next.charOffset + 1)
            ..setNext(new SimpleToken(TokenType.EQ, next.charOffset + 2)
              ..setNext(next.next)));
      } else {
        gt = new SyntheticToken(TokenType.GT, next.charOffset)..setNext(next);
      }

      lt.endGroup = gt;
      end.setNext(gt);
      end = gt;
    }
    assert(beforeLt.next == lt);
    return lt;
  }

  /// Insert a synthetic identifier after [token] and return the new identifier.
  Token insertSyntheticIdentifier(Token token) {
    Token identifier = new SyntheticStringToken(
        TokenType.IDENTIFIER, '', token.next.charOffset, 0)
      ..setNext(token.next);

    // A no-op rewriter could simply return the synthetic identifier here.

    token.setNext(identifier);
    return identifier;
  }

  /// Insert the chain of tokens starting at the [insertedToken] immediately
  /// after the [previousToken]. Return the [previousToken].
  Token insertTokenAfter(Token previousToken, Token insertedToken) {
    Token afterToken = previousToken.next;
    previousToken.setNext(insertedToken);

    Token lastReplacement = _lastTokenInChain(insertedToken);
    lastReplacement.setNext(afterToken);

    return previousToken;
  }

  /// Move [endGroup] (a synthetic `)`, `]`, `}`, or `>` token) after [token]
  /// in the token stream and return [endGroup].
  Token moveSynthetic(Token token, Token endGroup) {
    assert(endGroup.beforeSynthetic != null);

    Token next = token.next;
    endGroup.beforeSynthetic.setNext(endGroup.next);
    token.setNext(endGroup);
    endGroup.setNext(next);
    endGroup.offset = next.offset;
    return endGroup;
  }

  /// Replace the single token immediately following the [previousToken] with
  /// the chain of tokens starting at the [replacementToken]. Return the
  /// [replacementToken].
  Token replaceTokenFollowing(Token previousToken, Token replacementToken) {
    Token replacedToken = previousToken.next;
    previousToken.setNext(replacementToken);

    (replacementToken as SimpleToken).precedingComments =
        replacedToken.precedingComments;

    _lastTokenInChain(replacementToken).setNext(replacedToken.next);

    return replacementToken;
  }

  /// Split a `>>` token into two separate `>` tokens and return the first `>`.
  /// This sets [start].endGroup to the second `>` and updates the token stream,
  /// but does not set the inner group's endGroup.
  Token splitGtGt(BeginToken start) {
    Token gtgt = start.endGroup;
    assert(gtgt != null);
    assert(optional('>>', gtgt));

    // A no-op rewriter could simply return `>>` here.

    Token gt1 =
        new SimpleToken(TokenType.GT, gtgt.charOffset, gtgt.precedingComments);
    Token gt2 = gt1.setNext(new SimpleToken(TokenType.GT, gt1.charOffset + 1));
    gt2.setNext(gtgt.next);

    Token token = start;
    Token next = token.next;
    while (!identical(next, gtgt)) {
      token = next;
      next = token.next;
    }
    token.setNext(gt1);

    start.endGroup = gt2;
    return gt1;
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
