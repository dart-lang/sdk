// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory/debugger.dart';
import 'package:observatory/service.dart' as S;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

class Foo {}

code() {
  new Foo();
}

class TestDebugger extends Debugger {
  TestDebugger(this.isolate, this.stack);

  VM get vm => isolate.vm;
  Isolate isolate;
  ServiceMap stack;
  int currentFrame = 0;
}

Future<Debugger> initDebugger(Isolate isolate) {
  return isolate.getStack().then((stack) {
    return new TestDebugger(isolate, stack);
  });
}

List<String> stops = [];

var tests = <IsolateTest>[
  hasPausedAtStart,
  // Load the isolate's libraries
  (Isolate isolate) async {
    for (var lib in isolate.libraries) {
      await lib.load();
    }
  },

  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(debugger, 'Foo');

    if (loc.valid) {
      if (loc.function != null) {
        try {
          await debugger.isolate.addBreakpointAtEntry(loc.function!);
        } on S.ServerRpcException catch (e) {
          if (e.code == S.ServerRpcException.kCannotAddBreakpoint) {
            // Expected
          } else {
            fail("Got unexpected error $e");
          }
        }
      } else {
        fail("Expected to find function");
      }
    } else {
      fail("Expected to find function");
    }

    await isolate.resume();
  }
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
