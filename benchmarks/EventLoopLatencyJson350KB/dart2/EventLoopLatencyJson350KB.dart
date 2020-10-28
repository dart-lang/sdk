// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:isolate';

import 'json_benchmark.dart';
import 'latency.dart';

main() async {
  // Start GC pressure from helper isolate.
  final exitPort = ReceivePort();
  final exitFuture = exitPort.first;
  final isolate = await Isolate.spawn(run, null, onExit: exitPort.sendPort);

  // Measure event loop latency.
  const tickDuration = const Duration(milliseconds: 1);
  const numberOfTicks = 8 * 1000; // min 8 seconds.
  final EventLoopLatencyStats stats =
      await measureEventLoopLatency(tickDuration, numberOfTicks);

  // Kill isolate & wait until it's dead.
  isolate.kill(priority: Isolate.immediate);
  await exitFuture;

  // Report event loop latency statistics.
  stats.report('EventLoopLatencyJson350KB');
}

void run(dynamic msg) {
  while (true) {
    JsonRoundTripBenchmark().run();
  }
}
