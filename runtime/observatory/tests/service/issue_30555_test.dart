// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:developer';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

import "dart:isolate" as dart;

void isolate(dart.SendPort port) {
  dart.RawReceivePort receive = new dart.RawReceivePort((_) {
    debugger();
    throw new Exception();
  });
  port.send(receive.sendPort);
}

void test() {
  dart.RawReceivePort receive = new dart.RawReceivePort((port) {
    debugger();
    port.send(null);
    debugger();
    port.send(null);
    debugger();
  });
  dart.Isolate.spawn(isolate, receive.sendPort);
}

var tests = [
  (VM vm) async {
    await vm.load();
    int step = 0;
    var completer = new Completer();
    var sub;
    sub = await vm.listenEventStream("Debug", (ServiceEvent c) {
      switch (step) {
        case 0:
          if (c.kind == "PauseStart") {
            // We have intercepted the first isolate pause on start.
            // So the isolate was loading during initialization.
            // We will resume here.
            vm.isolates[0].resume();
            return;
          }
          expect(c.kind, equals("Resume"),
              reason: "First isolate should resume");
          expect(c.isolate.id, equals(vm.isolates[0].id),
              reason: "First isolate should resume");
          break;
        case 1:
          expect(c.kind, equals("PauseStart"),
              reason: "Second isolate should pause on start");
          expect(c.isolate.id, equals(vm.isolates[1].id),
              reason: "Second isolate should pause on start");
          vm.isolates[1].resume();
          break;
        case 2:
          expect(c.kind, equals("Resume"),
              reason: "Second isolate should resume");
          expect(c.isolate.id, equals(vm.isolates[1].id),
              reason: "Second isolate should resume");
          break;
        case 3:
          expect(c.kind, equals("PauseBreakpoint"),
              reason: "First isolate should stop at debugger()");
          expect(c.isolate.id, equals(vm.isolates[0].id),
              reason: "First isolate should stop at debugger()");
          vm.isolates[0].resume();
          break;
        case 4:
          expect(c.kind, equals("Resume"),
              reason: "First isolate should resume (1)");
          expect(c.isolate.id, equals(vm.isolates[0].id),
              reason: "First isolate should resume (1)");
          break;
        case 5:
          expect(c.kind, equals("PauseBreakpoint"),
              reason: "First & Second isolate should stop at debugger()");
          break;
        case 6:
          expect(c.kind, equals("PauseBreakpoint"),
              reason: "First & Second isolate should stop at debugger()");
          vm.isolates[1].resume();
          break;
        case 7:
          expect(c.kind, equals("Resume"),
              reason: "Second isolate should resume before the exception");
          expect(c.isolate.id, equals(vm.isolates[1].id),
              reason: "Second isolate should resume before the exception");
          break;
        case 8:
          expect(c.kind, equals("PauseExit"),
              reason: "Second isolate should exit at the exception");
          expect(c.isolate.id, equals(vm.isolates[1].id),
              reason: "Second isolate should exit at the exception");
          vm.isolates[0].resume();
          break;
        case 9:
          expect(c.kind, equals("Resume"),
              reason: "First isolate should resume after the exception");
          expect(c.isolate.id, equals(vm.isolates[0].id),
              reason: "First isolate should resume after the exception");
          break;
        case 10:
          expect(c.kind, equals("PauseBreakpoint"),
              reason: "First isolate "
                  "should stop at debugger() after exception.\n"
                  "Probably the second resumed even though it was not expect "
                  "to do it.");
          expect(c.isolate.id, equals(vm.isolates[0].id),
              reason: "First "
                  "isolate should stop at debugger() after exception.\n"
                  "Probably the second resumed even though it was not expect "
                  "to do it.");
          completer.complete();
          break;
        default:
          expect(false, isTrue,
              reason: "Shouldn't get here, the second "
                  "isolate resumed even though it was not expect to do it");
          break;
      }
      step++;
    });
    switch (vm.isolates[0].status) {
      case M.IsolateStatus.loading:
        // It is still loading we will resume in the stream listener.
        break;
      case M.IsolateStatus.paused:
        // It is already paused we will resume here.
        vm.isolates[0].resume();
        break;
      default:
        expect(false, isTrue,
            reason: "The first isolate should be loading or paused on start");
    }
    await completer.future;
    // We wait 1 second to account for delays in the service protocol.
    // A late message can still arrive.
    await new Future.delayed(const Duration(seconds: 1));
    // No fails, tear down the stream.
    sub.cancel();
  }
];

main(args) async => runVMTests(args, tests,
    pause_on_start: true, pause_on_exit: true, testeeConcurrent: test);
