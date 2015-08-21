// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'test_helper.dart';
import 'dart:async';

void testMain() {
  print('Hello');
}

var tests = [

(Isolate isolate) async {
  Completer completer = new Completer();
  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  var subscription;
  subscription = stream.listen((ServiceEvent event) {
    if (event.kind == ServiceEvent.kPauseStart) {
      print('Received PauseStart');
      subscription.cancel();
      completer.complete();
    }
  });

  if (isolate.pauseEvent != null &&
      isolate.pauseEvent.kind == ServiceEvent.kPauseStart) {
    // Wait for the isolate to hit PauseStart.
    subscription.cancel();
    print('subscription cancelled.');
  } else {
    print('waiting for pause start event.');
    await completer.future;
  }

  completer = new Completer();
  stream = await isolate.vm.getEventStream(VM.kDebugStream);
  subscription = stream.listen((ServiceEvent event) {
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      print('Received PauseBreakpoint');
      subscription.cancel();
      completer.complete();
    }
    print('Got ${event.kind}');
  });

  print('Stepping...');
  isolate.stepInto();

  // Wait for the isolate to hit PauseBreakpoint.
  print('Waiting for PauseBreakpoint');
  await completer.future;
},

];

main(args) => runIsolateTests(args, tests,
                              testeeConcurrent: testMain,
                              pause_on_start: true, pause_on_exit: true);
