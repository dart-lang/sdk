// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

const int LINE_A = 18;
const int LINE_B = 21;
const int LINE_C = 24;
const String file = "breakpoint_gc_test.dart";

int foo() => 42;

testeeMain() {
  foo(); // static call

  dynamic list = [1, 2, 3];
  list.clear(); // instance call
  print(list);

  dynamic local = list; // debug step check = runtime call
  return local;
}

Future<void> forceGC(VmService service, IsolateRef isolateRef) async {
  await service.callMethod(
    "_collectAllGarbage",
    isolateId: isolateRef.id!,
  );
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(file, LINE_A), // at `foo()`
  setBreakpointAtUriAndLine(file, LINE_B), // at `list.clear()`
  setBreakpointAtUriAndLine(file, LINE_C), // at `local = list`
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  forceGC, // Should not crash
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  forceGC, // Should not crash
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  forceGC, // Should not crash
  resumeIsolate,
];

void main(List<String> args) => runIsolateTestsSynchronous(
      args,
      tests,
      file,
      testeeConcurrent: testeeMain,
      pause_on_start: true,
    );
