// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_dart_copy.status_expression;

/**
 * Parse and evaluate expressions in a .status file for Dart and V8.
 * There are set expressions and Boolean expressions in a .status file.
 * The grammar is:
 *   BooleanExpression := $variableName == value | $variableName != value |
 *                        $variableName | (BooleanExpression) |
 *                        BooleanExpression && BooleanExpression |
 *                        BooleanExpression || BooleanExpression
 *
 *   SetExpression := value | (SetExpression) |
 *                    SetExpression || SetExpression |
 *                    SetExpression if BooleanExpression |
 *                    SetExpression , SetExpression
 *
 *  Productions are listed in order of precedence, and the || and , operators
 *  both evaluate to set union, but with different precedence.
 *
 *  Values and variableNames are non-empty strings of word characters, matching
 *  the RegExp \w+.
 *
 *  Expressions evaluate as expected, with values of variables found in
 *  an environment passed to the evaluator.  The SetExpression "value"
 *  evaluates to a singleton set containing that value. "A if B" evaluates
 *  to A if B is true, and to the empty set if B is false.
 */

class ExprEvaluationException {
  String error;

  ExprEvaluationException(this.error);

  toString() => error;
}

class Token {
  static const String LEFT_PAREN = "(";
  static const String RIGHT_PAREN = ")";
  static const String DOLLAR_SYMBOL = r"$";
  static const String UNION = ",";
  static const String EQUALS = "==";
  static const String NOT_EQUALS = "!=";
  static const String AND = "&&";
  static const String OR = "||";
}

class Tokenizer {
  String expression;
  List<String> tokens;

  Tokenizer(String this.expression) : tokens = new List<String>();

  // Tokens are : "(", ")", "$", ",", "&&", "||", "==", "!=", and (maximal) \w+.
  static final testRegexp =
      new RegExp(r"^([()$\w\s,]|(\&\&)|(\|\|)|(\=\=)|(\!\=))+$");
  static final regexp = new RegExp(r"[()$,]|(\&\&)|(\|\|)|(\=\=)|(\!\=)|\w+");

  List<String> tokenize() {
    if (!testRegexp.hasMatch(expression)) {
      throw new FormatException("Syntax error in '$expression'");
    }
    for (Match match in regexp.allMatches(expression)) tokens.add(match[0]);
    return tokens;
  }
}

abstract class BooleanExpression {
  bool evaluate(Map<String, String> environment);
}

abstract class SetExpression {
  Set<String> evaluate(Map<String, String> environment);
}

class Comparison implements BooleanExpression {
  TermVariable left;
  TermConstant right;
  bool negate;

  Comparison(this.left, this.right, this.negate);

  bool evaluate(environment) {
    return negate !=
        (left.termValue(environment) == right.termValue(environment));
  }

  String toString() =>
      "(\$${left.name} ${negate ? '!=' : '=='} ${right.value})";
}

class TermVariable {
  String name;

  TermVariable(this.name);

  String termValue(environment) {
    var value = environment[name];
    if (value == null) {
      throw new ExprEvaluationException("Could not find '$name' in environment "
          "while evaluating status file expression.");
    }
    return value.toString();
  }
}

class TermConstant {
  String value;

  TermConstant(String this.value);

  String termValue(environment) => value;
}

class BooleanVariable implements BooleanExpression {
  TermVariable variable;

  BooleanVariable(this.variable);

  bool evaluate(environment) => variable.termValue(environment) == 'true';
  String toString() => "(bool \$${variable.name})";
}

class BooleanOperation implements BooleanExpression {
  String op;
  BooleanExpression left;
  BooleanExpression right;

  BooleanOperation(this.op, this.left, this.right);

  bool evaluate(environment) => (op == Token.AND)
      ? left.evaluate(environment) && right.evaluate(environment)
      : left.evaluate(environment) || right.evaluate(environment);
  String toString() => "($left $op $right)";
}

class SetUnion implements SetExpression {
  SetExpression left;
  SetExpression right;

  SetUnion(this.left, this.right);

  // Overwrites left.evaluate(env).
  // Set.addAll does not return this.
  Set<String> evaluate(environment) {
    Set<String> result = left.evaluate(environment);
    result.addAll(right.evaluate(environment));
    return result;
  }

  String toString() => "($left || $right)";
}

class SetIf implements SetExpression {
  SetExpression left;
  BooleanExpression right;

  SetIf(this.left, this.right);

