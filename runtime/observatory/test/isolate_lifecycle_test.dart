// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override --checked

import 'dart:async';
import 'dart:isolate' as I;
import 'dart:math';

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

final spawnCount = 4;
final resumeCount = spawnCount ~/ 2;
final isolates = [];

void spawnEntry(int i) {
}

Future before() async {
  // Spawn spawnCount long lived isolates.
  for (var i = 0; i < spawnCount; i++) {
    var isolate = await I.Isolate.spawn(spawnEntry, i);
    isolates.add(isolate);
  }
  print('spawned all isolates');
}

Future during() {
}

var tests = [
  (VM vm) async {
    expect(vm.isolates.length, spawnCount + 1);
  },
  (VM vm) async {
    // Load each isolate.
    for (var isolate in vm.isolates) {
      await isolate.load();
    }
  },
  (VM vm) async {
    var pausedCount = 0;
    var runningCount = 0;
    for (var isolate in vm.isolates) {
      if (isolate.paused) {
        pausedCount++;
      } else {
        runningCount++;
      }
    }
    expect(pausedCount, spawnCount);
    expect(runningCount, 1);
  },
  (VM vm) async {
    var resumedReceived = 0;
    var eventsDone = processServiceEvents(vm, (event, sub, completer) {
      if (event.eventType == ServiceEvent.kIsolateExit) {
        resumedReceived++;
        if (resumedReceived == resumeCount) {
          sub.cancel();
          completer.complete(null);
        }
      }
    });
    var resumesIssued = 0;
    var isolateList = vm.isolates.toList();
    for (var isolate in isolateList) {
      if (isolate.name.endsWith('main')) {
        continue;
      }
      try {
        resumesIssued++;
        await isolate.resume();
      } catch(_) {}
      if (resumesIssued == resumeCount) {
        break;
      }
    }
    return eventsDone;
  },
  (VM vm) async {
    var pausedCount = 0;
    var runningCount = 0;
    for (var isolate in vm.isolates) {
      if (isolate.paused) {
        pausedCount++;
      } else {
        runningCount++;
      }
    }
    expect(pausedCount, spawnCount - resumeCount);
    expect(runningCount, 1);
  },
];

main(args) async => runVMTests(args, tests,
                               testeeBefore: before,
                               testeeConcurrent: during,
                               pause_on_exit: true);
