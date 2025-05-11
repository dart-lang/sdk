// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../scanner/token.dart';
import 'literal_entry_info.dart';
import 'parser_impl.dart';

/// [ifCondition] is the first step for parsing a literal entry
/// starting with `if` control flow.
const LiteralEntryInfo ifCondition = const IfCondition();

/// [spreadOperator] is the first step for parsing a literal entry
/// preceded by a '...' spread operator.
const LiteralEntryInfo spreadOperator = const SpreadOperator();

/// [nullAwareEntry] is for parsing a null-aware element in a literal list or
/// set, preceded by the `?` null-aware marker, or a null-aware map entry in a
/// map literal, where either the key or the value is preceded by the `?`
/// null-aware marker.
const NullAwareEntry nullAwareEntry = const NullAwareEntry();

/// The first step when processing a `for` control flow collection entry.
class ForCondition extends LiteralEntryInfo {
  bool _inStyle = false;

  ForCondition() : super(hasEntry: false, ifConditionDelta: 0);

  @override
  Token parse(Token token, Parser parser) {
    Token next = token.next!;
    Token? awaitToken;
    if (next.isA(Keyword.AWAIT)) {
      awaitToken = token = next;
      next = token.next!;
    }
    final Token forToken = next;
    assert(forToken.isA(Keyword.FOR));
    parser.listener.beginForControlFlow(awaitToken, forToken);

    ForPartsContext forPartsContext = new ForPartsContext();
    token = parser.parseForLoopPartsStart(
      awaitToken,
      forToken,
      forPartsContext,
    );
    Token? patternKeyword = forPartsContext.patternKeyword;
    if (patternKeyword != null) {
      if (token.next!.isA(TokenType.EQ)) {
        // Process `for ( pattern = expression ; ... ; ... )`
        Token equals = token.next!;
        token = parser.parseExpression(equals);
        parser.listener.handleForInitializerPatternVariableAssignment(
          patternKeyword,
          equals,
        );
        _inStyle = false;
        return parser.parseForLoopPartsRest(token, forToken, awaitToken);
      } else {
        // Process `for ( pattern in expression )`
        assert(token.next!.isA(Keyword.IN));
        _inStyle = true;
        return parser.parseForInLoopPartsRest(
          token,
          awaitToken,
          forToken,
          patternKeyword,
          /* identifier = */ null,
        );
      }
    }
    Token identifier = token.next!;
    token = parser.parseForLoopPartsMid(token, awaitToken, forToken);

    if (token.next!.isA(Keyword.IN) || token.next!.isA(TokenType.COLON)) {
      // Process `for ( ... in ... )`
      _inStyle = true;
      token = parser.parseForInLoopPartsRest(
        token,
        awaitToken,
        forToken,
        /* patternKeyword = */ null,
        identifier,
      );
    } else {
      // Process `for ( ... ; ... ; ... )`
      _inStyle = false;
      token = parser.parseForLoopPartsRest(token, forToken, awaitToken);
    }
    return token;
  }

  @override
  LiteralEntryInfo computeNext(Token token) {
    Token next = token.next!;
    if (next.isA(Keyword.FOR) ||
        (next.isA(Keyword.AWAIT) && next.next!.isA(Keyword.FOR))) {
      return new Nested(
        new ForCondition(),
        _inStyle ? const ForInComplete() : const ForComplete(),
      );
    } else if (next.isA(Keyword.IF)) {
      return new Nested(
        ifCondition,
        _inStyle ? const ForInComplete() : const ForComplete(),
      );
    } else if (next.isA(TokenType.PERIOD_PERIOD_PERIOD) ||
        next.isA(TokenType.PERIOD_PERIOD_PERIOD_QUESTION)) {
      return _inStyle ? const ForInSpread() : const ForSpread();
    } else if (next.isA(TokenType.QUESTION)) {
      return new Nested(
        nullAwareEntry,
        _inStyle ? const ForInComplete() : const ForComplete(),
      );
    }
    return _inStyle ? const ForInEntry() : const ForEntry();
  }
}

/// A step for parsing a spread collection
/// as the "for" control flow's expression.
class ForSpread extends SpreadOperator {
  const ForSpread();

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const ForComplete();
  }
}

/// A step for parsing a spread collection
/// as the "for-in" control flow's expression.
class ForInSpread extends SpreadOperator {
  const ForInSpread();

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const ForInComplete();
  }
}

/// A step for parsing a literal list, set, or map entry
/// as the "for" control flow's expression.
class ForEntry extends LiteralEntryInfo {
  const ForEntry() : super(hasEntry: true, ifConditionDelta: 0);

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const ForComplete();
  }
}

/// A step for parsing a literal list, set, or map entry
/// as the "for-in" control flow's expression.
class ForInEntry extends LiteralEntryInfo {
  const ForInEntry() : super(hasEntry: true, ifConditionDelta: 0);

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const ForInComplete();
  }
}

class ForComplete extends LiteralEntryInfo {
  const ForComplete() : super(hasEntry: false, ifConditionDelta: 0);

  @override
  Token parse(Token token, Parser parser) {
    parser.listener.endForControlFlow(token);
    return token;
  }
}

class ForInComplete extends LiteralEntryInfo {
  const ForInComplete() : super(hasEntry: false, ifConditionDelta: 0);

  @override
  Token parse(Token token, Parser parser) {
    parser.listener.endForInControlFlow(token);
    return token;
  }
}

/// The first step when processing an `if` control flow collection entry.
class IfCondition extends LiteralEntryInfo {
  const IfCondition() : super(hasEntry: false, ifConditionDelta: 1);

