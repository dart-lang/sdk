// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Shared code used by fasta_perf and incremental_perf.
library front_end.tool.perf_common;

import 'dart:io';
import 'package:front_end/front_end.dart';
export 'package:front_end/src/fasta/fasta_codes.dart';

/// Error messages that we temporarily allow when compiling benchmarks in strong
/// mode.
///
/// This whitelist lets us run the compiler benchmarks while those errors get
/// fixed. We don't blindly allow any error message because we would then miss
/// situations where the benchmarks are actually broken.
///
/// Note: the performance bots compile both dart2js and the flutter-gallery app
/// as benchmarks, so they both need to be checked before we remove a message
/// from this set.
final whitelistMessageCode = new Set<String>.from(<String>[
  // Code names in this list should match the key used in messages.yaml
  // For example: 'InvalidAssignment'
]);

onErrorHandler(bool isStrong) => (CompilationMessage m) {
      if (m.severity == Severity.internalProblem ||
          m.severity == Severity.error) {
        if (!isStrong || !whitelistMessageCode.contains(m.code)) {
          exitCode = 1;
        }
      }
    };
