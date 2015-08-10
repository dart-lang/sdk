// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:isolate' as I;

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

Future during() async {
}

int numPaused(vm) {
  int paused = 0;
  for (var isolate in vm.isolates) {
    if (isolate.paused) {
      paused++;
    }
  }
  return paused;
}

var tests = [
  (VM vm) async {
    Completer completer = new Completer();
    var stream = await vm.getEventStream(VM.kIsolateStream);
    if (vm.isolates.length < spawnCount + 1) {
      var subscription;
      subscription = stream.listen((ServiceEvent event) {
        if (event.kind == ServiceEvent.kIsolateStart) {
          if (vm.isolates.length == (spawnCount + 1)) {
            subscription.cancel();
            completer.complete(null);
          }
        }
      });
      await completer.future;
    }
    expect(vm.isolates.length, spawnCount + 1);
  },

  (VM vm) async {
    // Load each isolate.
    for (var isolate in vm.isolates) {
      await isolate.load();
    }
  },

  (VM vm) async {
    Completer completer = new Completer();
    var stream = await vm.getEventStream(VM.kDebugStream);
    if (numPaused(vm) < spawnCount) {
      var subscription;
      subscription = stream.listen((ServiceEvent event) {
        if (event.kind == ServiceEvent.kPauseExit) {
          if (numPaused(vm) == (spawnCount + 1)) {
            subscription.cancel();
            completer.complete(null);
          }
        }
      });
      await completer.future;
    }
    expect(numPaused(vm), spawnCount + 1);
  },


  (VM vm) async {
    var resumedReceived = 0;
    Completer completer = new Completer();
    var stream = await vm.getEventStream(VM.kIsolateStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kIsolateExit) {
        resumedReceived++;
        if (resumedReceived >= resumeCount) {
          subscription.cancel();
          completer.complete(null);
        }
      }
    });

    // Resume a subset of the isolates.
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
    await completer.future;
  },

  (VM vm) async {
    expect(numPaused(vm), spawnCount + 1 - resumeCount); 
  },
];

main(args) async => runVMTests(args, tests,
                               testeeBefore: before,
                               testeeConcurrent: during,
                               pause_on_exit: true);
