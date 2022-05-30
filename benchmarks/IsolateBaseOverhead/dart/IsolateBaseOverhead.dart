// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

const int count = 10000;

// The benchmark will spawn a long chain of isolates, keeping all of them
// alive until the last one which measures Rss at that point (i.e. when all
// isolates are alive), thereby getting a good estimate of memory-overhead per
// isolate.
void main() async {
  final onDone = ReceivePort();
  final lastIsolatePort = ReceivePort();
  final startRss = ProcessInfo.currentRss;
  final startUs = DateTime.now().microsecondsSinceEpoch;
  await Isolate.spawn(worker, WorkerInfo(count, lastIsolatePort.sendPort),
      onExit: onDone.sendPort);
  final result = await lastIsolatePort.first as List;
  final lastIsolateRss = result[0] as int;
  final lastIsolateUs = result[1] as int;
  await onDone.first;
  final doneUs = DateTime.now().microsecondsSinceEpoch;

  final averageMemoryUsageInKB = (lastIsolateRss - startRss) / count / 1024;
  final averageStartLatencyInUs = (lastIsolateUs - startUs) / count;
  final averageFinishLatencyInUs = (doneUs - startUs) / count;

  print('IsolateBaseOverhead.Rss(MemoryUse): $averageMemoryUsageInKB');
  print(
      'IsolateBaseOverhead.StartLatency(Latency): $averageStartLatencyInUs us.');
  print(
      'IsolateBaseOverhead.FinishLatency(Latency): $averageFinishLatencyInUs us.');
}

class WorkerInfo {
  final int id;
  final SendPort result;

  WorkerInfo(this.id, this.result);
}

Future worker(WorkerInfo workerInfo) async {
  if (workerInfo.id == 1) {
    workerInfo.result
        .send([ProcessInfo.currentRss, DateTime.now().microsecondsSinceEpoch]);
    return;
  }
  final onExit = ReceivePort();
  await Isolate.spawn(worker, WorkerInfo(workerInfo.id - 1, workerInfo.result),
      onExit: onExit.sendPort);
  await onExit.first;
}
