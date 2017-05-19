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

  Selector get selector => new Selector(SelectorKind.OPERATOR,
      new PublicName(selectorName), CallStructure.NO_ARGS);

  String toString() => name;

  /// The unary ! operator.
  static const UnaryOperator NOT =
      const UnaryOperator(UnaryOperatorKind.NOT, '!', null);

  /// The unary - operator.
  static const UnaryOperator NEGATE =
      const UnaryOperator(UnaryOperatorKind.NEGATE, '-', 'unary-');

  /// The unary ~ operator.
  static const UnaryOperator COMPLEMENT =
      const UnaryOperator(UnaryOperatorKind.COMPLEMENT, '~', '~');

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

  String toString() => name;

  /// The == operator.
  static const BinaryOperator EQ =
      const BinaryOperator._(BinaryOperatorKind.EQ, '==');

  /// The != operator.
  static const BinaryOperator NOT_EQ = const _NotEqualsOperator();

  /// The [] operator.
  static const BinaryOperator INDEX =
      const BinaryOperator._(BinaryOperatorKind.INDEX, '[]');

  /// The binary + operator.
  static const BinaryOperator ADD =
      const BinaryOperator._(BinaryOperatorKind.ADD, '+');

  /// The binary - operator.
  static const BinaryOperator SUB =
      const BinaryOperator._(BinaryOperatorKind.SUB, '-');

  /// The binary * operator.
  static const BinaryOperator MUL =
      const BinaryOperator._(BinaryOperatorKind.MUL, '*');

  /// The binary / operator.
  static const BinaryOperator DIV =
      const BinaryOperator._(BinaryOperatorKind.DIV, '/');

  /// The binary ~/ operator.
  static const BinaryOperator IDIV =
      const BinaryOperator._(BinaryOperatorKind.IDIV, '~/');

  /// The binary % operator.
  static const BinaryOperator MOD =
      const BinaryOperator._(BinaryOperatorKind.MOD, '%');

  /// The binary << operator.
  static const BinaryOperator SHL =
      const BinaryOperator._(BinaryOperatorKind.SHL, '<<');

  /// The binary >> operator.
  static const BinaryOperator SHR =
      const BinaryOperator._(BinaryOperatorKind.SHR, '>>');

  /// The binary >= operator.
  static const BinaryOperator GTEQ =
      const BinaryOperator._(BinaryOperatorKind.GTEQ, '>=');

  /// The binary > operator.
  static const BinaryOperator GT =
      const BinaryOperator._(BinaryOperatorKind.GT, '>');

  /// The binary <= operator.
  static const BinaryOperator LTEQ =
      const BinaryOperator._(BinaryOperatorKind.LTEQ, '<=');

  /// The binary < operator.
  static const BinaryOperator LT =
      const BinaryOperator._(BinaryOperatorKind.LT, '<');

  /// The binary & operator.
  static const BinaryOperator AND =
      const BinaryOperator._(BinaryOperatorKind.AND, '&');

  /// The binary | operator.
  static const BinaryOperator OR =
      const BinaryOperator._(BinaryOperatorKind.OR, '|');

  /// The binary ^ operator.
  static const BinaryOperator XOR =
      const BinaryOperator._(BinaryOperatorKind.XOR, '^');

  /// The logical && operator.
  static const BinaryOperator LOGICAL_AND =
      const _LogicalOperator(BinaryOperatorKind.LOGICAL_AND, '&&');

  /// The binary | operator.
  static const BinaryOperator LOGICAL_OR =
      const _LogicalOperator(BinaryOperatorKind.LOGICAL_OR, '||');

  /// The if-null ?? operator.
  static const BinaryOperator IF_NULL =
      const _IfNullOperator(BinaryOperatorKind.IF_NULL, '??');

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

  bool get isUserDefinable => false;

  String get selectorName => '==';
}

/// The operators && and || which are not user definable operators but control
/// structures.
class _LogicalOperator extends BinaryOperator {
  const _LogicalOperator(BinaryOperatorKind kind, String name)
      : super._(kind, name);

  bool get isUserDefinable => false;

  String get selectorName => null;
}

/// The operators ?? is not user definable.
class _IfNullOperator extends BinaryOperator {
  const _IfNullOperator(BinaryOperatorKind kind, String name)
      : super._(kind, name);

  bool get isUserDefinable => false;

  String get selectorName => '??';
}

enum AssignmentOperatorKind {
  ASSIGN,
  IF_NULL,
  ADD,
  SUB,
  MUL,
  DIV,
  IDIV,
  MOD,
  SHL,
  SHR,
  AND,
  OR,
  XOR,
}

class AssignmentOperator {
  final AssignmentOperatorKind kind;
  final BinaryOperator binaryOperator;
  final String name;
  final bool isUserDefinable;

  const AssignmentOperator._(this.kind, this.name, this.binaryOperator,
      {this.isUserDefinable: true});

  String get selectorName {
    return binaryOperator != null ? binaryOperator.selectorName : null;
  }

  String toString() => name;

  /// The = operator.
  static const AssignmentOperator ASSIGN = const AssignmentOperator._(
      AssignmentOperatorKind.ASSIGN, '=', null,
      isUserDefinable: false);

