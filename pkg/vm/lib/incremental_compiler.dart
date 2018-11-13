// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines wrapper class around incremental compiler to support
/// the flow, where incremental deltas can be rejected by VM.
import 'dart:async';

import 'package:front_end/src/api_unstable/vm.dart';
import 'package:kernel/kernel.dart';

const String kDebugProcedureName = ":Eval";

/// Wrapper around [IncrementalKernelGenerator] that keeps track of rejected
/// deltas and combines them together into resultant program until it is
/// accepted.
class IncrementalCompiler {
  IncrementalKernelGenerator _generator;

  // Component that reflect current state of the compiler, which has not
  // been yet accepted by the client. Is [null] if no compilation was done
  // since last accept/reject acknowledgement by the client.
  Component _candidate;
  // Component that reflect the state that was most recently accepted by the
  // client. Is [null], if no compilation results were accepted by the client.
  Component _lastKnownGood;

  List<Component> _pendingDeltas;
  CompilerOptions _compilerOptions;
  bool initialized = false;
  bool fullComponent = false;
  Uri initializeFromDillUri;
  Uri _entryPoint;

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
    Component component = await _generator.computeDelta(
        entryPoint: entryPoint, fullComponent: fullComponent);
    initialized = true;
    fullComponent = false;
    final bool firstDelta = _pendingDeltas.isEmpty;
    _pendingDeltas.add(component);
    if (!firstDelta) {
      // If more than one delta is pending, we need to combine them.
      Procedure mainMethod;
      Map<Uri, Library> combined = <Uri, Library>{};
      for (Component delta in _pendingDeltas) {
        if (delta.mainMethod != null) {
          mainMethod = delta.mainMethod;
        }
        for (Library library in delta.libraries) {
          combined[library.importUri] = library;
        }
      }
      // TODO(vegorov) this needs to merge metadata repositories from deltas.
      component = new Component(libraries: combined.values.toList())
        ..mainMethod = mainMethod;
    }
    _candidate = component;
    return component;
  }

  /// This lets incremental compiler know that results of last [compile] call
  /// were accepted, don't need to be included into subsequent [compile] calls
  /// results.
  accept() {
    _pendingDeltas.clear();

    Map<Uri, Library> combined = <Uri, Library>{};
    if (_lastKnownGood != null) {
      // TODO(aam): Figure out how to skip no-longer-used libraries from
      // [_lastKnownGood] libraries.
      for (Library library in _lastKnownGood.libraries) {
        combined[library.importUri] = library;
      }
    }
    for (Library library in _candidate.libraries) {
      combined[library.importUri] = library;
    }
    _lastKnownGood = new Component(
      libraries: combined.values.toList(),
      uriToSource: _candidate.uriToSource,
    )..mainMethod = _candidate.mainMethod;
    for (final repo in _candidate.metadata.values) {
      _lastKnownGood.addMetadataRepository(repo);
    }

    _candidate = null;
  }

  /// This lets incremental compiler know that results of last [compile] call
  /// were rejected. Subsequent [compile] or [compileExpression] calls need to
  /// be processed without changes picked up by rejected [compile] call.
  reject() async {
    _pendingDeltas.clear();
    _candidate = null;
    // Need to reset and warm up compiler so that expression evaluation requests
    // are processed in that known good state.
    _generator = new IncrementalKernelGenerator.fromComponent(
        _compilerOptions, _entryPoint, _lastKnownGood);
    await _generator.computeDelta(entryPoint: _entryPoint);
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
