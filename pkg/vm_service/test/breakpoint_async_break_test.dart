// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE = 19;
const int COL = 7;

// Issue: https://github.com/dart-lang/sdk/issues/36622
Future<void> testMain() async {
  for (int i = 0; i < 2; i++) {
    if (i > 0) {
      break; // breakpoint here
    }
    await Future.delayed(Duration(seconds: 1));
  }
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final scriptId = rootLib.scripts![0].id!;

    final bpt = await service.addBreakpoint(isolateId, scriptId, LINE);
    expect(bpt.breakpointNumber, 1);
    expect(bpt.resolved, isTrue);
    expect(await bpt.location!.line, LINE);
    expect(await bpt.location!.column, 7);

    await service.resume(isolateId);
    await hasStoppedAtBreakpoint(service, isolate);

    // Remove the breakpoints.
    expect(
      (await service.removeBreakpoint(isolateId, bpt.id!)).type,
      'Success',
    );
  },
];

Future<void> main(args) => runIsolateTests(
      args,
      tests,
      'breakpoint_async_break_test.dart',
      testeeConcurrent: testMain,
      pauseOnStart: true,
    );
