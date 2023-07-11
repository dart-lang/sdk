// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Note: we pass --save-debugging-info=* without --dwarf-stack-traces to
// make this test pass on vm-aot-dwarf-* builders.
//
// VMOptions=--save-debugging-info=$TEST_COMPILATION_DIR/debug.so
// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

import 'dart:async';

import 'package:expect/expect.dart';

import 'harness.dart' as harness;

bool barRunning = false;

Future<void> foo() async {}

Future<void> bar() async {
  try {
    barRunning = true;
    await foo();
  } finally {
    barRunning = false;
  }
}

Future<void> runTest() {
  final Zone testZone = Zone.current.fork(
      specification: ZoneSpecification(
          registerUnaryCallback: _registerUnaryCallback,
          registerBinaryCallback: _registerBinaryCallback));
  return testZone.run(bar);
}

StackTrace? registerUnaryCallbackStackTrace;
StackTrace? registerBinaryCallbackStackTrace;

ZoneUnaryCallback<R, T> _registerUnaryCallback<R, T>(
    Zone self, ZoneDelegate parent, Zone zone, R Function(T) f) {
  final stackTrace = StackTrace.current;
  print('registerUnaryCallback got stack trace:');
  print(stackTrace);
  if (barRunning) {
    Expect.isNull(registerUnaryCallbackStackTrace);
    registerUnaryCallbackStackTrace = stackTrace;
  }
  return parent.registerUnaryCallback(zone, f);
}

ZoneBinaryCallback<R, T1, T2> _registerBinaryCallback<R, T1, T2>(
    Zone self, ZoneDelegate parent, Zone zone, R Function(T1, T2) f) {
  final stackTrace = StackTrace.current;
  print('registerBinaryCallback got stack trace:');
  print(stackTrace);
  if (barRunning) {
    Expect.isNull(registerBinaryCallbackStackTrace);
    registerBinaryCallbackStackTrace = stackTrace;
  }
  return parent.registerBinaryCallback(zone, f);
}

Future<void> main() async {
  if (harness.shouldSkip()) {
    return;
  }

  harness.configure(currentExpectations);

  await runTest();
  await harness.checkExpectedStack(registerUnaryCallbackStackTrace!);
  await harness.checkExpectedStack(registerBinaryCallbackStackTrace!);

  harness.updateExpectations();
}

// CURRENT EXPECTATIONS BEGIN
final currentExpectations = [
  """
#0    _registerUnaryCallback (%test%)
#1    _CustomZone.registerUnaryCallback (zone.dart)
#2    bar (%test%)
#3    _rootRun (zone.dart)
#4    _CustomZone.run (zone.dart)
#5    runTest (%test%)
#6    main (%test%)
#7    _delayEntrypointInvocation.<anonymous closure> (isolate_patch.dart)
#8    _RawReceivePort._handleMessage (isolate_patch.dart)""",
  """
#0    _registerBinaryCallback (%test%)
#1    _CustomZone.registerBinaryCallback (zone.dart)
#2    bar (%test%)
#3    _rootRun (zone.dart)
#4    _CustomZone.run (zone.dart)
#5    runTest (%test%)
#6    main (%test%)
#7    _delayEntrypointInvocation.<anonymous closure> (isolate_patch.dart)
#8    _RawReceivePort._handleMessage (isolate_patch.dart)"""
];
// CURRENT EXPECTATIONS END
