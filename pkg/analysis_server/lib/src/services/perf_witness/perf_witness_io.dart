// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:perf_witness/server.dart';
import 'package:perf_witness/src/async_span.dart';

Future<void> shutdownPerfWitnessImpl() async {
  await PerfWitnessServer.shutdown();
}

Future<void> startPerfWitnessImpl() async {
  OperationPerformanceImpl.runAsyncHook = AsyncSpan.runUnary;
  await PerfWitnessServer.start(tag: 'das', inBackground: true);
}
