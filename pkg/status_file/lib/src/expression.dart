// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import '../environment.dart';

/// A parsed Boolean expression AST.
abstract class Expression implements Comparable<Expression> {
  /// Parses Boolean expressions in a .status file for Dart.
  ///
  /// The grammar is:
  ///
  ///     expression := or
  ///     or         := and ( "||" and )*
  ///     and        := primary ( "&&" primary )*
  ///     primary    := "$" identifier ( "==" | "!=" ) identifier |
  ///                   "!"? "$" identifier |
  ///                   "(" expression ")"
  ///     identifier := regex "\w+"
  ///
  /// Expressions evaluate as expected, with values of variables found in an
  /// environment passed to the evaluator.
  static Expression parse(String expression) =>
      new _ExpressionParser(expression).parse();

  /// Validates that this expression does not contain any invalid uses of
  /// variables.
  ///
  /// Ensures that any variable names are known and that any literal values are
  /// allowed for their corresponding variable. If an invalid variable or value
  /// is found, adds appropriate error messages to [errors].
  void validate(Environment environment, List<String> errors);

  /// Evaluates the expression where all variables are defined by the given
  /// [environment].
  bool evaluate(Environment environment);

  /// Produce a "normalized" version of this expression.
  ///
  /// This removes any redundant computation and orders subexpressions in a
  /// well-defined way such that two expressions with the same tree structure
  /// and operands should result in equivalent expressions. It:
  ///
  /// * Simplifies comparisons against boolean literals "true" and "false" to
  ///   the equivalent bare variable forms.
  /// * Sorts the operands to a series of logic operators in a well-defined way.
  ///   (We are free to do this because status expressions are side-effect free
  ///   and don't need to short-circuit).
  /// * Removes duplicate operands to logic operators.
  ///
  /// This does not try to produce a *minimal* expression that calculates the
  /// same truth values as the original expression.
  Expression normalize();

  /// Computes a relative ordering between two expressions or returns zero if
  /// they are exactly identical.
  ///
  /// This is useful for things like sorting lists of expressions or
  /// normalizing a list of subexpressions. The rough logic is that higher
  /// precedence and alphabetically lower expressions come first.
  int compareTo(Expression other) {
    var comparison = _typeComparison.compareTo(other._typeComparison);
    if (comparison != 0) return comparison;

    // They must be the same type.
    return _compareToMyType(other);
  }

  int _compareToMyType(covariant Expression other);

  /// The "precedence" of each expression type when comparing them using
  /// `compareTo()`. Expressions whose type is lower compare earlier.
  int get _typeComparison;
}

/// Keyword token strings.
class _Token {
  static const leftParen = "(";
  static const rightParen = ")";
  static const dollar = r"$";
  static const equals = "==";
  static const notEqual = "!=";
  static const and = "&&";
  static const or = "||";
  static const not = "!";
}

/// A reference to a variable.
class _Variable {
  final String name;

  _Variable(this.name);

  String lookup(Environment environment) {
    var value = environment.lookUp(name);
    if (value == null) {
      throw new Exception("Could not find '$name' in environment "
          "while evaluating status file expression.");
    }

    // Explicitly stringify all values so that things like:
    //
    //     $strong == true
    //
    // work correctly even though "true" is treated as a string here.
    // TODO(rnystrom): Is there a cleaner/safer way to do this?
    return value.toString();
  }
}

/// Tests whether a given variable is or is not equal some literal value, as in:
/// ```
/// $variable == someValue
/// ```
/// Negate the result if [negate] is true.
class _ComparisonExpression extends Expression {
  final _Variable left;
  final String right;
  final bool negate;

  _ComparisonExpression(this.left, this.right, this.negate);

  void validate(Environment environment, List<String> errors) {
    environment.validate(left.name, right, errors);
  }

  bool evaluate(Environment environment) {
    return negate != (left.lookup(environment) == right);
  }

