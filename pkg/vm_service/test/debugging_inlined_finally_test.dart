// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 25;
const int LINE_B = 28;
const int LINE_C = 31;

Function testFunction() {
  debugger();
  var a;
  try {
    var b;
    try {
      for (int i = 0; i < 10;) {
        var x = () => i + a + b;
        return x; // LINE_A
      }
    } finally {
      b = 10; // LINE_B
    }
  } finally {
    a = 1; // LINE_C
  }
  throw StateError('Unreachable');
}

void testMain() {
  final f = testFunction();
  expect(f(), 11);
}

Future<void> Function(VmService, IsolateRef) checkBreakpoint(int line) =>
    (VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final stack = await service.getStack(isolateId);
      expect(stack.frames!.length, greaterThanOrEqualTo(1));

      final frame = stack.frames![0];
      final script = await service.getObject(
          isolateId, frame.location!.script!.id!) as Script;

      expect(script.getLineNumberFromTokenPos(frame.location!.tokenPos!), line);
    };

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

  // Add breakpoint
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    var isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;

    final scriptId = rootLib.scripts![0].id!;
    final script = await service.getObject(isolateId, scriptId) as Script;

    // Add 3 breakpoints.
    {
      final bpt = await service.addBreakpoint(isolateId, script.id!, LINE_A);
      expect(bpt.location!.script!.id, scriptId);
      expect(script.getLineNumberFromTokenPos(bpt.location!.tokenPos), LINE_A);

      isolate = await service.getIsolate(isolateId);
      expect(isolate.breakpoints!.length, 1);
    }

    {
      final bpt = await service.addBreakpoint(isolateId, scriptId, LINE_B);
      expect(bpt.location!.script!.id, scriptId);
      expect(script.getLineNumberFromTokenPos(bpt.location!.tokenPos), LINE_B);

      isolate = await service.getIsolate(isolateId);
      expect(isolate.breakpoints!.length, equals(2));
    }

    {
      final bpt = await service.addBreakpoint(isolateId, scriptId, LINE_C);
      expect(bpt.location!.script!.id, scriptId);
      expect(script.getLineNumberFromTokenPos(bpt.location!.tokenPos), LINE_C);

      isolate = await service.getIsolate(isolateId);
      expect(isolate.breakpoints!.length, equals(3));
    }

    // Wait for breakpoint events.
  },

  resumeIsolate,

  hasStoppedAtBreakpoint,

  // We are at the breakpoint on line LINE_A.
  checkBreakpoint(LINE_A),

  resumeIsolate,

  hasStoppedAtBreakpoint,

  // We are at the breakpoint on line LINE_B.
  checkBreakpoint(LINE_B),

  resumeIsolate,

  hasStoppedAtBreakpoint,

  // We are at the breakpoint on line LINE_C.
  checkBreakpoint(LINE_C),

  resumeIsolate,
];

void main(List<String> args) => runIsolateTests(
      args,
      tests,
      'debugging_inlined_finally_test.dart',
      testeeConcurrent: testMain,
    );
