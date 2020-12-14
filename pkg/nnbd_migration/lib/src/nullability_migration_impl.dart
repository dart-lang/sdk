// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_builder.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/exceptions.dart';
import 'package:nnbd_migration/src/fix_aggregator.dart';
import 'package:nnbd_migration/src/fix_builder.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/postmortem_file.dart';
import 'package:nnbd_migration/src/variables.dart';
import 'package:pub_semver/pub_semver.dart';

/// Implementation of the [NullabilityMigration] public API.
class NullabilityMigrationImpl implements NullabilityMigration {
  /// Set this constant to a pathname to cause nullability migration to output
  /// a post-mortem file that can be later examined by tool/postmortem.dart.
  static const String _postmortemPath = null;

  final NullabilityMigrationListener listener;

  Variables _variables;

  final NullabilityGraph _graph;

  final bool _permissive;

  final NullabilityMigrationInstrumentation _instrumentation;

  DecoratedClassHierarchy _decoratedClassHierarchy;

  bool _propagated = false;

  /// Indicates whether code removed by the migration engine should be removed
  /// by commenting it out.  A value of `false` means to actually delete the
  /// code that is removed.
  final bool removeViaComments;

  final bool warnOnWeakCode;

  final _decoratedTypeParameterBounds = DecoratedTypeParameterBounds();

  /// If not `null`, the object that will be used to write out post-mortem
  /// information once migration is complete.
  final PostmortemFileWriter _postmortemFileWriter =
      _makePostmortemFileWriter();

  final LineInfo Function(String) _getLineInfo;

  /// Map from [Source] object to a boolean indicating whether the source is
  /// opted in to null safety.
  final Map<Source, bool> _libraryOptInStatus = {};

  /// Indicates whether the client has used the [unmigratedDependencies] getter.
  bool _queriedUnmigratedDependencies = false;

  /// Map of additional package dependencies that will be required by the
  /// migrated code.  Keys are package names; values indicate the minimum
  /// required version of each package.
  final Map<String, Version> _neededPackages = {};

  /// Prepares to perform nullability migration.
  ///
  /// If [permissive] is `true`, exception handling logic will try to proceed
  /// as far as possible even though the migration algorithm is not yet
  /// complete.  TODO(paulberry): remove this mode once the migration algorithm
  /// is fully implemented.
  ///
  /// Optional parameter [removeViaComments] indicates whether code that the
  /// migration tool wishes to remove should instead be commenting it out.
  ///
  /// Optional parameter [warnOnWeakCode] indicates whether weak-only code
  /// should be warned about or removed (in the way specified by
  /// [removeViaComments]).
  NullabilityMigrationImpl(NullabilityMigrationListener listener,
      LineInfo Function(String) getLineInfo,
      {bool permissive = false,
      NullabilityMigrationInstrumentation instrumentation,
      bool removeViaComments = false,
      bool warnOnWeakCode = true})
      : this._(
            listener,
            NullabilityGraph(instrumentation: instrumentation),
            permissive,
            instrumentation,
            removeViaComments,
            warnOnWeakCode,
            getLineInfo);

  NullabilityMigrationImpl._(
      this.listener,
      this._graph,
      this._permissive,
      this._instrumentation,
      this.removeViaComments,
      this.warnOnWeakCode,
      this._getLineInfo) {
    _instrumentation?.immutableNodes(_graph.never, _graph.always);
    _postmortemFileWriter?.graph = _graph;
  }

  @override
  bool get isPermissive => _permissive;

  @override
  List<String> get unmigratedDependencies {
    _queriedUnmigratedDependencies = true;
    var unmigratedDependencies = <Source>[];
    for (var entry in _libraryOptInStatus.entries) {
      if (_graph.isBeingMigrated(entry.key)) continue;
      if (!entry.value) {
        unmigratedDependencies.add(entry.key);
      }
    }
    var badUris = {
      for (var dependency in unmigratedDependencies) dependency.uri.toString()
    }.toList();
    badUris.sort();
    return badUris;
  }