  /// The ??= operator.
  static const AssignmentOperator IF_NULL = const AssignmentOperator._(
      AssignmentOperatorKind.IF_NULL, '??=', BinaryOperator.IF_NULL,
      isUserDefinable: false);

  /// The += assignment operator.
  static const AssignmentOperator ADD = const AssignmentOperator._(
      AssignmentOperatorKind.ADD, '+=', BinaryOperator.ADD);

  /// The -= assignment operator.
  static const AssignmentOperator SUB = const AssignmentOperator._(
      AssignmentOperatorKind.SUB, '-=', BinaryOperator.SUB);

  /// The *= assignment operator.
  static const AssignmentOperator MUL = const AssignmentOperator._(
      AssignmentOperatorKind.MUL, '*=', BinaryOperator.MUL);

  /// The /= assignment operator.
  static const AssignmentOperator DIV = const AssignmentOperator._(
      AssignmentOperatorKind.DIV, '/=', BinaryOperator.DIV);

  /// The ~/= assignment operator.
  static const AssignmentOperator IDIV = const AssignmentOperator._(
      AssignmentOperatorKind.IDIV, '~/=', BinaryOperator.IDIV);

  /// The %= assignment operator.
  static const AssignmentOperator MOD = const AssignmentOperator._(
      AssignmentOperatorKind.MOD, '%=', BinaryOperator.MOD);

  /// The <<= assignment operator.
  static const AssignmentOperator SHL = const AssignmentOperator._(
      AssignmentOperatorKind.SHL, '<<=', BinaryOperator.SHL);

  /// The >>= assignment operator.
  static const AssignmentOperator SHR = const AssignmentOperator._(
      AssignmentOperatorKind.SHR, '>>=', BinaryOperator.SHR);

  /// The &= assignment operator.
  static const AssignmentOperator AND = const AssignmentOperator._(
      AssignmentOperatorKind.AND, '&=', BinaryOperator.AND);

  /// The |= assignment operator.
  static const AssignmentOperator OR = const AssignmentOperator._(
      AssignmentOperatorKind.OR, '|=', BinaryOperator.OR);

  /// The ^= assignment operator.
  static const AssignmentOperator XOR = const AssignmentOperator._(
      AssignmentOperatorKind.XOR, '^=', BinaryOperator.XOR);

  static AssignmentOperator parse(String value) {
    switch (value) {
      case '=':
        return ASSIGN;
      case '??=':
        return IF_NULL;
      case '*=':
        return MUL;
      case '/=':
        return DIV;
      case '%=':
        return MOD;
      case '~/=':
        return IDIV;
      case '+=':
        return ADD;
      case '-=':
        return SUB;
      case '<<=':
        return SHL;
      case '>>=':
        return SHR;
      case '&=':
        return AND;
      case '^=':
        return XOR;
      case '|=':
        return OR;
      default:
        return null;
    }
  }

  // ignore: MISSING_RETURN
  static AssignmentOperator fromKind(AssignmentOperatorKind kind) {
    switch (kind) {
      case AssignmentOperatorKind.ASSIGN:
        return ASSIGN;
      case AssignmentOperatorKind.IF_NULL:
        return IF_NULL;
      case AssignmentOperatorKind.ADD:
        return ADD;
      case AssignmentOperatorKind.SUB:
        return SUB;
      case AssignmentOperatorKind.MUL:
        return MUL;
      case AssignmentOperatorKind.DIV:
        return DIV;
      case AssignmentOperatorKind.IDIV:
        return IDIV;
      case AssignmentOperatorKind.MOD:
        return MOD;
      case AssignmentOperatorKind.SHL:
        return SHL;
      case AssignmentOperatorKind.SHR:
        return SHR;
      case AssignmentOperatorKind.AND:
        return AND;
      case AssignmentOperatorKind.OR:
        return OR;
      case AssignmentOperatorKind.XOR:
        return XOR;
    }
  }
}

enum IncDecOperatorKind { INC, DEC }

class IncDecOperator {
  final IncDecOperatorKind kind;
  final String name;
  final BinaryOperator binaryOperator;

  const IncDecOperator._(this.kind, this.name, this.binaryOperator);

  String get selectorName => binaryOperator.selectorName;

  String toString() => name;

  /// The prefix/postfix ++ operator.
  static const IncDecOperator INC =
      const IncDecOperator._(IncDecOperatorKind.INC, '++', BinaryOperator.ADD);

  /// The prefix/postfix -- operator.
  static const IncDecOperator DEC =
      const IncDecOperator._(IncDecOperatorKind.DEC, '--', BinaryOperator.SUB);

  static IncDecOperator parse(String value) {
    switch (value) {
      case '++':
        return INC;
      case '--':
        return DEC;
      default:
        return null;
    }
  }

  // ignore: MISSING_RETURN
  static IncDecOperator fromKind(IncDecOperatorKind kind) {
    switch (kind) {
      case IncDecOperatorKind.INC:
        return INC;
      case IncDecOperatorKind.DEC:
        return DEC;
    }
  }
}
