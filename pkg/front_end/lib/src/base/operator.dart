// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.operators;

/// The user-definable operators in Dart.
///
/// The names have been chosen to represent their normal semantic meaning.
enum Operator {
  add("+", 1),
  bitwiseAnd("&", 1),
  bitwiseNot("~", 0),
  bitwiseOr("|", 1),
  bitwiseXor("^", 1),
  divide("/", 1),
  equals("==", 1),
  greaterThan(">", 1),
  greaterThanEquals(">=", 1),
  indexGet("[]", 1),
  indexSet("[]=", 2),
  leftShift("<<", 1),
  lessThan("<", 1),
  lessThanEquals("<=", 1),
  modulo("%", 1),
  multiply("*", 1),
  rightShift(">>", 1),
  tripleShift(">>>", 1),
  subtract("-", 1),
  truncatingDivide("~/", 1),
  unaryMinus("unary-", 0),
  ;

  final String text;
  final int requiredArgumentCount;

  const Operator(this.text, this.requiredArgumentCount);

  static Operator? fromText(String text) {
    // TODO(johnniwinther): Should we have a map instead?
    for (Operator operator in values) {
      if (identical(operator.text, text)) {
        return operator;
      }
    }
    return null;
  }
}
