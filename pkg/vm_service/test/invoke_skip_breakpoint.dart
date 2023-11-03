// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 17;
const int LINE_B = LINE_A + 5;

String bar() {
  print('bar'); // LINE_A
  return 'bar';
}

void testMain() {
  debugger(); // LINE_B
  bar();
  print('Done');
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  setBreakpointAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final result = await service.invoke(
      isolateId,
      isolate.rootLib!.id!,
      'bar',
      [],
      disableBreakpoints: true,
    ) as InstanceRef;
    expect(result.valueAsString, 'bar');
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'invoke_skip_breakpoint.dart',
      testeeConcurrent: testMain,
    );
