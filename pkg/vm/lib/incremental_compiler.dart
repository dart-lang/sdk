// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines wrapper class around incremental compiler to support
/// the flow, where incremental deltas can be rejected by VM.
import 'dart:async';

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:kernel/kernel.dart';

/// Wrapper around [IncrementalKernelGenerator] that keeps track of rejected
/// deltas and combines them together into resultant program until it is
/// accepted.
class IncrementalCompiler {
  IncrementalKernelGenerator _generator;
  List<Component> _pendingDeltas;
  CompilerOptions _compilerOptions;
  bool initialized = false;
  bool fullComponent = false;

  IncrementalCompiler(this._compilerOptions, Uri entryPoint,
      {Uri bootstrapDill}) {
    _generator = new IncrementalKernelGenerator(
        _compilerOptions, entryPoint, bootstrapDill);
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
    if (firstDelta) {
      return component;
    }

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
    return new Component(libraries: combined.values.toList())
      ..mainMethod = mainMethod;
  }

  /// This lets incremental compiler know that results of last [compile] call
  /// were accepted, don't need to be included into subsequent [compile] calls
  /// results.
  accept() {
    _pendingDeltas.clear();
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
}
