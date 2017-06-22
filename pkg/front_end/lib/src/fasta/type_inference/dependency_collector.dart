// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:kernel/ast.dart' show Expression;

/// Keeps track of state while determining whether an expression has an
/// immediately evident type, and if so what its dependencies are.
///
/// This class describes the interface for use by clients of type inference.
/// The implementation is in [DependencyCollectorImpl].
abstract class DependencyCollector {
  /// Collects any dependencies of [expression], and reports errors if the
  /// expression does not have an immediately evident type.
  void collectDependencies(Expression expression);
}

/// Generic implementation of [DependencyCollectorImpl].
///
/// This class contains all of the implementation of [DependencyCollector] which
/// can be expressed without the need to reference private data structures in
/// the shadow hierarchy.
abstract class DependencyCollectorImpl extends DependencyCollector {
  List<AccessorNode> dependencies = [];

  bool isImmediatelyEvident = true;

  void recordDependency(AccessorNode accessorNode) {
    dependencies.add(accessorNode);
  }

  void recordNotImmediatelyEvident(int fileOffset) {
    isImmediatelyEvident = false;
    // TODO(paulberry): report an error.
  }
}
