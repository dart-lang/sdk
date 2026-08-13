// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple binary which continuously does some busy work and generates
// timeline events.

import 'dart:async';
import 'dart:developer';

import 'package:perf_witness/server.dart';
import 'package:perf_witness/src/async_span.dart';

int fib(int i) {
  if (i < 2) return 1;
  return fib(i - 1) + fib(i - 2);
}

Future<void> task(int id) async {
  await AsyncSpan.run('task#$id', () async {
    for (var i = 0; i < 10; i++) {
      Timeline.timeSync('fib', () {
        final sw = Stopwatch()..start();
        while (sw.elapsedMilliseconds < 100) {
          fib(10);
        }
      });
      await Future.delayed(Duration(milliseconds: 100));
    }
  });
}

void main() async {
  await PerfWitnessServer.start();
  var id = 0;
  while (true) {
    await AsyncSpan.run('task-group-${id ~/ 2}', () async {
      await Future.wait([task(id++), task(id++)]);
      await Future.delayed(Duration(milliseconds: 100));
    });
  }
}
