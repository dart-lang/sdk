// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.operators;

import 'names.dart' show PublicName;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector, SelectorKind;

enum UnaryOperatorKind {
  NOT,
  NEGATE,
  COMPLEMENT,
}

class UnaryOperator {
  final UnaryOperatorKind kind;
  final String name;
  final String selectorName;

  const UnaryOperator(this.kind, this.name, this.selectorName);

  bool get isUserDefinable => selectorName != null;

  Selector get selector => Selector(
      SelectorKind.OPERATOR, PublicName(selectorName), CallStructure.NO_ARGS);

  @override
  String toString() => name;

  /// The unary ! operator.
  static const UnaryOperator NOT =
      UnaryOperator(UnaryOperatorKind.NOT, '!', null);

  /// The unary - operator.
  static const UnaryOperator NEGATE =
      UnaryOperator(UnaryOperatorKind.NEGATE, '-', 'unary-');

  /// The unary ~ operator.
  static const UnaryOperator COMPLEMENT =
      UnaryOperator(UnaryOperatorKind.COMPLEMENT, '~', '~');

  static UnaryOperator parse(String value) {
    switch (value) {
      case '!':
        return NOT;
      case '-':
        return NEGATE;
      case '~':
        return COMPLEMENT;
      default:
        return null;
    }
  }

  // ignore: MISSING_RETURN
  static UnaryOperator fromKind(UnaryOperatorKind kind) {
    switch (kind) {
      case UnaryOperatorKind.NOT:
        return NOT;
      case UnaryOperatorKind.NEGATE:
        return NEGATE;
      case UnaryOperatorKind.COMPLEMENT:
        return COMPLEMENT;
    }
  }
}

enum BinaryOperatorKind {
  EQ,
  NOT_EQ,
  INDEX,
  ADD,
  SUB,
  MUL,
  DIV,
  IDIV,
  MOD,
  SHL,
  SHR,
  SHRU,
  GTEQ,
  GT,
  LTEQ,
  LT,
  AND,
  OR,
  XOR,
  LOGICAL_AND,
  LOGICAL_OR,
  IF_NULL,
}

class BinaryOperator {
  final BinaryOperatorKind kind;
  final String name;

  const BinaryOperator._(this.kind, this.name);

  /// `true` if this operator can be implemented through an `operator [name]`
  /// method.
  bool get isUserDefinable => true;

  String get selectorName => name;

  @override
  String toString() => name;

  /// The == operator.
  static const BinaryOperator EQ =
      BinaryOperator._(BinaryOperatorKind.EQ, '==');

  /// The != operator.
  static const BinaryOperator NOT_EQ = _NotEqualsOperator();

  /// The [] operator.
  static const BinaryOperator INDEX =
      BinaryOperator._(BinaryOperatorKind.INDEX, '[]');

  /// The binary + operator.
  static const BinaryOperator ADD =
      BinaryOperator._(BinaryOperatorKind.ADD, '+');

  /// The binary - operator.
  static const BinaryOperator SUB =
      BinaryOperator._(BinaryOperatorKind.SUB, '-');

  /// The binary * operator.
  static const BinaryOperator MUL =
      BinaryOperator._(BinaryOperatorKind.MUL, '*');

  /// The binary / operator.
  static const BinaryOperator DIV =
      BinaryOperator._(BinaryOperatorKind.DIV, '/');

  /// The binary ~/ operator.
  static const BinaryOperator IDIV =
      BinaryOperator._(BinaryOperatorKind.IDIV, '~/');

  /// The binary % operator.
  static const BinaryOperator MOD =
      BinaryOperator._(BinaryOperatorKind.MOD, '%');

  /// The binary << operator.
  static const BinaryOperator SHL =
      BinaryOperator._(BinaryOperatorKind.SHL, '<<');

  /// The binary >> operator.
  static const BinaryOperator SHR =
      BinaryOperator._(BinaryOperatorKind.SHR, '>>');

  /// The binary >>> operator.
  static const BinaryOperator SHRU =
      BinaryOperator._(BinaryOperatorKind.SHRU, '>>>');

  /// The binary >= operator.
  static const BinaryOperator GTEQ =
      BinaryOperator._(BinaryOperatorKind.GTEQ, '>=');

  /// The binary > operator.
  static const BinaryOperator GT = BinaryOperator._(BinaryOperatorKind.GT, '>');

  /// The binary <= operator.
  static const BinaryOperator LTEQ =
      BinaryOperator._(BinaryOperatorKind.LTEQ, '<=');

  /// The binary < operator.
  static const BinaryOperator LT = BinaryOperator._(BinaryOperatorKind.LT, '<');

