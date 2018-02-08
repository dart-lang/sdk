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
  List<Program> _pendingDeltas;
  CompilerOptions _compilerOptions;

  IncrementalCompiler(this._compilerOptions, Uri entryPoint) {
    _generator = new IncrementalKernelGenerator(_compilerOptions, entryPoint);
    _pendingDeltas = <Program>[];
  }

  /// Recompiles invalidated files, produces incremental program.
  ///
  /// If [entryPoint] is specified, that points to new entry point for the
  /// compilation. Otherwise, previously set entryPoint is used.
  Future<Program> compile({Uri entryPoint}) async {
    Program program = await _generator.computeDelta(entryPoint: entryPoint);
    final bool firstDelta = _pendingDeltas.isEmpty;
    _pendingDeltas.add(program);
    if (firstDelta) {
      return program;
    }

    // If more than one delta is pending, we need to combine them.
    Map<Uri, Library> combined = <Uri, Library>{};
    for (Program delta in _pendingDeltas) {
      for (Library library in delta.libraries) {
        combined[library.importUri] = library;
      }
    }
    return new Program(libraries: combined.values.toList());
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
}
