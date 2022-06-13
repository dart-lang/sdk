// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

library compiler_api_migrated;

import 'dart:async';

import 'src/compiler.dart' show Compiler;
import 'src/options.dart' show CompilerOptions;

import 'compiler_api.dart';

// Unless explicitly allowed, passing [:null:] for any argument to the
// methods of library will result in an Error being thrown.

/// Returns a future that completes to a [CompilationResult] when the Dart
/// sources in [options] have been compiled.
///
/// The generated compiler output is obtained by providing a [compilerOutput].
///
/// If the compilation fails, the future's `CompilationResult.isSuccess` is
/// `false` and [CompilerDiagnostics.report] on [compilerDiagnostics]
/// is invoked at least once with `kind == Diagnostic.ERROR` or
/// `kind == Diagnostic.CRASH`.
Future<CompilationResult> compile(
    CompilerOptions compilerOptions,
    CompilerInput compilerInput,
    CompilerDiagnostics compilerDiagnostics,
    CompilerOutput compilerOutput) {
  if (compilerOptions == null) {
    throw new ArgumentError("compilerOptions must be non-null");
  }
  if (compilerInput == null) {
    throw new ArgumentError("compilerInput must be non-null");
  }
  if (compilerDiagnostics == null) {
    throw new ArgumentError("compilerDiagnostics must be non-null");
  }
  if (compilerOutput == null) {
    throw new ArgumentError("compilerOutput must be non-null");
  }

  var compiler = Compiler(
      compilerInput, compilerOutput, compilerDiagnostics, compilerOptions);
  return compiler.run().then((bool success) {
    return new CompilationResult(compiler,
        isSuccess: success,
        kernelInitializedCompilerState: compiler.initializedCompilerState);
  });
}
