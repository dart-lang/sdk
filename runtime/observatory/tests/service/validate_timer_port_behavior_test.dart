// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:isolate' hide Isolate;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

void warmup() {
  Timer timer = Timer(const Duration(days: 30), () => null);
  debugger();
  timer.cancel();
  debugger();
  timer = Timer(const Duration(days: 30), () => null);
  debugger();
  timer.cancel();
}

late Set<int> originalPortIds;
late int timerPortId;

final tests = <IsolateTest>[
  hasPausedAtStart,
  (Isolate isolate) async {
    final originalPorts =
        (await isolate.invokeRpcNoUpgrade('getPorts', {}))['ports'];
    originalPortIds = {
      for (int i = 0; i < originalPorts.length; ++i) originalPorts[i]['portId'],
    };
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Determine the ID of the timer port.
    final ports = (await isolate.invokeRpcNoUpgrade('getPorts', {}))['ports'];
    timerPortId = ports
        .firstWhere((p) => !originalPortIds.contains(p['portId']))['portId'];
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // After cancelling the timer, there should be no active timers left.
    // The timer port should be inactive and not reported.
    final ports = (await isolate.invokeRpcNoUpgrade('getPorts', {}))['ports'];
    for (final port in ports) {
      if (port['portId'] == timerPortId) {
        fail('Timer port should no longer be active');
      }
    }
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // After setting a new timer, the timer port should be active and have the same
    // port ID as before as the original port is still being used.
    final ports = (await isolate.invokeRpcNoUpgrade('getPorts', {}))['ports'];
    bool foundTimerPort = false;
    for (final port in ports) {
      if (port['portId'] == timerPortId) {
        foundTimerPort = true;
        break;
      }
    }
    expect(foundTimerPort, true);
  },
];

main(args) async => runIsolateTests(args, tests,
    pause_on_start: true, testeeConcurrent: warmup);
