// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines wrapper class around incremental compiler to support
/// the flow, where incremental deltas can be rejected by VM.
library;

import 'dart:async';
import 'dart:developer';

import 'package:front_end/src/api_unstable/vm.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/kernel.dart';

const String kDebugProcedureName = ":Eval";

/// Wrapper around [IncrementalKernelGenerator] that keeps track of rejected
/// deltas and combines them together into resultant program until it is
/// accepted.
class IncrementalCompiler {
  late IncrementalKernelGenerator _generator;
  IncrementalSerializer? incrementalSerializer;

  // Component that reflect the state that was most recently accepted by the
  // client. Is [null], if no compilation results were accepted by the client.
  IncrementalCompilerResult? _lastKnownGood;
  late List<IncrementalCompilerResult> _pendingDeltas;
  CompilerOptions _compilerOptions;
  bool initialized = false;
  bool fullComponent = false;
  Uri? initializeFromDillUri;
  List<Uri> _latestAcceptedEntryPoints;
  List<Uri> _latestUsedEntryPoints;
  final bool forExpressionCompilationOnly;

  List<Uri> get entryPoints => _latestAcceptedEntryPoints;
  IncrementalKernelGenerator get generator => _generator;
  IncrementalCompilerResult? get lastKnownGoodResult => _lastKnownGood;

  IncrementalCompiler(
    this._compilerOptions,
    this._latestAcceptedEntryPoints, {
    this.initializeFromDillUri,
    bool incrementalSerialization = true,
  }) : forExpressionCompilationOnly = false,
       _latestUsedEntryPoints = _latestAcceptedEntryPoints {
    if (incrementalSerialization) {
      incrementalSerializer = new IncrementalSerializer();
    }
    _generator = new IncrementalKernelGenerator(
      _compilerOptions,
      _latestAcceptedEntryPoints,
      initializeFromDillUri,
      false,
      incrementalSerializer,
    );
    _pendingDeltas = <IncrementalCompilerResult>[];
  }

  IncrementalCompiler.forExpressionCompilationOnly(
    Component component,
    this._compilerOptions,
    this._latestAcceptedEntryPoints,
  ) : forExpressionCompilationOnly = true,
      _latestUsedEntryPoints = _latestAcceptedEntryPoints {
    _generator = new IncrementalKernelGenerator.forExpressionCompilationOnly(
      _compilerOptions,
      _latestAcceptedEntryPoints,
      component,
    );
    _pendingDeltas = <IncrementalCompilerResult>[];
  }

  /// Recompiles invalidated files, produces incremental component.
  ///
  /// If [entryPoints] is specified, that points to the new list of entry
  /// points for the compilation. Otherwise, previously set entryPoints are
  /// used.
  Future<IncrementalCompilerResult> compile({List<Uri>? entryPoints}) async {
    final task = new TimelineTask();
    try {
      task.start("IncrementalCompiler.compile");
      _latestUsedEntryPoints = entryPoints ?? _latestAcceptedEntryPoints;
      IncrementalCompilerResult compilerResult = await _generator.computeDelta(
        entryPoints: _latestUsedEntryPoints,
        fullComponent: fullComponent,
      );
      initialized = true;
      fullComponent = false;
      _pendingDeltas.add(compilerResult);
      return _combinePendingDeltas(false);
    } finally {
      task.finish();
    }
  }

  IncrementalCompilerResult _combinePendingDeltas(bool includePlatform) {
    assert(_pendingDeltas.isNotEmpty);
    Procedure? mainMethod;
    Map<Uri, Library> combined = <Uri, Library>{};
    Map<Uri, Source> uriToSource = new Map<Uri, Source>();
    ClassHierarchy classHierarchy = _pendingDeltas.last.classHierarchy;
    CoreTypes coreTypes = _pendingDeltas.last.coreTypes;
    for (IncrementalCompilerResult deltaResult in _pendingDeltas) {
      Component delta = deltaResult.component;
      if (delta.mainMethod != null) {
        mainMethod = delta.mainMethod;
      }
      uriToSource.addAll(delta.uriToSource);
      for (Library library in delta.libraries) {
        bool isPlatform =
            library.importUri.isScheme("dart") && !library.isSynthetic;
        if (!includePlatform && isPlatform) continue;
        combined[library.importUri] = library;
      }
    }

    // TODO(vegorov) this needs to merge metadata repositories from deltas.
    final result = new IncrementalCompilerResult(
      new Component(
        libraries: combined.values.toList(),
        uriToSource: uriToSource,
      )..setMainMethodAndMode(mainMethod?.reference, true),
      classHierarchy: classHierarchy,
      coreTypes: coreTypes,
    );
    if (_pendingDeltas.length == 1) {
      // With only one delta to "merge" we can copy over the metadata.
      result.component.metadata.addAll(
        _pendingDeltas.single.component.metadata,
      );
    }
    return result;
  }

