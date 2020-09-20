// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines wrapper class around incremental compiler to support
/// the flow, where incremental deltas can be rejected by VM.
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
  IncrementalKernelGenerator _generator;
  IncrementalSerializer incrementalSerializer;

  // Component that reflect the state that was most recently accepted by the
  // client. Is [null], if no compilation results were accepted by the client.
  Component _lastKnownGood;
  List<Component> _pendingDeltas;
  CompilerOptions _compilerOptions;
  bool initialized = false;
  bool fullComponent = false;
  Uri initializeFromDillUri;
  Uri _entryPoint;
  final bool forExpressionCompilationOnly;

  Uri get entryPoint => _entryPoint;
  IncrementalKernelGenerator get generator => _generator;
  Component get lastKnownGoodComponent => _lastKnownGood;

  IncrementalCompiler(this._compilerOptions, this._entryPoint,
      {this.initializeFromDillUri, bool incrementalSerialization: true})
      : forExpressionCompilationOnly = false {
    if (incrementalSerialization) {
      incrementalSerializer = new IncrementalSerializer();
    }
    _generator = new IncrementalKernelGenerator(_compilerOptions, _entryPoint,
        initializeFromDillUri, false, incrementalSerializer);
    _pendingDeltas = <Component>[];
  }

  IncrementalCompiler.forExpressionCompilationOnly(
      Component component, this._compilerOptions, this._entryPoint)
      : forExpressionCompilationOnly = true {
    _generator = new IncrementalKernelGenerator.forExpressionCompilationOnly(
        _compilerOptions, _entryPoint, component);
    _pendingDeltas = <Component>[];
  }

  /// Recompiles invalidated files, produces incremental component.
  ///
  /// If [entryPoint] is specified, that points to new entry point for the
  /// compilation. Otherwise, previously set entryPoint is used.
  Future<Component> compile({Uri entryPoint}) async {
    final task = new TimelineTask();
    try {
      task.start("IncrementalCompiler.compile");
      _entryPoint = entryPoint ?? _entryPoint;
      List<Uri> entryPoints;
      if (entryPoint != null) entryPoints = [entryPoint];
      Component component = await _generator.computeDelta(
          entryPoints: entryPoints, fullComponent: fullComponent);
      initialized = true;
      fullComponent = false;
      _pendingDeltas.add(component);
      return _combinePendingDeltas(false);
    } finally {
      task.finish();
    }
  }

  _combinePendingDeltas(bool includePlatform) {
    Procedure mainMethod;
    NonNullableByDefaultCompiledMode compilationMode;
    Map<Uri, Library> combined = <Uri, Library>{};
    Map<Uri, Source> uriToSource = new Map<Uri, Source>();
    for (Component delta in _pendingDeltas) {
      if (delta.mainMethod != null) {
        mainMethod = delta.mainMethod;
      }
      compilationMode = delta.mode;
      uriToSource.addAll(delta.uriToSource);
      for (Library library in delta.libraries) {
        bool isPlatform =
            library.importUri.scheme == "dart" && !library.isSynthetic;
        if (!includePlatform && isPlatform) continue;
        combined[library.importUri] = library;
      }
    }

    // TODO(vegorov) this needs to merge metadata repositories from deltas.
    return new Component(
        libraries: combined.values.toList(), uriToSource: uriToSource)
      ..setMainMethodAndMode(mainMethod?.reference, true, compilationMode);
  }

  CoreTypes getCoreTypes() => _generator.getCoreTypes();
  ClassHierarchy getClassHierarchy() => _generator.getClassHierarchy();

  /// This lets incremental compiler know that results of last [compile] call
  /// were accepted, don't need to be included into subsequent [compile] calls
  /// results.
  accept() {
    if (forExpressionCompilationOnly) {
      throw new StateError("Incremental compiler created for expression "
          "compilation only; cannot accept");
    }
    Map<Uri, Library> combined = <Uri, Library>{};
    Map<Uri, Source> uriToSource = <Uri, Source>{};

    if (_lastKnownGood != null) {
      // TODO(aam): Figure out how to skip no-longer-used libraries from
      // [_lastKnownGood] libraries.
      for (Library library in _lastKnownGood.libraries) {
        combined[library.importUri] = library;
      }
      uriToSource.addAll(_lastKnownGood.uriToSource);
    }

    Component candidate = _combinePendingDeltas(true);
    for (Library library in candidate.libraries) {
      combined[library.importUri] = library;
    }
    uriToSource.addAll(candidate.uriToSource);

    _lastKnownGood = new Component(
      libraries: combined.values.toList(),
      uriToSource: uriToSource,
    )..setMainMethodAndMode(
        candidate.mainMethod?.reference, true, candidate.mode);
    for (final repo in candidate.metadata.values) {
      _lastKnownGood.addMetadataRepository(repo);
    }
    _pendingDeltas.clear();
  }

  /// This lets incremental compiler know that results of last [compile] call
  /// were rejected. Subsequent [compile] or [compileExpression] calls need to
  /// be processed without changes picked up by rejected [compile] call.
  reject() async {
    if (forExpressionCompilationOnly) {
      throw new StateError("Incremental compiler created for expression "
          "compilation only; cannot reject");
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
    _lastKnownGood?.relink();

    _generator = new IncrementalKernelGenerator.fromComponent(_compilerOptions,
        _entryPoint, _lastKnownGood, false, incrementalSerializer);
    await _generator.computeDelta(entryPoints: [_entryPoint]);
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

  Future<Procedure> compileExpression(
      String expression,
      List<String> definitions,
      List<String> typeDefinitions,
      String libraryUri,
      String klass,
      bool isStatic) {
    Map<String, DartType> completeDefinitions = {};
    for (String name in definitions) {
      if (!isLegalIdentifier(name)) continue;
      completeDefinitions[name] = new DynamicType();
    }

    List<TypeParameter> typeParameters = [];
    for (String name in typeDefinitions) {
      if (!isLegalIdentifier(name)) continue;
      typeParameters.add(new TypeParameter(name, new DynamicType()));
    }

    Uri library = Uri.parse(libraryUri);
    if (library == null) return null;

    return _generator.compileExpression(expression, completeDefinitions,
        typeParameters, kDebugProcedureName, library, klass, isStatic);
  }
}
