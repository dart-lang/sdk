// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'validate_timer_port_behavior_lib.dart' as testee_lib;

late Set<int> originalPortIds;
late int timerPortId;

void main([args = const <String>[]]) => IsolateTestHarness(
      'validate_timer_port_behavior_lib.dart',
      args,
    )
        .hasPausedAtStart()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final originalPorts = (await service.getPorts(isolateId)).ports!;
          originalPortIds = {
            for (int i = 0; i < originalPorts.length; ++i)
              originalPorts[i].portId!,
          };
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // Determine the ID of the timer port.
          final isolateId = isolateRef.id!;
          final ports = (await service.getPorts(isolateId)).ports!;
          timerPortId = ports
              .firstWhere(
                (p) => !originalPortIds.contains(p.portId!),
              )
              .portId!;
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // After cancelling the timer, there should be no active timers left.
          // The timer port should be inactive and not reported.
          final isolateId = isolateRef.id!;
          final ports = (await service.getPorts(isolateId)).ports!;
          for (final port in ports) {
            if (port.portId! == timerPortId) {
              fail('Timer port should no longer be active');
            }
          }
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // After setting a new timer, the timer port should be active and have the same
          // port ID as before as the original port is still being used.
          final isolateId = isolateRef.id!;
          final ports = (await service.getPorts(isolateId)).ports!;
          bool foundTimerPort = false;
          for (final port in ports) {
            if (port.portId! == timerPortId) {
              foundTimerPort = true;
              break;
            }
          }
          expect(foundTimerPort, true);
        })
        .run(testeeMain: testee_lib.main, pauseOnStart: true);
