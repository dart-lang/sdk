// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.optimizers;

import 'cps_ir_nodes.dart';

part 'redundant_phi.dart';
part 'shrinking_reductions.dart';

/// An optimization pass over the CPS IR.
abstract class Pass {
  /// Applies optimizations to root, rewriting it in the process.
  void rewrite(FunctionDefinition root);
}