  @override
  void finalizeInput(ResolvedUnitResult result) {
    if (result.unit.featureSet.isEnabled(Feature.non_nullable)) {
      // This library has already been migrated; nothing more to do.
      return;
    }
    ExperimentStatusException.sanityCheck(result);
    if (!_propagated) {
      _propagated = true;
      _graph.propagate(_postmortemFileWriter);
    }
    var unit = result.unit;
    var compilationUnit = unit.declaredElement;
    var library = compilationUnit.library;
    var source = compilationUnit.source;
    // Hierarchies were created assuming the libraries being migrated are opted
    // out, but the FixBuilder will analyze assuming they're opted in.  So we
    // need to clear the hierarchies before we continue.
    (result.session as AnalysisSessionImpl).clearHierarchies();
    var fixBuilder = FixBuilder(
        source,
        _decoratedClassHierarchy,
        result.typeProvider,
        library.typeSystem as TypeSystemImpl,
        _variables,
        library,
        _permissive ? listener : null,
        unit,
        warnOnWeakCode,
        _graph,
        _neededPackages);
    try {
      DecoratedTypeParameterBounds.current = _decoratedTypeParameterBounds;
      fixBuilder.visitAll();
    } finally {
      DecoratedTypeParameterBounds.current = null;
    }
    var changes = FixAggregator.run(unit, result.content, fixBuilder.changes,
        removeViaComments: removeViaComments, warnOnWeakCode: warnOnWeakCode);
    _instrumentation?.changes(source, changes);
    final lineInfo = LineInfo.fromContent(source.contents.data);
    var offsets = changes.keys.toList();
    offsets.sort();
    for (var offset in offsets) {
      var edits = changes[offset];
      var descriptions = edits
          .map((edit) => edit.info)
          .where((info) => info != null)
          .map((info) => info.description.appliedMessage)
          .join(', ');
      var sourceEdit = edits.toSourceEdit(offset);
      listener.addSuggestion(
          descriptions, _computeLocation(lineInfo, sourceEdit, source));
      listener.addEdit(source, sourceEdit);
    }
  }

  Map<String, Version> finish() {
    _postmortemFileWriter?.write();
    _instrumentation?.finished();
    return _neededPackages;
  }

  void prepareInput(ResolvedUnitResult result) {
    assert(
        !_queriedUnmigratedDependencies,
        'Should only query unmigratedDependencies after all calls to '
        'prepareInput');
    if (result.unit.featureSet.isEnabled(Feature.non_nullable)) {
      // This library has already been migrated; nothing more to do.
      return;
    }
    ExperimentStatusException.sanityCheck(result);
    _recordTransitiveImportExportOptInStatus(
        result.libraryElement.importedLibraries);
    _recordTransitiveImportExportOptInStatus(
        result.libraryElement.exportedLibraries);
    if (_variables == null) {
      _variables = Variables(_graph, result.typeProvider, _getLineInfo,
          instrumentation: _instrumentation,
          postmortemFileWriter: _postmortemFileWriter);
      _decoratedClassHierarchy = DecoratedClassHierarchy(_variables, _graph);
    }
    var unit = result.unit;
    try {
      DecoratedTypeParameterBounds.current = _decoratedTypeParameterBounds;
      unit.accept(NodeBuilder(
          _variables,
          unit.declaredElement.source,
          _permissive ? listener : null,
          _graph,
          result.typeProvider,
          _getLineInfo,
          instrumentation: _instrumentation));
    } finally {
      DecoratedTypeParameterBounds.current = null;
    }
  }

  void processInput(ResolvedUnitResult result) {
    if (result.unit.featureSet.isEnabled(Feature.non_nullable)) {
      // This library has already been migrated; nothing more to do.
      return;
    }
    ExperimentStatusException.sanityCheck(result);
    var unit = result.unit;
    try {
      DecoratedTypeParameterBounds.current = _decoratedTypeParameterBounds;
      unit.accept(EdgeBuilder(
          result.typeProvider,
          result.typeSystem,
          _variables,
          _graph,
          unit.declaredElement.source,
          _permissive ? listener : null,
          _decoratedClassHierarchy,
          instrumentation: _instrumentation));
    } finally {
      DecoratedTypeParameterBounds.current = null;
    }
  }

  @override
  void update() {
    _graph.update(_postmortemFileWriter);
  }

  /// Records the opt in/out status of all libraries in [libraries], and any
  /// libraries they transitively import or export, in [_libraryOptInStatus].
  void _recordTransitiveImportExportOptInStatus(
      Iterable<LibraryElement> libraries) {
    var librariesToCheck = libraries.toList();
    while (librariesToCheck.isNotEmpty) {
      var library = librariesToCheck.removeLast();
      if (_libraryOptInStatus.containsKey(library.source)) continue;
      _libraryOptInStatus[library.source] = library.isNonNullableByDefault;
      librariesToCheck.addAll(library.importedLibraries);
      librariesToCheck.addAll(library.exportedLibraries);
    }
  }

  static Location _computeLocation(
      LineInfo lineInfo, SourceEdit edit, Source source) {
    final locationInfo = lineInfo.getLocation(edit.offset);
    var location = Location(
      source.fullName,
      edit.offset,
      edit.length,
      locationInfo.lineNumber,
      locationInfo.columnNumber,
    );
    return location;
  }

  static PostmortemFileWriter _makePostmortemFileWriter() {
    if (_postmortemPath == null) return null;
    return PostmortemFileWriter(
        PhysicalResourceProvider.INSTANCE.getFile(_postmortemPath));
  }
}
