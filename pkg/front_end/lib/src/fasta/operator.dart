// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.operators;

/// The user-definable operators in Dart.
///
/// The names have been chosen to represent their normal semantic meaning.
enum Operator {
  add,
  bitwiseAnd,
  bitwiseNot,
  bitwiseOr,
  bitwiseXor,
  divide,
  equals,
  greaterThan,
  greaterThanEquals,
  indexGet,
  indexSet,
  leftShift,
  lessThan,
  lessThanEquals,
  modulo,
  multiply,
  rightShift,
  subtract,
  truncatingDivide,
  unaryMinus,
}

Operator operatorFromString(String string) {
  if (identical("+", string)) return Operator.add;
  if (identical("&", string)) return Operator.bitwiseAnd;
  if (identical("~", string)) return Operator.bitwiseNot;
  if (identical("|", string)) return Operator.bitwiseOr;
  if (identical("^", string)) return Operator.bitwiseXor;
  if (identical("/", string)) return Operator.divide;
  if (identical("==", string)) return Operator.equals;
  if (identical(">", string)) return Operator.greaterThan;
  if (identical(">=", string)) return Operator.greaterThanEquals;
  if (identical("[]", string)) return Operator.indexGet;
  if (identical("[]=", string)) return Operator.indexSet;
  if (identical("<<", string)) return Operator.leftShift;
  if (identical("<", string)) return Operator.lessThan;
  if (identical("<=", string)) return Operator.lessThanEquals;
  if (identical("%", string)) return Operator.modulo;
  if (identical("*", string)) return Operator.multiply;
  if (identical(">>", string)) return Operator.rightShift;
  if (identical("-", string)) return Operator.subtract;
  if (identical("~/", string)) return Operator.truncatingDivide;
  if (identical("unary-", string)) return Operator.unaryMinus;
  return null;
}

String operatorToString(Operator operator) {
  switch (operator) {
    case Operator.add:
      return "+";
    case Operator.bitwiseAnd:
      return "&";
    case Operator.bitwiseNot:
      return "~";
    case Operator.bitwiseOr:
      return "|";
    case Operator.bitwiseXor:
      return "^";
    case Operator.divide:
      return "/";
    case Operator.equals:
      return "==";
    case Operator.greaterThan:
      return ">";
    case Operator.greaterThanEquals:
      return ">=";
    case Operator.indexGet:
      return "[]";
    case Operator.indexSet:
      return "[]=";
    case Operator.leftShift:
      return "<<";
    case Operator.lessThan:
      return "<";
    case Operator.lessThanEquals:
      return "<=";
    case Operator.modulo:
      return "%";
    case Operator.multiply:
      return "*";
    case Operator.rightShift:
      return ">>";
    case Operator.subtract:
      return "-";
    case Operator.truncatingDivide:
      return "~/";
    case Operator.unaryMinus:
      return "unary-";
  }
  return null;
}

int operatorRequiredArgumentCount(Operator operator) {
  switch (operator) {
    case Operator.bitwiseNot:
    case Operator.unaryMinus:
      return 0;

    case Operator.add:
    case Operator.bitwiseAnd:
    case Operator.bitwiseOr:
    case Operator.bitwiseXor:
    case Operator.divide:
    case Operator.equals:
    case Operator.greaterThan:
    case Operator.greaterThanEquals:
    case Operator.indexGet:
    case Operator.leftShift:
    case Operator.lessThan:
    case Operator.lessThanEquals:
    case Operator.modulo:
    case Operator.multiply:
    case Operator.rightShift:
    case Operator.subtract:
    case Operator.truncatingDivide:
      return 1;

    case Operator.indexSet:
      return 2;
  }
  return -1;
}
