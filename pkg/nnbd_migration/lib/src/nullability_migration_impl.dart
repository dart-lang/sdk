// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_builder.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';
import 'package:nnbd_migration/src/variables.dart';

/// Implementation of the [NullabilityMigration] public API.
class NullabilityMigrationImpl implements NullabilityMigration {
  final NullabilityMigrationListener listener;

  final Variables _variables;

  final NullabilityGraph _graph;

  final bool _permissive;

  /// Prepares to perform nullability migration.
  ///
  /// If [permissive] is `true`, exception handling logic will try to proceed
  /// as far as possible even though the migration algorithm is not yet
  /// complete.  TODO(paulberry): remove this mode once the migration algorithm
  /// is fully implemented.
  NullabilityMigrationImpl(NullabilityMigrationListener listener,
      {bool permissive: false})
      : this._(listener, NullabilityGraph(), permissive);

  NullabilityMigrationImpl._(this.listener, this._graph, this._permissive)
      : _variables = Variables(_graph);

  void finish() {
    _graph.propagate();
    for (var entry in _variables.getPotentialModifications().entries) {
      var source = entry.key;
      for (var potentialModification in entry.value) {
        var fix = _SingleNullabilityFix(source, potentialModification);
        listener.addFix(fix);
        for (var edit in potentialModification.modifications) {
          listener.addEdit(fix, edit);
        }
      }
    }
  }

  void prepareInput(ResolvedUnitResult result) {
    var unit = result.unit;
    unit.accept(NodeBuilder(_variables, unit.declaredElement.source,
        _permissive ? listener : null, _graph, result.typeProvider));
  }

  void processInput(ResolvedUnitResult result) {
    var unit = result.unit;
    unit.accept(EdgeBuilder(result.typeProvider, result.typeSystem, _variables,
        _graph, unit.declaredElement.source, _permissive ? listener : null));
  }
}

/// Implementation of [SingleNullabilityFix] used internally by
/// [NullabilityMigration].
class _SingleNullabilityFix extends SingleNullabilityFix {
  @override
  final Source source;

  @override
  final NullabilityFixKind kind;

  factory _SingleNullabilityFix(
      Source source, PotentialModification potentialModification) {
    // TODO(paulberry): once everything is migrated into the analysis server,
    // the migration engine can just create SingleNullabilityFix objects
    // directly and set their kind appropriately; we won't need to translate the
    // kinds using a bunch of `is` checks.
    NullabilityFixKind kind;
    if (potentialModification is ExpressionChecks) {
      kind = NullabilityFixKind.checkExpression;
    } else if (potentialModification is DecoratedTypeAnnotation) {
      kind = NullabilityFixKind.makeTypeNullable;
    } else if (potentialModification is ConditionalModification) {
      kind = potentialModification.discard.keepFalse
          ? NullabilityFixKind.discardThen
          : NullabilityFixKind.discardElse;
    } else if (potentialModification is PotentiallyAddImport) {
      kind = NullabilityFixKind.addImport;
    } else if (potentialModification is PotentiallyAddRequired) {
      kind = NullabilityFixKind.addRequired;
    } else {
      throw new UnimplementedError('TODO(paulberry)');
    }

    Location location;

    // TODO(devoncarew): Calculate line and column info from the source+offset.
    if (potentialModification.modifications.isNotEmpty) {
      location = new Location(
        source.fullName,
        potentialModification.modifications.first.offset,
        potentialModification.modifications.first.length,
        0, // TODO(devoncarew): calculate the startLine info
        0, // TODO(devoncarew): calculate the startColumn info
      );
    }

    return _SingleNullabilityFix._(source, kind, location: location);
  }

  _SingleNullabilityFix._(this.source, this.kind, {Location location})
      : this._location = location;

  Location get location => _location;

  Location _location;
}
