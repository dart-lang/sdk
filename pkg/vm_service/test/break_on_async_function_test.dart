// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 14;

/* LINE_A */ Future<String> testFunction() async {
  await new Future.delayed(new Duration(milliseconds: 1));
  return "Done";
}

Future<void> testMain() async {
  debugger();
  print(await testFunction());
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

  // Add breakpoint at the entry of async function
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        (await service.getObject(isolateId, isolate.rootLib!.id!)) as Library;

    final function =
        rootLib.functions!.singleWhere((f) => f.name == 'testFunction');
    final bpt = await service.addBreakpointAtEntry(isolateId, function.id!);
    print(bpt);
  },

  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
];

void main(args) => runIsolateTests(
      args,
      tests,
      'break_on_async_function_test.dart',
      testeeConcurrent: testMain,
    );