  @override
  Token parse(Token token, Parser parser) {
    final Token ifToken = token.next!;
    assert(ifToken.isA(Keyword.IF));
    parser.listener.beginIfControlFlow(ifToken);
    Token result = parser.ensureParenthesizedCondition(
      ifToken,
      allowCase: parser.allowPatterns,
    );
    parser.listener.handleThenControlFlow(result);
    return result;
  }

  @override
  LiteralEntryInfo computeNext(Token token) {
    Token next = token.next!;
    if (next.isA(Keyword.FOR) ||
        (next.isA(Keyword.AWAIT) && next.next!.isA(Keyword.FOR))) {
      return new Nested(new ForCondition(), const IfComplete());
    } else if (next.isA(Keyword.IF)) {
      return new Nested(ifCondition, const IfComplete());
    } else if (next.isA(TokenType.PERIOD_PERIOD_PERIOD) ||
        next.isA(TokenType.PERIOD_PERIOD_PERIOD_QUESTION)) {
      return const IfSpread();
    } else if (next.isA(TokenType.QUESTION)) {
      return new Nested(nullAwareEntry, const IfComplete());
    }
    return const IfEntry();
  }
}

/// A step for parsing a spread collection
/// as the `if` control flow's then-expression.
class IfSpread extends SpreadOperator {
  const IfSpread();

  @override
  LiteralEntryInfo computeNext(Token token) => const IfComplete();
}

/// A step for parsing a literal list, set, or map entry
/// as the `if` control flow's then-expression.
class IfEntry extends LiteralEntryInfo {
  const IfEntry() : super(hasEntry: true, ifConditionDelta: 0);

  @override
  LiteralEntryInfo computeNext(Token token) => const IfComplete();
}

class IfComplete extends LiteralEntryInfo {
  const IfComplete() : super(hasEntry: false, ifConditionDelta: 0);

  @override
  Token parse(Token token, Parser parser) {
    if (!token.next!.isA(Keyword.ELSE)) {
      parser.listener.endIfControlFlow(token);
    }
    return token;
  }

  @override
  LiteralEntryInfo? computeNext(Token token) {
    return token.next!.isA(Keyword.ELSE) ? const IfElse() : null;
  }
}

/// A step for parsing the `else` portion of an `if` control flow.
class IfElse extends LiteralEntryInfo {
  const IfElse() : super(hasEntry: false, ifConditionDelta: -1);

  @override
  Token parse(Token token, Parser parser) {
    Token elseToken = token.next!;
    assert(elseToken.isA(Keyword.ELSE));
    parser.listener.handleElseControlFlow(elseToken);
    return elseToken;
  }

  @override
  LiteralEntryInfo computeNext(Token token) {
    assert(token.isA(Keyword.ELSE));
    Token next = token.next!;
    if (next.isA(Keyword.FOR) ||
        (next.isA(Keyword.AWAIT) && next.next!.isA(Keyword.FOR))) {
      return new Nested(new ForCondition(), const IfElseComplete());
    } else if (next.isA(Keyword.IF)) {
      return new Nested(ifCondition, const IfElseComplete());
    } else if (next.isA(TokenType.PERIOD_PERIOD_PERIOD) ||
        next.isA(TokenType.PERIOD_PERIOD_PERIOD_QUESTION)) {
      return const ElseSpread();
    } else if (next.isA(TokenType.QUESTION)) {
      return new Nested(nullAwareEntry, const IfElseComplete());
    }
    return const ElseEntry();
  }
}

class ElseSpread extends SpreadOperator {
  const ElseSpread();

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const IfElseComplete();
  }
}

class ElseEntry extends LiteralEntryInfo {
  const ElseEntry() : super(hasEntry: true, ifConditionDelta: 0);

  @override
  LiteralEntryInfo computeNext(Token token) {
    return const IfElseComplete();
  }
}

class IfElseComplete extends LiteralEntryInfo {
  const IfElseComplete() : super(hasEntry: false, ifConditionDelta: 0);

  @override
  Token parse(Token token, Parser parser) {
    parser.listener.endIfElseControlFlow(token);
    return token;
  }
}

/// The first step when processing a spread entry.
class SpreadOperator extends LiteralEntryInfo {
  const SpreadOperator() : super(hasEntry: false, ifConditionDelta: 0);

  @override
  Token parse(Token token, Parser parser) {
    final Token operator = token.next!;
    assert(
      operator.isA(TokenType.PERIOD_PERIOD_PERIOD) ||
          operator.isA(TokenType.PERIOD_PERIOD_PERIOD_QUESTION),
    );
    token = parser.parseExpression(operator);
    parser.listener.handleSpreadExpression(operator);
    return token;
  }
}

class Nested extends LiteralEntryInfo {
  LiteralEntryInfo? nestedStep;
  final LiteralEntryInfo lastStep;

  Nested(this.nestedStep, this.lastStep)
    : super(hasEntry: false, ifConditionDelta: 0);

  @override
  bool get hasEntry => nestedStep!.hasEntry;

  @override
  Token parse(Token token, Parser parser) => nestedStep!.parse(token, parser);

  @override
  LiteralEntryInfo computeNext(Token token) {
    nestedStep = nestedStep!.computeNext(token);
    return nestedStep != null ? this : lastStep;
  }
}

class NullAwareEntry extends LiteralEntryInfo {
  const NullAwareEntry() : super(hasEntry: true, ifConditionDelta: 0);
}
