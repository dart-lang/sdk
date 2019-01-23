// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart';
import '../fasta_codes.dart' show templateUnexpectedToken;
import 'identifier_context.dart';
import 'literal_entry_info.dart';
import 'parser.dart';
import 'util.dart';

/// [forCondition] is the first step for parsing a literal entry
/// starting with the `for` control flow.
const LiteralEntryInfo forCondition = const ForCondition();

/// [ifCondition] is the first step for parsing a literal entry
/// starting with `if` control flow.
const LiteralEntryInfo ifCondition = const IfCondition();

/// [simpleEntry] is the first step for parsing a literal entry
/// without any control flow or spread collection operator.
const LiteralEntryInfo simpleEntry = const LiteralEntryInfo(true);

/// [spreadOperator] is the first step for parsing a literal entry
/// preceded by a '...' spread operator.
const LiteralEntryInfo spreadOperator = const SpreadOperator();

/// The first step when processing a `for` control flow collection entry.
class ForCondition extends LiteralEntryInfo {
  const ForCondition() : super(false);

  @override
  Token parse(Token token, Parser parser) {
    final forToken = token.next;
    assert(optional('for', forToken));
    // TODO(danrubel): implement `for` control flow collection entries
    parser.reportRecoverableErrorWithToken(forToken, templateUnexpectedToken);
    parser.ensureIdentifier(forToken, IdentifierContext.expression);
    return forToken;
  }
}

/// The first step when processing an `if` control flow collection entry.
class IfCondition extends LiteralEntryInfo {
  const IfCondition() : super(false);

  @override
  Token parse(Token token, Parser parser) {
    final ifToken = token.next;
    assert(optional('if', ifToken));
    parser.listener.beginIfControlFlow(ifToken);
    return parser.ensureParenthesizedCondition(ifToken);
  }

  @override
  LiteralEntryInfo computeNext(Token token) {
    Token next = token.next;
    if (optional('...', next) || optional('...?', next)) {
      return const IfSpread();
    }
    // TODO(danrubel): nested control flow structures
    return const IfEntry();
  }
}

/// A step for parsing a spread collection
/// as the `if` control flow's then-expression.
class IfSpread extends SpreadOperator {
  const IfSpread();

  @override
  LiteralEntryInfo computeNext(Token token) {
    // TODO(danrubel): handle `else'
    return const IfComplete();
  }
}

/// A step for parsing a literal list, set, or map entry
/// as the `if` control flow's then-expression.
class IfEntry extends LiteralEntryInfo {
  const IfEntry() : super(true);

  @override
  LiteralEntryInfo computeNext(Token token) {
    // TODO(danrubel): handle `else'
    return const IfComplete();
  }
}

class IfComplete extends LiteralEntryInfo {
  const IfComplete() : super(false);

  @override
  Token parse(Token token, Parser parser) {
    parser.listener.endIfControlFlow(token);
    return token;
  }
}

/// The first step when processing a spread entry.
class SpreadOperator extends LiteralEntryInfo {
  const SpreadOperator() : super(false);

  @override
  Token parse(Token token, Parser parser) {
    final operator = token.next;
    assert(optional('...', operator) || optional('...?', operator));
    token = parser.parseExpression(operator);
    parser.listener.handleSpreadExpression(operator);
    return token;
  }
}
