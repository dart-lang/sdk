// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constant_system;

import '../common_elements.dart' show CommonElements;
import '../elements/operators.dart';
import '../elements/types.dart';
import 'values.dart';

abstract class Operation {
  String get name;
}

abstract class UnaryOperation extends Operation {
  /** Returns [:null:] if it was unable to fold the operation. */
  ConstantValue fold(ConstantValue constant);
}

abstract class BinaryOperation extends Operation {
  /** Returns [:null:] if it was unable to fold the operation. */
  ConstantValue fold(ConstantValue left, ConstantValue right);
  apply(left, right);
}

/**
 * A [ConstantSystem] is responsible for creating constants and folding them.
 */
abstract class ConstantSystem {
  BinaryOperation get add;
  BinaryOperation get bitAnd;
  UnaryOperation get bitNot;
  BinaryOperation get bitOr;
  BinaryOperation get bitXor;
  BinaryOperation get booleanAnd;
  BinaryOperation get booleanOr;
  BinaryOperation get divide;
  BinaryOperation get equal;
  BinaryOperation get greaterEqual;
  BinaryOperation get greater;
  BinaryOperation get identity;
  BinaryOperation get ifNull;
  BinaryOperation get lessEqual;
  BinaryOperation get less;
  BinaryOperation get modulo;
  BinaryOperation get multiply;
  UnaryOperation get negate;
  UnaryOperation get not;
  BinaryOperation get remainder;
  BinaryOperation get shiftLeft;
  BinaryOperation get shiftRight;
  BinaryOperation get subtract;
  BinaryOperation get truncatingDivide;

  BinaryOperation get codeUnitAt;
  UnaryOperation get round;

  const ConstantSystem();

  ConstantValue createInt(int i);
  ConstantValue createDouble(double d);
  ConstantValue createString(String string);
  ConstantValue createBool(bool value);
  ConstantValue createNull();
  ConstantValue createList(InterfaceType type, List<ConstantValue> values);
  ConstantValue createMap(CommonElements commonElements, InterfaceType type,
      List<ConstantValue> keys, List<ConstantValue> values);
  ConstantValue createType(CommonElements commonElements, DartType type);
  ConstantValue createSymbol(CommonElements commonElements, String text);

  // We need to special case the subtype check for JavaScript constant
  // system because an int is a double at runtime.
  bool isSubtype(DartTypes types, DartType s, DartType t);

  /** Returns true if the [constant] is an integer at runtime. */
  bool isInt(ConstantValue constant);
  /** Returns true if the [constant] is a double at runtime. */
  bool isDouble(ConstantValue constant);
  /** Returns true if the [constant] is a string at runtime. */
  bool isString(ConstantValue constant);
  /** Returns true if the [constant] is a boolean at runtime. */
  bool isBool(ConstantValue constant);
  /** Returns true if the [constant] is null at runtime. */
  bool isNull(ConstantValue constant);

  UnaryOperation lookupUnary(UnaryOperator operator) {
    switch (operator.kind) {
      case UnaryOperatorKind.COMPLEMENT:
        return bitNot;
      case UnaryOperatorKind.NEGATE:
        return negate;
      case UnaryOperatorKind.NOT:
        return not;
      default:
        return null;
    }
  }

  BinaryOperation lookupBinary(BinaryOperator operator) {
    switch (operator.kind) {
      case BinaryOperatorKind.ADD:
        return add;
      case BinaryOperatorKind.SUB:
        return subtract;
      case BinaryOperatorKind.MUL:
        return multiply;
      case BinaryOperatorKind.DIV:
        return divide;
      case BinaryOperatorKind.MOD:
        return modulo;
      case BinaryOperatorKind.IDIV:
        return truncatingDivide;
      case BinaryOperatorKind.OR:
        return bitOr;
      case BinaryOperatorKind.AND:
        return bitAnd;
      case BinaryOperatorKind.XOR:
        return bitXor;
      case BinaryOperatorKind.LOGICAL_OR:
        return booleanOr;
      case BinaryOperatorKind.LOGICAL_AND:
        return booleanAnd;
      case BinaryOperatorKind.SHL:
        return shiftLeft;
      case BinaryOperatorKind.SHR:
        return shiftRight;
      case BinaryOperatorKind.LT:
        return less;
      case BinaryOperatorKind.LTEQ:
        return lessEqual;
      case BinaryOperatorKind.GT:
        return greater;
      case BinaryOperatorKind.GTEQ:
        return greaterEqual;
      case BinaryOperatorKind.EQ:
        return equal;
      case BinaryOperatorKind.IF_NULL:
        return ifNull;
      default:
        return null;
    }
  }
}
