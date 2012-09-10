// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Operation {
  final SourceString name;
  bool isUserDefinable();
}

interface UnaryOperation extends Operation {
  /** Returns [:null:] if it was unable to fold the operation. */
  Constant fold(Constant constant);
}

interface BinaryOperation extends Operation {
  /** Returns [:null:] if it was unable to fold the operation. */
  Constant fold(Constant left, Constant right);
}

/**
 * A [ConstantSystem] is responsible for creating constants and folding them.
 */
interface ConstantSystem {
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

  Constant createInt(int i);
  Constant createDouble(double d);
  // We need a diagnostic node to report errors in case the string is malformed.
  Constant createString(DartString string, Node diagnosticNode);
  Constant createBool(bool value);
  Constant createNull();

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
}
