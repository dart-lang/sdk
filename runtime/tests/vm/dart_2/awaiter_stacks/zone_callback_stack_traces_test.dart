// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Note: we pass --save-debugging-info=* without --dwarf-stack-traces to
// make this test pass on vm-aot-dwarf-* builders.
//
// VMOptions=--save-debugging-info=$TEST_COMPILATION_DIR/debug.so
// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

// This test check that awaiter stack unwinding can produce useful and readable
// stack traces when unwinding through custom Zone which use
// [Zone.registerUnaryCallback] and [Zone.registerBinaryCallback] hooks when
// corresponding hooks are properly annotated with `@pragma('vm:awaiter-link')`.
//
// `package:stack_trace` which is heavily used in the Dart ecosystem is heavily
// reliant on these hooks and we want to make sure that native awaiter stack
// unwinding works correctly even within `package:stack_trace` zones.

// @dart=2.9

import 'dart:async';

import 'package:expect/expect.dart';

import 'harness.dart' as harness;

bool barRunning = false;

Future<void> foo() async {
  await null;
  stacktraces.add(StackTrace.current);
}

Future<void> bar() async {
  await foo();
  stacktraces.add(StackTrace.current);
}

Future<void> runTest() {
  final Zone testZone = Zone.current.fork(
      specification: ZoneSpecification(
    registerUnaryCallback: _registerUnaryCallback,
    registerBinaryCallback: _registerBinaryCallback,
  ));
  return testZone.run(bar);
}

final stacktraces = <StackTrace>[];

ZoneUnaryCallback<R, T> _registerUnaryCallback<R, T>(
    Zone self,
    ZoneDelegate parent,
    Zone zone,
    @pragma('vm:awaiter-link') R Function(T) f) {
  stacktraces.add(StackTrace.current);
  return parent.registerUnaryCallback(zone, (v) => f(v));
}

ZoneBinaryCallback<R, T1, T2> _registerBinaryCallback<R, T1, T2>(
    Zone self,
    ZoneDelegate parent,
    Zone zone,
    @pragma('vm:awaiter-link') R Function(T1, T2) f) {
  stacktraces.add(StackTrace.current);
  return parent.registerBinaryCallback(zone, (a, b) => f(a, b));
}

Future<void> main() async {
  if (harness.shouldSkip()) {
    return;
  }

  harness.configure(currentExpectations);

  await runTest();
  for (var st in stacktraces) {
    await harness.checkExpectedStack(st);
  }
  Expect.equals(6, stacktraces.length);

  harness.updateExpectations();
}

// CURRENT EXPECTATIONS BEGIN
final currentExpectations = [
  """
#0    _registerUnaryCallback (%test%)
#1    _CustomZone.registerUnaryCallback (zone.dart)
#2    foo (%test%)
#3    bar (%test%)
#4    _rootRun (zone.dart)
#5    _CustomZone.run (zone.dart)
#6    runTest (%test%)
#7    main (%test%)
#8    _delayEntrypointInvocation.<anonymous closure> (isolate_patch.dart)
#9    _RawReceivePort._handleMessage (isolate_patch.dart)""",
  """
#0    _registerBinaryCallback (%test%)
#1    _CustomZone.registerBinaryCallback (zone.dart)
#2    foo (%test%)
#3    bar (%test%)
#4    _rootRun (zone.dart)
#5    _CustomZone.run (zone.dart)
#6    runTest (%test%)
#7    main (%test%)
#8    _delayEntrypointInvocation.<anonymous closure> (isolate_patch.dart)
#9    _RawReceivePort._handleMessage (isolate_patch.dart)""",
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
#8    _RawReceivePort._handleMessage (isolate_patch.dart)""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    main (%test%)
<asynchronous suspension>"""
];
// CURRENT EXPECTATIONS END
