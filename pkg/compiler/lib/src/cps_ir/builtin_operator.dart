// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library builtin_operator;
// This is shared by the CPS and Tree IRs.
// Both cps_ir_nodes and tree_ir_nodes import and re-export this file.

/// An operator supported natively in the CPS and Tree IRs using the
/// `ApplyBuiltinOperator` instructions.
///
/// These operators are pure in the sense that they cannot throw, diverge,
/// have observable side-effects, return new objects, nor depend on any
/// mutable state.
///
/// Most operators place restrictions on the values that may be given as
/// argument; their behaviour is unspecified if those requirements are violated.
///
/// In all cases, the word "null" refers to the Dart null object, corresponding
/// to both JS null and JS undefined.
enum BuiltinOperator {
  /// The numeric binary operators must take two numbers as argument.
  /// The bitwise operators coerce the result to an unsigned integer, but
  /// otherwise these all behave like the corresponding JS operator.
  NumAdd,
  NumSubtract,
  NumMultiply,
  NumAnd,
  NumOr,
  NumXor,
  NumLt,
  NumLe,
  NumGt,
  NumGe,

  /// Returns true if the two arguments are the same value, and that value is
  /// not NaN, or if one argument is +0 and the other is -0.
  ///
  /// At most one of the arguments may be null.
  StrictEq,

  /// Negated version of [StrictEq]. Introduced by [LogicalRewriter] in Tree IR.
  StrictNeq,

  /// Returns true if the two arguments are both null or are the same string,
  /// boolean, or number, and that number is not NaN, or one argument is +0
  /// and the other is -0.
  ///
  /// One of the following must hold:
  /// - At least one argument is null.
  /// - Arguments are both strings, or both booleans, or both numbers.
  LooseEq,

  /// Negated version of [LooseEq]. Introduced by [LogicalRewriter] in Tree IR.
  LooseNeq,

  /// Returns true if the argument is false, +0. -0, NaN, the empty string,
  /// or null.
  IsFalsy
}
