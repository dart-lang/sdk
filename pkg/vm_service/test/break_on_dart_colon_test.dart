// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

// Line in core/print.dart
const int LINE_A = 10;

testMain() {
  debugger();
  print('1');
  print('2');
  print('3');
  print('Done');
}

IsolateTest expectHitBreakpoint(String uri, int line) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    final bpt = await service.addBreakpointWithScriptUri(isolateId, uri, line);
    await resumeIsolate(service, isolateRef);
    await hasStoppedAtBreakpoint(service, isolateRef);
    await stoppedAtLine(line)(service, isolateRef);
    await service.removeBreakpoint(isolateId, bpt.id!);
  };
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

  // Dart libraries are not debuggable by default
  markDartColonLibrariesDebuggable,

  expectHitBreakpoint('org-dartlang-sdk:///sdk/lib/core/print.dart', LINE_A),
  expectHitBreakpoint('dart:core/print.dart', LINE_A),
  expectHitBreakpoint('/core/print.dart', LINE_A),

  resumeIsolate,
];

main(args) => runIsolateTests(
      args,
      tests,
      'break_on_dart_colon_test.dart',
      testeeConcurrent: testMain,
    );
