// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:expect/expect.dart';

// Implements recursive summation via tail calls:
//   fib(n) => n <= 1 ? 1
//                    : fib(n-1) + fib(n-2);
Future fibonacciRecursive(List args) async {
  final SendPort port = args[0];
  final n = args[1];
  if (n <= 1) {
    port.send(1);
    return;
  }
  final left = ReceivePort();
  final right = ReceivePort();
  await Future.wait([
    Isolate.spawn(fibonacciRecursive, [left.sendPort, n - 1]),
    Isolate.spawn(fibonacciRecursive, [right.sendPort, n - 2]),
  ]);
  final results = await Future.wait([left.first, right.first]);
  port.send(results[0] + results[1]);
}

Future<void> main() async {
  final rpWarmup = ReceivePort();
  final rpRun = ReceivePort();
  final int nWarmup = 17; // enough runs to trigger optimized compilation
  final int nWarmupFactorial = 2584;
  // Runs for about 8 seconds.
  final int n = 21;
  final int nFactorial = 17711;
  final beforeRss = ProcessInfo.currentRss;

  int maxRss = beforeRss;
  final rssTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
    maxRss = max(ProcessInfo.currentRss, maxRss);
  });

  final watch = Stopwatch();
  watch.start();

  // Warm up code by running a couple iterations in the main isolate.
  await Isolate.spawn(fibonacciRecursive, [rpWarmup.sendPort, nWarmup]);
  Expect.equals(nWarmupFactorial, await rpWarmup.first);

  final warmup = watch.elapsedMicroseconds;

  await Isolate.spawn(fibonacciRecursive, [rpRun.sendPort, n]);
  Expect.equals(nFactorial, await rpRun.first);

  final done = watch.elapsedMicroseconds;

  print('IsolateFibonacci_$n.Calculation(RunTimeRaw): ${done - warmup} us.');
  print('IsolateFibonacci_$n.DeltaPeak(MemoryUse): ${maxRss - beforeRss}');
  rssTimer.cancel();
}
