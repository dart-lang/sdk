// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 15;

/* LINE_A */ void testFunction(bool flag) {
  if (flag) {
    print("Yes");
  } else {
    print("No");
  }
}

void testMain() {
  debugger();
  testFunction(true);
  testFunction(false);
  print("Done");
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

  // Add breakpoint
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final function = rootLib.functions!.singleWhere(
      (f) => f.name == 'testFunction',
    );
    final bpt = await service.addBreakpointAtEntry(isolateId, function.id!);
    print(bpt);
  },

  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
];

void main(args) => runIsolateTests(
      args,
      tests,
      'break_on_function_test.dart',
      testeeConcurrent: testMain,
    );
