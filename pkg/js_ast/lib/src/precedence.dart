// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The ordering of the values in this enum is important. Higher enum indices
// correspond to higher precedences derived from the expression grammar
// specification at https://tc39.es/ecma262/.
enum Precedence {
  expression,
  assignment,
  logicalOr,
  logicalAnd,
  bitOr,
  bitXor,
  bitAnd,
  equality,
  relational,
  shift,
  additive,
  multiplicative,
  exponentiation,
  unary,
  update,
  call,
  leftHandSide,
  primary,
}
