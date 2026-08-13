// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/ddc.dart'
    show InitializedCompilerState;

/// The result of a single `dartdevc` compilation.
///
/// Typically used for exiting the process with [exitCode] or checking the
/// [success] of the compilation.
///
/// For batch/worker compilations, the [compilerState] provides an opportunity
/// to reuse state from the previous run, if the options/input summaries are
/// equivalent. Otherwise it will be discarded.
class CompilerResult {
  /// Optionally provides the front_end state from the previous compilation,
  /// which can be passed to [compile] to potentially speed up the next
  /// compilation.
  final InitializedCompilerState? kernelState;

  /// The process exit code of the compiler.
  final int exitCode;

  CompilerResult(this.exitCode, {this.kernelState});

  /// Gets the kernel compiler state, if any.
  Object? get compilerState => kernelState;

  /// Whether the program compiled without any fatal errors (equivalent to
  /// [exitCode] == 0).
  bool get success => exitCode == 0;

  /// Whether the compiler crashed (i.e. threw an unhandled exception,
  /// typically indicating an internal error in DDC itself or its front end).
  bool get crashed => exitCode == 70;
}
