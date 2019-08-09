// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
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
    if (_graph.unsatisfiedSubstitutions.isNotEmpty) {
      throw new UnimplementedError('Need to report unsatisfied substitutions');
    }
    // TODO(paulberry): it would be nice to report on unsatisfied edges as well,
    // however, since every `!` we add has an unsatisfied edge associated with
    // it, we can't report on every unsatisfied edge.  We need to figure out a
    // way to report unsatisfied edges that isn't too overwhelming.
    broadcast(_variables, listener);
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

  @visibleForTesting
  static void broadcast(
      Variables variables, NullabilityMigrationListener listener) {
    for (var entry in variables.getPotentialModifications().entries) {
      var source = entry.key;
      final lineInfo = LineInfo.fromContent(source.contents.data);
      for (var potentialModification in entry.value) {
        var modifications = potentialModification.modifications;
        if (modifications.isEmpty) {
          continue;
        }
        var fix =
            _SingleNullabilityFix(source, potentialModification, lineInfo);
        listener.addFix(fix);
        for (var edit in modifications) {
          listener.addEdit(fix, edit);
        }
      }
    }
  }
}

/// Implementation of [SingleNullabilityFix] used internally by
/// [NullabilityMigration].
class _SingleNullabilityFix extends SingleNullabilityFix {
  @override
  final Source source;

  @override
  final NullabilityFixDescription description;

  Location _location;

  factory _SingleNullabilityFix(Source source,
      PotentialModification potentialModification, LineInfo lineInfo) {
    // TODO(paulberry): once everything is migrated into the analysis server,
    // the migration engine can just create SingleNullabilityFix objects
    // directly and set their kind appropriately; we won't need to translate the
    // kinds using a bunch of `is` checks.
    NullabilityFixDescription desc;
    if (potentialModification is ExpressionChecks) {
      desc = NullabilityFixDescription.checkExpression;
    } else if (potentialModification is DecoratedTypeAnnotation) {
      desc = NullabilityFixDescription.makeTypeNullable(
          potentialModification.type.toString());
    } else if (potentialModification is ConditionalModification) {
      desc = potentialModification.discard.keepFalse
          ? NullabilityFixDescription.discardThen
          : NullabilityFixDescription.discardElse;
    } else if (potentialModification is PotentiallyAddImport) {
      desc =
          NullabilityFixDescription.addImport(potentialModification.importPath);
    } else if (potentialModification is PotentiallyAddRequired) {
      desc = NullabilityFixDescription.addRequired(
          potentialModification.className,
          potentialModification.methodName,
          potentialModification.parameterName);
    } else {
      throw new UnimplementedError('TODO(paulberry)');
    }

    Location location;

    if (potentialModification.modifications.isNotEmpty) {
      final locationInfo = lineInfo
          .getLocation(potentialModification.modifications.first.offset);
      location = new Location(
        source.fullName,
        potentialModification.modifications.first.offset,
        potentialModification.modifications.first.length,
        locationInfo.lineNumber,
        locationInfo.columnNumber,
      );
    }

    return _SingleNullabilityFix._(source, desc, location: location);
  }

  _SingleNullabilityFix._(this.source, this.description, {Location location})
      : this._location = location;

  Location get location => _location;
}