  Set<String> evaluate(environment) => right.evaluate(environment)
      ? left.evaluate(environment)
      : new Set<String>();
  String toString() => "($left if $right)";
}

class SetConstant implements SetExpression {
  String value;

  SetConstant(String v) : value = v.toLowerCase();

  Set<String> evaluate(environment) => new Set<String>.from([value]);
  String toString() => value;
}

// An iterator that allows peeking at the current token.
class Scanner {
  List<String> tokens;
  Iterator tokenIterator;
  String current;

  Scanner(this.tokens) {
    tokenIterator = tokens.iterator;
    advance();
  }

  bool hasMore() => current != null;

  void advance() {
    current = tokenIterator.moveNext() ? tokenIterator.current : null;
  }
}

class ExpressionParser {
  Scanner scanner;

  ExpressionParser(this.scanner);

  SetExpression parseSetExpression() => parseSetUnion();

  SetExpression parseSetUnion() {
    SetExpression left = parseSetIf();
    while (scanner.hasMore() && scanner.current == Token.UNION) {
      scanner.advance();
      SetExpression right = parseSetIf();
      left = new SetUnion(left, right);
    }
    return left;
  }

  SetExpression parseSetIf() {
    SetExpression left = parseSetOr();
    while (scanner.hasMore() && scanner.current == "if") {
      scanner.advance();
      BooleanExpression right = parseBooleanExpression();
      left = new SetIf(left, right);
    }
    return left;
  }

  SetExpression parseSetOr() {
    SetExpression left = parseSetAtomic();
    while (scanner.hasMore() && scanner.current == Token.OR) {
      scanner.advance();
      SetExpression right = parseSetAtomic();
      left = new SetUnion(left, right);
    }
    return left;
  }

  SetExpression parseSetAtomic() {
    if (scanner.current == Token.LEFT_PAREN) {
      scanner.advance();
      SetExpression value = parseSetExpression();
      if (scanner.current != Token.RIGHT_PAREN) {
        throw new FormatException("Missing right parenthesis in expression");
      }
      scanner.advance();
      return value;
    }
    if (!new RegExp(r"^\w+$").hasMatch(scanner.current)) {
      throw new FormatException(
          "Expected identifier in expression, got ${scanner.current}");
    }
    SetExpression value = new SetConstant(scanner.current);
    scanner.advance();
    return value;
  }

  BooleanExpression parseBooleanExpression() => parseBooleanOr();

  BooleanExpression parseBooleanOr() {
    BooleanExpression left = parseBooleanAnd();
    while (scanner.hasMore() && scanner.current == Token.OR) {
      scanner.advance();
      BooleanExpression right = parseBooleanAnd();
      left = new BooleanOperation(Token.OR, left, right);
    }
    return left;
  }

  BooleanExpression parseBooleanAnd() {
    BooleanExpression left = parseBooleanAtomic();
    while (scanner.hasMore() && scanner.current == Token.AND) {
      scanner.advance();
      BooleanExpression right = parseBooleanAtomic();
      left = new BooleanOperation(Token.AND, left, right);
    }
    return left;
  }

  BooleanExpression parseBooleanAtomic() {
    if (scanner.current == Token.LEFT_PAREN) {
      scanner.advance();
      BooleanExpression value = parseBooleanExpression();
      if (scanner.current != Token.RIGHT_PAREN) {
        throw new FormatException("Missing right parenthesis in expression");
      }
      scanner.advance();
      return value;
    }

    // The only atomic booleans are of the form $variable == value or
    // of the form $variable.
    if (scanner.current != Token.DOLLAR_SYMBOL) {
      throw new FormatException(
          "Expected \$ in expression, got ${scanner.current}");
    }
    scanner.advance();
    if (!new RegExp(r"^\w+$").hasMatch(scanner.current)) {
      throw new FormatException(
          "Expected identifier in expression, got ${scanner.current}");
    }
    TermVariable left = new TermVariable(scanner.current);
    scanner.advance();
    if (scanner.current == Token.EQUALS ||
        scanner.current == Token.NOT_EQUALS) {
      bool negate = scanner.current == Token.NOT_EQUALS;
      scanner.advance();
      if (!new RegExp(r"^\w+$").hasMatch(scanner.current)) {
        throw new FormatException(
            "Expected value in expression, got ${scanner.current}");
      }
      TermConstant right = new TermConstant(scanner.current);
      scanner.advance();
      return new Comparison(left, right, negate);
    } else {
      return new BooleanVariable(left);
    }
  }
}
