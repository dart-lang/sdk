// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/graph_builder.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';
import 'package:nnbd_migration/src/variables.dart';

/// Transitional migration API.
///
/// Usage: pass each input source file to [prepareInput].  Then pass each input
/// source file to [processInput].  Then call [finish] to obtain the
/// modifications that need to be made to each source file.
///
/// TODO(paulberry): this implementation keeps a lot of CompilationUnit objects
/// around.  Can we do better?
class NullabilityMigration {
  final NullabilityMigrationListener /*?*/ listener;

  final Variables _variables;

  final NullabilityGraph _graph;

  /// Prepares to perform nullability migration.
  ///
  /// If [permissive] is `true`, exception handling logic will try to proceed
  /// as far as possible even though the migration algorithm is not yet
  /// complete.  TODO(paulberry): remove this mode once the migration algorithm
  /// is fully implemented.
  NullabilityMigration(NullabilityMigrationListener /*?*/ listener)
      : this._(listener, NullabilityGraph());

  NullabilityMigration._(this.listener, this._graph) : _variables = Variables();

  Map<Source, List<PotentialModification>> finish() {
    _graph.propagate();
    return _variables.getPotentialModifications();
  }

  void prepareInput(CompilationUnit unit, TypeProvider typeProvider) {
    unit.accept(NodeBuilder(_variables, unit.declaredElement.source, listener,
        _graph, typeProvider));
  }

  void processInput(CompilationUnit unit, TypeProvider typeProvider) {
    unit.accept(GraphBuilder(typeProvider, _variables, _graph,
        unit.declaredElement.source, listener));
  }
}
