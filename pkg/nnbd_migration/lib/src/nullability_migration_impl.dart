// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/edge_builder.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/fix_aggregator.dart';
import 'package:nnbd_migration/src/fix_builder.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';
import 'package:nnbd_migration/src/variables.dart';

/// Implementation of the [NullabilityMigration] public API.
class NullabilityMigrationImpl implements NullabilityMigration {
  final NullabilityMigrationListener listener;

  Variables _variables;

  final NullabilityGraph _graph;

  final bool _permissive;

  final NullabilityMigrationInstrumentation _instrumentation;

  DecoratedClassHierarchy _decoratedClassHierarchy;

  bool _propagated = false;

  /// Indicates whether migration should use the new [FixBuilder]
  /// infrastructure.  Once FixBuilder is at feature parity with the old
  /// implementation, this option will be removed and FixBuilder will be used
  /// unconditionally.
  ///
  /// Currently defaults to `false`.
  final bool useFixBuilder;

  /// Prepares to perform nullability migration.
  ///
  /// If [permissive] is `true`, exception handling logic will try to proceed
  /// as far as possible even though the migration algorithm is not yet
  /// complete.  TODO(paulberry): remove this mode once the migration algorithm
  /// is fully implemented.
  ///
  /// [useFixBuilder] indicates whether migration should use the new
  /// [FixBuilder] infrastructure.  Once FixBuilder is at feature parity with
  /// the old implementation, this option will be removed and FixBuilder will
  /// be used unconditionally.
  ///
  /// Optional parameter [removeViaComments] indicates whether dead code should
  /// be removed in its entirety (the default) or removed by commenting it out.
  /// TODO(paulberry): wire this up.
  NullabilityMigrationImpl(NullabilityMigrationListener listener,
      {bool permissive: false,
      NullabilityMigrationInstrumentation instrumentation,
      bool useFixBuilder: false,
      bool removeViaComments = false})
      : this._(listener, NullabilityGraph(instrumentation: instrumentation),
            permissive, instrumentation, useFixBuilder);

  NullabilityMigrationImpl._(this.listener, this._graph, this._permissive,
      this._instrumentation, this.useFixBuilder) {
    _instrumentation?.immutableNodes(_graph.never, _graph.always);
  }

  @override
  void finalizeInput(ResolvedUnitResult result) {
    if (!useFixBuilder) return;
    if (!_propagated) {
      _propagated = true;
      _graph.propagate();
    }
    var unit = result.unit;
    var compilationUnit = unit.declaredElement;
    var library = compilationUnit.library;
    var source = compilationUnit.source;
    var fixBuilder = FixBuilder(
        source,
        _decoratedClassHierarchy,
        result.typeProvider,
        library.typeSystem as Dart2TypeSystem,
        _variables,
        library);
    fixBuilder.visitAll(unit);
    var changes = FixAggregator.run(unit, result.content, fixBuilder.changes);
    for (var entry in changes.entries) {
      final lineInfo = LineInfo.fromContent(source.contents.data);
      var fix = _SingleNullabilityFix(
          source, const _DummyPotentialModification(), lineInfo);
      listener.addFix(fix);
      var edits = entry.value;
      _instrumentation?.fix(
          fix,
          edits
              .whereType<AtomicEditWithReason>()
              .map((edit) => edit.fixReason));
      listener.addEdit(fix, edits.toSourceEdit(entry.key));
    }
  }

  void finish() {
    if (useFixBuilder) return;
    _graph.propagate();
    if (_graph.unsatisfiedSubstitutions.isNotEmpty) {
      // TODO(paulberry): for now we just ignore unsatisfied substitutions, to
      // work around https://github.com/dart-lang/sdk/issues/38257
      // throw new UnimplementedError('Need to report unsatisfied substitutions');
    }
    // TODO(paulberry): it would be nice to report on unsatisfied edges as well,
    // however, since every `!` we add has an unsatisfied edge associated with
    // it, we can't report on every unsatisfied edge.  We need to figure out a
    // way to report unsatisfied edges that isn't too overwhelming.
    if (_variables != null) {
      broadcast(_variables, listener, _instrumentation);
    }
  }

  void prepareInput(ResolvedUnitResult result) {
    if (_variables == null) {
      _variables = Variables(_graph, result.typeProvider,
          instrumentation: _instrumentation);
      _decoratedClassHierarchy = DecoratedClassHierarchy(_variables, _graph);
    }
    var unit = result.unit;
    unit.accept(NodeBuilder(_variables, unit.declaredElement.source,
        _permissive ? listener : null, _graph, result.typeProvider,
        instrumentation: _instrumentation));
  }

  void processInput(ResolvedUnitResult result) {
    var unit = result.unit;
    unit.accept(EdgeBuilder(
        result.typeProvider,
        result.typeSystem,
        _variables,
        _graph,
        unit.declaredElement.source,
        _permissive ? listener : null,
        _decoratedClassHierarchy,
        instrumentation: _instrumentation));
  }

  @visibleForTesting
  static void broadcast(
      Variables variables,
      NullabilityMigrationListener listener,
      NullabilityMigrationInstrumentation instrumentation) {
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
        instrumentation?.fix(fix, potentialModification.reasons);
        for (var edit in modifications) {
          listener.addEdit(fix, edit);
        }
      }
    }
  }
}

/// Dummy implementation of [PotentialModification] used as a temporary bridge
/// between the old pre-FixBuilder logic and the new FixBuilder logic (which
/// doesn't use [PotentialModification]).
///
/// TODO(paulberry): once we've fully migrated over to the new logic, this class
/// should go away (as should [PotentialModification]).
class _DummyPotentialModification implements PotentialModification {
  const _DummyPotentialModification();

  @override
  NullabilityFixDescription get description => null;

  @override
  Iterable<SourceEdit> get modifications => const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Implementation of [SingleNullabilityFix] used internally by
/// [NullabilityMigration].
class _SingleNullabilityFix extends SingleNullabilityFix {
  @override
  final Source source;

  @override
  final NullabilityFixDescription description;

  List<Location> _locations;

  factory _SingleNullabilityFix(Source source,
      PotentialModification potentialModification, LineInfo lineInfo) {
    List<Location> locations = [];

    for (var modification in potentialModification.modifications) {
      final locationInfo = lineInfo.getLocation(modification.offset);
      locations.add(new Location(
        source.fullName,
        modification.offset,
        modification.length,
        locationInfo.lineNumber,
        locationInfo.columnNumber,
      ));
    }

    return _SingleNullabilityFix._(source, potentialModification.description,
        locations: locations);
  }

  _SingleNullabilityFix._(this.source, this.description,
      {List<Location> locations})
      : this._locations = locations;

  List<Location> get locations => _locations;
}