  /// This lets incremental compiler know that results of last [compile] call
  /// were accepted, don't need to be included into subsequent [compile] calls
  /// results.
  accept() {
    if (forExpressionCompilationOnly) {
      throw new StateError(
        "Incremental compiler created for expression "
        "compilation only; cannot accept",
      );
    }
    if (_pendingDeltas.isEmpty) return;
    Map<Uri, Library> combined = <Uri, Library>{};
    Map<Uri, Source> uriToSource = <Uri, Source>{};

    IncrementalCompilerResult? lastKnownGood = _lastKnownGood;
    if (lastKnownGood != null) {
      // TODO(aam): Figure out how to skip no-longer-used libraries from
      // [_lastKnownGood] libraries.
      for (Library library in lastKnownGood.component.libraries) {
        combined[library.importUri] = library;
      }
      uriToSource.addAll(lastKnownGood.component.uriToSource);
    }

    IncrementalCompilerResult result = _combinePendingDeltas(true);
    Component candidate = result.component;
    for (Library library in candidate.libraries) {
      combined[library.importUri] = library;
    }
    uriToSource.addAll(candidate.uriToSource);

    _lastKnownGood =
        lastKnownGood = new IncrementalCompilerResult(
          new Component(
            libraries: combined.values.toList(),
            uriToSource: uriToSource,
          )..setMainMethodAndMode(candidate.mainMethod?.reference, true),
          classHierarchy: result.classHierarchy,
          coreTypes: result.coreTypes,
        );
    for (final repo in candidate.metadata.values) {
      lastKnownGood.component.addMetadataRepository(repo);
    }
    _pendingDeltas.clear();

    _latestAcceptedEntryPoints = _latestUsedEntryPoints;
  }

  /// This lets incremental compiler know that results of last [compile] call
  /// were rejected. Subsequent [compile] or [compileExpression] calls need to
  /// be processed without changes picked up by rejected [compile] call.
  reject() async {
    if (forExpressionCompilationOnly) {
      throw new StateError(
        "Incremental compiler created for expression "
        "compilation only; cannot reject",
      );
    }
    _pendingDeltas.clear();
    // Need to reset and warm up compiler so that expression evaluation requests
    // are processed in that known good state.
    if (incrementalSerializer != null) {
      incrementalSerializer = new IncrementalSerializer();
    }
    // Make sure the last known good component is linked to itself, i.e. if the
    // rejected delta was an "advanced incremental recompilation" that updated
    // old libraries to point to a new library (that we're now rejecting), make
    // sure it's "updated back".
    // Note that if accept was never called [_lastKnownGood] is null (and
    // loading from it below is basically nonsense, it will just start over).
    _lastKnownGood?.component.relink();

    _generator = new IncrementalKernelGenerator.fromComponent(
      _compilerOptions,
      _latestAcceptedEntryPoints,
      _lastKnownGood?.component,
      false,
      incrementalSerializer,
    );
    var compilerResult = await _generator.computeDelta(
      entryPoints: _latestAcceptedEntryPoints,
    );
    // Make '_lastKnownGood' up-to-date.
    _lastKnownGood = null;
    _pendingDeltas.add(compilerResult);
    accept();
  }

  /// This tells incremental compiler that it needs rescan [uri] file during
  /// next [compile] call.
  invalidate(Uri uri) {
    _generator.invalidate(uri);
  }

  resetDeltaState() {
    _pendingDeltas.clear();
    fullComponent = true;
  }

  Future<Procedure?> compileExpression(
    String expression,
    List<String> definitions,
    List<String> definitionTypes,
    List<String> typeDefinitions,
    List<String> typeBounds,
    List<String> typeDefaults,
    String libraryUri,
    String? klass,
    String? method,
    int offset,
    String? scriptUri,
    bool isStatic,
  ) {
    assert(_lastKnownGood != null || _pendingDeltas.isNotEmpty);
    ClassHierarchy classHierarchy =
        (_lastKnownGood ?? _combinePendingDeltas(false)).classHierarchy;
    Map<String, DartType>? completeDefinitions = createDefinitionsWithTypes(
      classHierarchy.knownLibraries,
      definitionTypes,
      definitions,
    );
    if (completeDefinitions == null) {
      completeDefinitions = {};
      // No class hierarchy or wasn't provided correct types.
      // Revert to old behaviour of setting everything to dynamic.
      for (int i = 0; i < definitions.length; i++) {
        String name = definitions[i];
        if (isLegalIdentifier(name) || isExtensionThisName(name)) {
          completeDefinitions[name] = new DynamicType();
        }
      }
    }

    List<TypeParameter>? typeParameters = createTypeParametersWithBounds(
      classHierarchy.knownLibraries,
      typeBounds,
      typeDefaults,
      typeDefinitions,
    );
    if (typeParameters == null) {
      // No class hierarchy or wasn't provided correct types.
      // Revert to old behaviour of setting everything to dynamic.
      typeParameters = [];
      for (String name in typeDefinitions) {
        if (!isLegalIdentifier(name)) continue;
        typeParameters.add(new TypeParameter(name, new DynamicType()));
      }
    }

    Uri library = Uri.parse(libraryUri);

    return _generator.compileExpression(
      expression,
      completeDefinitions,
      typeParameters,
      kDebugProcedureName,
      library,
      className: klass,
      methodName: method,
      offset: offset,
      scriptUri: scriptUri,
      isStatic: isStatic,
    );
  }
}
