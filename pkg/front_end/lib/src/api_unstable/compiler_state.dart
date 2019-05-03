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
  final IncrementalCompiler incrementalCompiler;

  InitializedCompilerState(this.options, this.processedOpts,
      {this.workerInputCache, this.incrementalCompiler});
}

/// A cached [Component] for a summary input file.
///
/// Tracks the originally marked "external" libs so that they can be restored,
/// since the kernel generator mutates the state.
class WorkerInputComponent {
  final List<int> digest;
  final Component component;
  final Set<Uri> externalLibs;
  WorkerInputComponent(this.digest, this.component)
      : externalLibs = component.libraries
            .where((lib) => lib.isExternal)
            .map((lib) => lib.importUri)
            .toSet();
}

bool digestsEqual(List<int> a, List<int> b) {
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
