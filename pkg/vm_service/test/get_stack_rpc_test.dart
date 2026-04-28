// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 22;

int counter = 0;

// This name is used in a test below.
void msgHandler(_) {}

void periodicTask(_) {
  debugger(message: 'fo', when: true);
  counter++;
  if (counter % 300 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  Timer.periodic(const Duration(milliseconds: 10), periodicTask);
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  // Get stack
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);

    // Sanity check.
    final frames = stack.frames!;
    expect(frames.length, greaterThanOrEqualTo(1));
    final scriptId = frames[0].location!.script!.id!;
    final script = await service.getObject(isolateId, scriptId) as Script;
    expect(
      script.getLineNumberFromTokenPos(frames[0].location!.tokenPos!),
      LINE_A,
    );

    // Iterate over frames.
    int frameDepth = 0;
    for (var frame in frames) {
      print('checking frame $frameDepth');
      expect(frame.index, equals(frameDepth++));
      expect(frame.code, isNotNull);
      expect(frame.function, isNotNull);
      expect(frame.location, isNotNull);
    }
  },
];

void main([args = const <String>[]]) => runIsolateTests(
  args,
  tests,
  'get_stack_rpc_test.dart',
  testeeBefore: startTimer,
);
