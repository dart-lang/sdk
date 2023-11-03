// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

const int LINE_A = 15;
const int LINE_B = LINE_A + 1;

testMain() {
  final foo; // LINE_A
  foo = 42; // LINE_B
  print(foo);
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  // Add breakpoints.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
    ) as Library;
    final scriptId = rootLib.scripts![0].id!;

    final bpt1 = await service.addBreakpoint(isolateId, scriptId, LINE_A);
    final bpt2 = await service.addBreakpoint(isolateId, scriptId, LINE_B);
    expect(bpt1.location!.line, LINE_A);
    expect(bpt2.location!.line, LINE_B);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final breakpoints = isolate.breakpoints!;
    expect(breakpoints.length, 2);
    for (final bpt in isolate.breakpoints!) {
      await service.removeBreakpoint(isolateId, bpt.id!);
    }
  },
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'issue_25465_test.dart',
      testeeConcurrent: testMain,
      pause_on_start: true,
    );
