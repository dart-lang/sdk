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

  // Component that reflect the state that was most recently accepted by the
  // client. Is [null], if no compilation results were accepted by the client.
  Component _lastKnownGood;

  List<Component> _pendingDeltas;
  CompilerOptions _compilerOptions;
  bool initialized = false;
  bool fullComponent = false;
  Uri initializeFromDillUri;
  Uri _entryPoint;

  Uri get entryPoint => _entryPoint;

  IncrementalCompiler(this._compilerOptions, this._entryPoint,
      {this.initializeFromDillUri}) {
    _generator = new IncrementalKernelGenerator(
        _compilerOptions, _entryPoint, initializeFromDillUri);
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
    Map<Uri, Library> combined = <Uri, Library>{};
    Map<Uri, Source> uriToSource = new Map<Uri, Source>();
    for (Component delta in _pendingDeltas) {
      if (delta.mainMethod != null) {
        mainMethod = delta.mainMethod;
      }
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
      ..mainMethod = mainMethod;
  }

  CoreTypes getCoreTypes() => _generator.getCoreTypes();
  ClassHierarchy getClassHierarchy() => _generator.getClassHierarchy();

  /// This lets incremental compiler know that results of last [compile] call
  /// were accepted, don't need to be included into subsequent [compile] calls
  /// results.
  accept() {
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
    )..mainMethod = candidate.mainMethod;
    for (final repo in candidate.metadata.values) {
      _lastKnownGood.addMetadataRepository(repo);
    }
    _pendingDeltas.clear();
  }

  /// This lets incremental compiler know that results of last [compile] call
  /// were rejected. Subsequent [compile] or [compileExpression] calls need to
  /// be processed without changes picked up by rejected [compile] call.
  reject() async {
    _pendingDeltas.clear();
    // Need to reset and warm up compiler so that expression evaluation requests
    // are processed in that known good state.
    _generator = new IncrementalKernelGenerator.fromComponent(
        _compilerOptions, _entryPoint, _lastKnownGood);
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
