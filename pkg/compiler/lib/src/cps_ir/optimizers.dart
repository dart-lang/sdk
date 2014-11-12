// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.optimizers;

import '../constants/expressions.dart' show
    ConstantExpression,
    PrimitiveConstantExpression;
import '../constants/values.dart';
import '../dart_types.dart' as types;
import '../dart2jslib.dart' as dart2js;
import '../tree/tree.dart' show LiteralDartString;
import '../util/util.dart';
import 'cps_ir_nodes.dart';

part 'constant_propagation.dart';
part 'redundant_phi.dart';
part 'shrinking_reductions.dart';

/// An optimization pass over the CPS IR.
abstract class Pass {
  /// Applies optimizations to root, rewriting it in the process.
  void rewrite(FunctionDefinition root);
}
