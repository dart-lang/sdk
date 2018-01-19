// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ahe): Remove this file.

import 'package:kernel/kernel.dart' show Library, Program;

/// Helper class to work around modifications in [kernel_generator_impl.dart].
class ExternalStateSnapshot {
  final List<ExternalState> snapshots;

  ExternalStateSnapshot(Program program)
      : snapshots = new List<ExternalState>.from(
            program.libraries.map((l) => new ExternalState(l, l.isExternal)));

  void restore() {
    for (ExternalState state in snapshots) {
      state.restore();
    }
  }
}

class ExternalState {
  final Library library;
  final bool isExternal;

  ExternalState(this.library, this.isExternal);

  void restore() {
    library.isExternal = isExternal;
  }
}
