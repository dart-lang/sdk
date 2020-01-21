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

  /// Indicates whether code removed by the migration engine should be removed
  /// by commenting it out.  A value of `false` means to actually delete the
  /// code that is removed.
  final bool removeViaComments;

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
  NullabilityMigrationImpl(NullabilityMigrationListener listener,
      {bool permissive: false,
      NullabilityMigrationInstrumentation instrumentation,
      bool useFixBuilder: false,
      bool removeViaComments = false})
      : this._(listener, NullabilityGraph(instrumentation: instrumentation),
            permissive, instrumentation, useFixBuilder, removeViaComments);

  NullabilityMigrationImpl._(this.listener, this._graph, this._permissive,
      this._instrumentation, this.useFixBuilder, this.removeViaComments) {
    _instrumentation?.immutableNodes(_graph.never, _graph.always);
  }

  @visibleForTesting
  void broadcast(Variables variables, NullabilityMigrationListener listener,
      NullabilityMigrationInstrumentation instrumentation) {
    assert(!useFixBuilder);
    for (var entry in variables.getPotentialModifications().entries) {
      var source = entry.key;
      final lineInfo = LineInfo.fromContent(source.contents.data);
      var changes = <int, List<AtomicEdit>>{};
      for (var potentialModification in entry.value) {
        var modifications = potentialModification.modifications;
        if (modifications.isEmpty) {
          continue;
        }
        var description = potentialModification.description;
        var info =
            AtomicEditInfo(description, potentialModification.reasons.toList());
        var atomicEditsByLocation = _gatherAtomicEditsByLocation(
            source, potentialModification, lineInfo, info);
        for (var entry in atomicEditsByLocation) {
          var location = entry.key;
          listener.addSuggestion(description.appliedMessage, location);
          changes[location.offset] = [entry.value];
        }
        for (var edit in modifications) {
          listener.addEdit(source, edit);
        }
      }
      instrumentation?.changes(source, changes);
    }
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
    var changes = FixAggregator.run(unit, result.content, fixBuilder.changes,
        removeViaComments: removeViaComments);
    _instrumentation?.changes(source, changes);
    final lineInfo = LineInfo.fromContent(source.contents.data);
    var offsets = changes.keys.toList();
    offsets.sort();
    for (var offset in offsets) {
      var edits = changes[offset];
      var descriptions = edits
          .whereType<AtomicEditWithInfo>()
          .map((edit) => edit.info.description.appliedMessage)
          .join(', ');
      var sourceEdit = edits.toSourceEdit(offset);
      listener.addSuggestion(
          descriptions, _computeLocation(lineInfo, sourceEdit, source));
      listener.addEdit(source, sourceEdit);
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

  static Location _computeLocation(
      LineInfo lineInfo, SourceEdit edit, Source source) {
    final locationInfo = lineInfo.getLocation(edit.offset);
    var location = new Location(
      source.fullName,
      edit.offset,
      edit.length,
      locationInfo.lineNumber,
      locationInfo.columnNumber,
    );
    return location;
  }

  static List<MapEntry<Location, AtomicEditWithInfo>>
      _gatherAtomicEditsByLocation(
          Source source,
          PotentialModification potentialModification,
          LineInfo lineInfo,
          AtomicEditInfo info) {
    List<MapEntry<Location, AtomicEditWithInfo>> result = [];

    for (var modification in potentialModification.modifications) {
      var atomicEditWithInfo = AtomicEditWithInfo.replace(
          modification.length, modification.replacement, info);
      result.add(MapEntry(_computeLocation(lineInfo, modification, source),
          atomicEditWithInfo));
    }
    return result;
  }
}
