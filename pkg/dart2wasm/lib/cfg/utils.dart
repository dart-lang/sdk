// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';

extension ReducibleFlowGraph on FlowGraph {
  /// Whether this control-flow graph is reducible, i.e. every retreating edge
  /// is a back-edge whose target dominates its source.
  bool get isReducible {
    for (final block in preorder) {
      for (final pred in block.predecessors) {
        if (pred != block &&
            pred.postorderNumber < block.postorderNumber &&
            !pred.isDominatedBy(block)) {
          return false;
        }
      }
    }
    return true;
  }
}
