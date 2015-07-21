// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.optimizers;

import 'cps_ir_nodes.dart';
import '../constants/values.dart';

export 'type_propagation.dart' show TypePropagator;
export 'redundant_phi.dart' show RedundantPhiEliminator;
export 'redundant_join.dart' show RedundantJoinEliminator;
export 'shrinking_reductions.dart' show ShrinkingReducer, ParentVisitor;
export 'mutable_ssa.dart' show MutableVariableEliminator;
export 'let_sinking.dart' show LetSinker;

/// An optimization pass over the CPS IR.
abstract class Pass {
  /// Applies optimizations to root, rewriting it in the process.
  void rewrite(FunctionDefinition root);

  String get passName;
}

// Shared code between optimizations

/// Returns true if [value] is false, null, 0, -0, NaN, or the empty string.
bool isFalsyConstant(ConstantValue value) {
  return value.isFalse ||
      value.isNull  ||
      value.isZero ||
      value.isMinusZero ||
      value.isNaN ||
      value is StringConstantValue && value.primitiveValue.isEmpty;
}