  Expression normalize() {
    // Replace Boolean comparisons with a straight variable expression.
    if (right == "true") {
      return new _VariableExpression(left, negate: negate);
    } else if (right == "false") {
      return new _VariableExpression(left, negate: !negate);
    } else {
      return this;
    }
  }

  int _compareToMyType(_ComparisonExpression other) {
    if (left.name != other.left.name) {
      return left.name.compareTo(other.left.name);
    }

    if (right != other.right) {
      return right.compareTo(other.right);
    }

    return _compareBool(negate, other.negate);
  }

  // Comparisons come before variables so that "$compiler == ..." and
  // "$runtime == ..." appear on the left in status expressions.
  int get _typeComparison => 0;

  String toString() => "\$${left.name} ${negate ? '!=' : '=='} $right";
}

/// A reference to a variable defined in the environment. The expression
/// evaluates to true if the variable's stringified value is "true".
/// ```
///     $variable
/// ```
/// is equivalent to
/// ```
///     $variable == true
/// ```
/// Negates result if [negate] is true, so
/// ```
///     !$variable
/// ```
/// is equivalent to
/// ```
///     $variable != true
/// ```
class _VariableExpression extends Expression {
  final _Variable variable;
  final bool negate;

  _VariableExpression(this.variable, {this.negate = false});

  void validate(Environment environment, List<String> errors) {
    // It must be a Boolean, so it should allow either Boolean value.
    environment.validate(variable.name, "true", errors);
  }

  bool evaluate(Environment environment) =>
      negate != (variable.lookup(environment) == "true");

  /// Variable expressions are fine as they are.
  Expression normalize() => this;

  int _compareToMyType(_VariableExpression other) {
    if (variable.name != other.variable.name) {
      return variable.name.compareTo(other.variable.name);
    }

    return _compareBool(negate, other.negate);
  }

  int get _typeComparison => 1;

  String toString() => "${negate ? "!" : ""}\$${variable.name}";
}

/// A logical `||` or `&&` expression.
class _LogicExpression extends Expression {
  /// The operator, `||` or `&&`.
  final String op;

  final List<Expression> operands;

  _LogicExpression(this.op, this.operands);

  void validate(Environment environment, List<String> errors) {
    for (var operand in operands) {
      operand.validate(environment, errors);
    }
  }

  bool evaluate(Environment environment) {
    if (op == _Token.and) {
      return operands.every((operand) => operand.evaluate(environment));
    } else {
      return operands.any((operand) => operand.evaluate(environment));
    }
  }

  Expression normalize() {
    // Normalize the order of the clauses. Since there is no short-circuiting,
    // a || b means the same as b || a. Picking a standard order lets us
    // identify and collapse identical expressions that only differ by clause
    // order.

    // Recurse into the operands, sort them, and remove duplicates.
    var normalized = operands.map((operand) => operand.normalize());
    var ordered = new SplayTreeSet<Expression>.from(normalized).toList();
    return new _LogicExpression(op, ordered);
  }

  int _compareToMyType(_LogicExpression other) {
    // Put "&&" before "||".
    if (op != other.op) return op == _Token.and ? -1 : 1;

    // Lexicographically compare the operands.
    var length = math.max(operands.length, other.operands.length);
    for (var i = 0; i < length; i++) {
      if (i >= operands.length) return -1;
      if (i >= other.operands.length) return 1;

      var comparison = operands[i].compareTo(other.operands[i]);
      if (comparison != 0) return comparison;
    }

    return 0;
  }

  int get _typeComparison => 2;

  String toString() {
    String parenthesize(Expression operand) {
      var result = operand.toString();
      if (op == "&&" && operand is _LogicExpression && operand.op == "||") {
        result = "($result)";
      }

      return result;
    }

    return operands.map(parenthesize).join(" $op ");
  }
}

/// Parser for Boolean expressions in a .status file for Dart.
class _ExpressionParser {
  final _Scanner _scanner;

