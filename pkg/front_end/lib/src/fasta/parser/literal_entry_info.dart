// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../scanner.dart';
import 'identifier_context.dart';
import 'literal_entry_info_impl.dart';
import 'parser.dart';
import 'util.dart';

/// [LiteralEntryInfo] represents steps for processing an entry
/// in a literal list, map, or set. These steps will handle parsing
/// both control flow and spreadable operators, and indicate
/// when the client should parse the literal entry.
///
/// Clients should parse a single entry in a list, set, or map like this:
/// ```
///    LiteralEntryInfo info = computeLiteralEntry(token);
///    while (info != null) {
///      if (info.hasEntry) {
///        ... parse expression (`:` expression)? ...
///        token = lastConsumedToken;
///      } else {
///        token = info.parse(token, parser);
///      }
///      info = info.computeNext(token);
///    }
/// ```
class LiteralEntryInfo {
  /// `true` if an entry should be parsed by the caller
  /// or `false` if this object's [parse] method should be called.
  final bool hasEntry;

  const LiteralEntryInfo(this.hasEntry);

  /// Parse the control flow and spread collection aspects of this entry.
  Token parse(Token token, Parser parser) {
    throw hasEntry
        ? 'Internal Error: should not call parse'
        : 'Internal Error: $runtimeType should implement parse';
  }

  /// Returns the next step when parsing an entry or `null` if none.
  LiteralEntryInfo computeNext(Token token) => null;
}

/// Compute the [LiteralEntryInfo] for the literal list, map, or set entry.
LiteralEntryInfo computeLiteralEntry(Token token) {
  Token next = token.next;
  if (optional('if', next)) {
    return ifCondition;
  } else if (optional('for', next) ||
      (optional('await', next) && optional('for', next.next))) {
    return new ForCondition();
  } else if (optional('...', next) || optional('...?', next)) {
    return spreadOperator;
  }
  return simpleEntry;
}

/// Return `true` if the given [token] should be treated like the start of
/// a literal entry in a list, set, or map for the purposes of recovery.
bool looksLikeLiteralEntry(Token token) =>
    looksLikeExpressionStart(token) ||
    optional('...', token) ||
    optional('...?', token) ||
    optional('if', token) ||
    optional('for', token) ||
    (optional('await', token) && optional('for', token.next));
