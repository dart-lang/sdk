// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../base/processed_options.dart' show ProcessedOptions;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:kernel/kernel.dart' show Component;

class InitializedCompilerState {
  final CompilerOptions options;
  final ProcessedOptions processedOpts;
  final Map<Uri, WorkerInputComponent> workerInputCache;

  /// A map from library import uri to dill uri, i.e. where a library came from,
  /// for all cached libraries.
  final Map<Uri, Uri> workerInputCacheLibs;
  final IncrementalCompiler incrementalCompiler;
  final Set<String> tags;
  final Map<Uri, Uri> libraryToInputDill;

  InitializedCompilerState(this.options, this.processedOpts,
      {this.workerInputCache,
      this.workerInputCacheLibs,
      this.incrementalCompiler,
      this.tags,
      this.libraryToInputDill});
}

/// A cached [Component] for a summary input file.
///
/// Tracks the originally marked "external" libs so that they can be restored,
/// since the kernel generator mutates the state.
class WorkerInputComponent {
  final List<int> digest;
  final Component component;
  WorkerInputComponent(this.digest, this.component);
}

bool digestsEqual(List<int> a, List<int> b) {
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