  _ExpressionParser(String expression) : _scanner = new _Scanner(expression);

  Expression parse() {
    var expression = _parseOr();

    // Should consume entire string.
    if (_scanner.hasMore) {
      throw new FormatException("Unexpected input after expression");
    }

    return expression;
  }

  Expression _parseOr() {
    var operands = [_parseAnd()];
    while (_scanner.match(_Token.or)) {
      operands.add(_parseAnd());
    }

    if (operands.length == 1) return operands.single;

    return new _LogicExpression(_Token.or, operands);
  }

  Expression _parseAnd() {
    var operands = [_parsePrimary()];
    while (_scanner.match(_Token.and)) {
      operands.add(_parsePrimary());
    }

    if (operands.length == 1) return operands.single;

    return new _LogicExpression(_Token.and, operands);
  }

  Expression _parsePrimary() {
    if (_scanner.match(_Token.leftParen)) {
      var value = _parseOr();
      if (!_scanner.match(_Token.rightParen)) {
        throw new FormatException("Missing right parenthesis in expression");
      }

      return value;
    }

    var negate = false;
    if (_scanner.match(_Token.not)) {
      negate = true;
    }

    // The only atomic booleans are of the form $variable == value or
    // of the form $variable.
    if (!_scanner.match(_Token.dollar)) {
      throw new FormatException(
          "Expected \$ in expression, got ${_scanner.current}");
    }

    if (!_scanner.isIdentifier) {
      throw new FormatException(
          "Expected identifier in expression, got ${_scanner.current}");
    }

    var left = new _Variable(_scanner.current);
    _scanner.advance();

    if (!negate &&
        (_scanner.current == _Token.equals ||
            _scanner.current == _Token.notEqual)) {
      var isNotEquals = _scanner.advance() == _Token.notEqual;

      if (!_scanner.isIdentifier) {
        throw new FormatException(
            "Expected value in expression, got ${_scanner.current}");
      }

      var right = _scanner.advance();
      return new _ComparisonExpression(left, right, isNotEquals);
    } else {
      return new _VariableExpression(left, negate: negate);
    }
  }
}

/// An iterator that allows peeking at the current token.
class _Scanner {
  /// Tokens are "(", ")", "$", "&&", "||", "!", ==", "!=", and (maximal) \w+.
  static final _testPattern = new RegExp(r"^(?:[()$\w\s]|&&|\|\||==|!=?)+$");
  static final _tokenPattern = new RegExp(r"[()$]|&&|\|\||==|!=?|\w+");

  /// Pattern that recognizes identifier tokens.
  ///
  /// Only checks the first character, since no non-identifier token can start
  /// with a word character.
  static final _identifierPattern = new RegExp(r"^\w");

  /// The token strings being iterated.
  final Iterator<String> tokenIterator;

  String current;

  _Scanner(String expression) : tokenIterator = tokenize(expression).iterator {
    advance();
  }

  static List<String> tokenize(String expression) {
    if (!_testPattern.hasMatch(expression)) {
      throw new FormatException("Syntax error in '$expression'");
    }

    return _tokenPattern
        .allMatches(expression)
        .map((match) => match[0])
        .toList();
  }

  bool get hasMore => current != null;

  /// Returns `true` if the current token is an identifier.
  // All non-identifier tokens are one or two characters,
  // so a longer token must be an identifier.
  bool get isIdentifier =>
      current.length > 2 || _identifierPattern.hasMatch(current);

  /// If the current token is [token], consumes it and returns `true`.
  bool match(String token) {
    if (!hasMore || current != token) return false;

    advance();
    return true;
  }

  /// Consumes the current token and returns it.
  String advance() {
    var previous = current;
    current = tokenIterator.moveNext() ? tokenIterator.current : null;
    return previous;
  }
}

int _compareBool(bool a, bool b) {
  if (a == b) return 0;
  if (a) return 1;
  return -1;
}
