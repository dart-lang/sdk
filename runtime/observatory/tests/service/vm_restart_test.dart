// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

int count = 0;

void test() {
  while (true) {
    count++;
    debugger();
  }
}

var tests = [
  hasStoppedAtBreakpoint,

  (Isolate isolate) async {
    // The loop has run one time.
    var result = await isolate.rootLibrary.evaluate('count');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('1'));

    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kResume) {
        subscription.cancel();
        completer.complete();
      }
    });
    isolate.resume();
    await completer.future;

    // The loop has run twice.
    result = await isolate.rootLibrary.evaluate('count');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('2'));
  },

  hasStoppedAtBreakpoint,

  (Isolate isolate) async {
    Isolate newIsolate = null;

    Completer testCompleter = new Completer();
    var debugStream = await isolate.vm.getEventStream(VM.kDebugStream);
    var debugSub;
    debugSub = debugStream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        if (event.isolate == newIsolate) {
          // The old isolate has died and the new isolate is at
          // the breakpoint.
          newIsolate.reload().then((_) {
            newIsolate.rootLibrary.evaluate('count').then((result) {
              expect(result.type, equals('Instance'));
              expect(result.valueAsString, equals('1'));
              debugSub.cancel();
              testCompleter.complete();
            });
          });
        }
      }
    });
    
    Completer restartCompleter = new Completer();
    var isolateStream = await isolate.vm.getEventStream(VM.kIsolateStream);
    var isolateSub;
    bool exit = false;
    bool start = false;
    isolateSub = isolateStream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kIsolateExit) {
        expect(event.isolate, equals(isolate));
        print('Old isolate exited');
        exit = true;
      }
      if (event.kind == ServiceEvent.kIsolateStart) {
        print('New isolate started');
        newIsolate = event.isolate;
        start = true;
      }
      if (exit && start) {
        isolateSub.cancel();
        restartCompleter.complete();
      }
    });

    // Restart the vm.
    print("restarting");
    await isolate.vm.restart();
    await restartCompleter.future;
    print("restarted");
    await testCompleter.future;
  },
];

  
main(args) => runIsolateTests(args, tests, testeeConcurrent: test);
