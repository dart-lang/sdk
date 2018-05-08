// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show Component;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/incremental_compiler.dart' show IncrementalCompiler;

import 'compiler_options.dart' show CompilerOptions;

abstract class IncrementalKernelGenerator {
  factory IncrementalKernelGenerator(CompilerOptions options, Uri entryPoint,
      [Uri bootstrapDill]) {
    return new IncrementalCompiler(
        new CompilerContext(new ProcessedOptions(options, false, [entryPoint])),
        bootstrapDill);
  }

  /// Returns a component whose libraries are the recompiled libraries,
  /// or - in the case of [fullComponent] - a full Component.
  Future<Component> computeDelta({Uri entryPoint, bool fullComponent});

  /// Remove the file associated with the given file [uri] from the set of
  /// valid files.  This guarantees that those files will be re-read on the
  /// next call to [computeDelta]).
  void invalidate(Uri uri);
}
