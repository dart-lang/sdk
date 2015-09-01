// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.tokens.token_map;

import 'scannerlib.dart' show
    Token;

/**
 * Key class used in [TokenMap] in which the hash code for a token is based
 * on the [charOffset].
 */
class TokenKey {
  final Token token;
  TokenKey(this.token);
  int get hashCode => token.charOffset;
  operator==(other) => other is TokenKey && token == other.token;
}

/// Map of tokens and the first associated comment.
/*
 * This implementation was chosen among several candidates for its space/time
 * efficiency by empirical tests of running dartdoc on dartdoc itself. Time
 * measurements for the use of [Compiler.commentMap]:
 *
 * 1) Using [TokenKey] as key (this class): ~80 msec
 * 2) Using [TokenKey] as key + storing a separate map in each script: ~120 msec
 * 3) Using [Token] as key in a [Map]: ~38000 msec
 * 4) Storing comments is new field in [Token]: ~20 msec
 *    (Abandoned due to the increased memory usage)
 * 5) Storing comments in an [Expando]: ~14000 msec
 * 6) Storing token/comments pairs in a linked list: ~5400 msec
 */
class TokenMap {
  Map<TokenKey,Token> comments = new Map<TokenKey,Token>();

  Token operator[] (Token key) {
    if (key == null) return null;
    return comments[new TokenKey(key)];
  }

  void operator[]= (Token key, Token value) {
    if (key == null) return;
    comments[new TokenKey(key)] = value;
  }
}