  /// The binary & operator.
  static const BinaryOperator AND =
      BinaryOperator._(BinaryOperatorKind.AND, '&');

  /// The binary | operator.
  static const BinaryOperator OR = BinaryOperator._(BinaryOperatorKind.OR, '|');

  /// The binary ^ operator.
  static const BinaryOperator XOR =
      BinaryOperator._(BinaryOperatorKind.XOR, '^');

  /// The logical && operator.
  static const BinaryOperator LOGICAL_AND =
      _LogicalOperator(BinaryOperatorKind.LOGICAL_AND, '&&');

  /// The binary | operator.
  static const BinaryOperator LOGICAL_OR =
      _LogicalOperator(BinaryOperatorKind.LOGICAL_OR, '||');

  /// The if-null ?? operator.
  static const BinaryOperator IF_NULL =
      _IfNullOperator(BinaryOperatorKind.IF_NULL, '??');

  static BinaryOperator parse(String value) {
    switch (value) {
      case '&&':
        return LOGICAL_AND;
      case '||':
        return LOGICAL_OR;
      case '??':
        return IF_NULL;
      default:
        return parseUserDefinable(value);
    }
  }

  static BinaryOperator parseUserDefinable(String value) {
    switch (value) {
      case '==':
        return EQ;
      case '!=':
        return NOT_EQ;
      case '[]':
        return INDEX;
      case '*':
        return MUL;
      case '/':
        return DIV;
      case '%':
        return MOD;
      case '~/':
        return IDIV;
      case '+':
        return ADD;
      case '-':
        return SUB;
      case '<<':
        return SHL;
      case '>>':
        return SHR;
      case '>>>':
        return SHRU;
      case '>=':
        return GTEQ;
      case '>':
        return GT;
      case '<=':
        return LTEQ;
      case '<':
        return LT;
      case '&':
        return AND;
      case '^':
        return XOR;
      case '|':
        return OR;
      default:
        return null;
    }
  }

  // ignore: MISSING_RETURN
  static BinaryOperator fromKind(BinaryOperatorKind kind) {
    switch (kind) {
      case BinaryOperatorKind.EQ:
        return EQ;
      case BinaryOperatorKind.NOT_EQ:
        return NOT_EQ;
      case BinaryOperatorKind.INDEX:
        return INDEX;
      case BinaryOperatorKind.MUL:
        return MUL;
      case BinaryOperatorKind.DIV:
        return DIV;
      case BinaryOperatorKind.MOD:
        return MOD;
      case BinaryOperatorKind.IDIV:
        return IDIV;
      case BinaryOperatorKind.ADD:
        return ADD;
      case BinaryOperatorKind.SUB:
        return SUB;
      case BinaryOperatorKind.SHL:
        return SHL;
      case BinaryOperatorKind.SHR:
        return SHR;
      case BinaryOperatorKind.SHRU:
        return SHRU;
      case BinaryOperatorKind.GTEQ:
        return GTEQ;
      case BinaryOperatorKind.GT:
        return GT;
      case BinaryOperatorKind.LTEQ:
        return LTEQ;
      case BinaryOperatorKind.LT:
        return LT;
      case BinaryOperatorKind.AND:
        return AND;
      case BinaryOperatorKind.XOR:
        return XOR;
      case BinaryOperatorKind.OR:
        return OR;
      case BinaryOperatorKind.LOGICAL_AND:
        return LOGICAL_AND;
      case BinaryOperatorKind.LOGICAL_OR:
        return LOGICAL_OR;
      case BinaryOperatorKind.IF_NULL:
        return IF_NULL;
    }
  }
}

/// The operator !=, which is not user definable operator but instead is a
/// negation of a call to user definable operator, namely ==.
class _NotEqualsOperator extends BinaryOperator {
  const _NotEqualsOperator() : super._(BinaryOperatorKind.NOT_EQ, '!=');

  @override
  bool get isUserDefinable => false;

  @override
  String get selectorName => '==';
}

/// The operators && and || which are not user definable operators but control
/// structures.
class _LogicalOperator extends BinaryOperator {
  const _LogicalOperator(BinaryOperatorKind kind, String name)
      : super._(kind, name);

  @override
  bool get isUserDefinable => false;

  @override
  String get selectorName => null;
}

/// The operators ?? is not user definable.
class _IfNullOperator extends BinaryOperator {
  const _IfNullOperator(BinaryOperatorKind kind, String name)
      : super._(kind, name);

  @override
  bool get isUserDefinable => false;

  @override
  String get selectorName => '??';
}
