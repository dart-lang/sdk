// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no-causal-async-stacks --lazy-async-stacks --verbose_debug
// VMOptions=--causal-async-stacks --no-lazy-async-stacks --verbose_debug

import 'dart:developer';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_C = 20;
const LINE_A = 26;
const LINE_B = 32;

foobar() {
  debugger();
  print('foobar'); // LINE_C.
}

helper() async {
  await 0; // force async gap
  debugger();
  print('helper'); // LINE_A.
  foobar();
}

testMain() {
  debugger();
  helper(); // LINE_B.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // No causal frames because we are in a completely synchronous stack.
    expect(stack['asyncCausalFrames'], isNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // Has causal frames (we are inside an async function)
    expect(stack['asyncCausalFrames'], isNotNull);
    var asyncStack = stack['asyncCausalFrames'];
    if (useCausalAsyncStacks) {
      expect(asyncStack[0].toString(), contains('helper'));
      expect(asyncStack[1].kind, equals(M.FrameKind.asyncSuspensionMarker));
      expect(asyncStack[2].toString(), contains('testMain'));
    } else {
      expect(asyncStack[0].toString(), contains('helper'));
      // "helper" is not await'ed.
    }
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // Has causal frames (we are inside a function called by an async function)
    expect(stack['asyncCausalFrames'], isNotNull);
    var asyncStack = stack['asyncCausalFrames'];
    if (useCausalAsyncStacks) {
      expect(asyncStack[0].toString(), contains('foobar'));
      expect(asyncStack[1].toString(), contains('helper'));
      expect(asyncStack[2].kind, equals(M.FrameKind.asyncSuspensionMarker));
      expect(asyncStack[3].toString(), contains('testMain'));
      expect(await asyncStack[0].location.toUserString(), contains('.dart:20'));
      expect(await asyncStack[1].location.toUserString(), contains('.dart:27'));
      expect(await asyncStack[3].location.toUserString(), contains('.dart:32'));
    } else {
      expect(asyncStack[0].toString(), contains('foobar'));
      expect(asyncStack[1].toString(), contains('helper'));
      // "helper" is not await'ed.
    }
  },
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
