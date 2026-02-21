// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/perf_witness/perf_witness_js.dart'
    if (dart.library.io) 'package:analysis_server/src/services/perf_witness/perf_witness_io.dart';

/// Shutdown `perf_witness` server.
Future<void> shutdownPerfWitness() => shutdownPerfWitnessImpl();

/// Start `perf_witness` server and hookup `runAsyncHook`.
Future<void> startPerfWitness() => startPerfWitnessImpl();
