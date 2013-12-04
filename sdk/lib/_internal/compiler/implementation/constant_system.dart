// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

abstract class Operation {
  String get name;
}

abstract class UnaryOperation extends Operation {
  /** Returns [:null:] if it was unable to fold the operation. */
  Constant fold(Constant constant);
}

abstract class BinaryOperation extends Operation {
  /** Returns [:null:] if it was unable to fold the operation. */
  Constant fold(Constant left, Constant right);
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
  BinaryOperation get lessEqual;
  BinaryOperation get less;
  BinaryOperation get modulo;
  BinaryOperation get multiply;
  UnaryOperation get negate;
  UnaryOperation get not;
  BinaryOperation get shiftLeft;
  BinaryOperation get shiftRight;
  BinaryOperation get subtract;
  BinaryOperation get truncatingDivide;

  const ConstantSystem();

  Constant createInt(int i);
  Constant createDouble(double d);
  Constant createString(DartString string);
  Constant createBool(bool value);
  Constant createNull();

  // We need to special case the subtype check for JavaScript constant
  // system because an int is a double at runtime.
  bool isSubtype(Compiler compiler, DartType s, DartType t);

  /** Returns true if the [constant] is an integer at runtime. */
  bool isInt(Constant constant);
  /** Returns true if the [constant] is a double at runtime. */
  bool isDouble(Constant constant);
  /** Returns true if the [constant] is a string at runtime. */
  bool isString(Constant constant);
  /** Returns true if the [constant] is a boolean at runtime. */
  bool isBool(Constant constant);
  /** Returns true if the [constant] is null at runtime. */
  bool isNull(Constant constant);

  Operation lookupUnary(String operator) {
    if (operator == '-') return negate;
    if (operator == '~') return bitNot;
    return null;
  }
}
