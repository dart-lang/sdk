// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:isolate' as isolate;
import 'dart:developer' as developer;

int counter = 0;
const stoppedAtLine = 24;
var port = new isolate.RawReceivePort(msgHandler);

// This name is used in a test below.
void msgHandler(_) {}

void periodicTask(_) {
  port.sendPort.send(34);
  developer.debugger(message: "fo", when: true); // We will be at the next line.
  counter++;
  if (counter % 300 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  new Timer.periodic(const Duration(milliseconds: 10), periodicTask);
}

var tests = <IsolateTest>[
// Initial data fetch and verify we've hit the breakpoint.
  (Isolate isolate) async {
    await isolate.rootLibrary.load();
    var script = isolate.rootLibrary.scripts[0];
    await script.load();
    await hasStoppedAtBreakpoint(isolate);
    // Sanity check.
    expect(isolate.pauseEvent is M.PauseBreakpointEvent, isTrue);
  },

// Get stack
  (Isolate isolate) async {
    var stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));

    // Sanity check.
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    Script script = stack['frames'][0].location.script;
    expect(script.tokenToLine(stack['frames'][0].location.tokenPos),
        equals(stoppedAtLine));

    // Iterate over frames.
    var frameDepth = 0;
    for (var frame in stack['frames']) {
      print('checking frame $frameDepth');
      expect(frame.type, equals('Frame'));
      expect(frame.index, equals(frameDepth++));
      expect(frame.code.type, equals('Code'));
      expect(frame.function.type, equals('Function'));
      expect(frame.location.type, equals('SourceLocation'));
    }

    // Sanity check.
    expect(stack['messages'].length, greaterThanOrEqualTo(1));

    // Iterate over messages.
    var messageDepth = 0;
    // objectId of message to be handled by msgHandler.
    var msgHandlerObjectId;
    for (var message in stack['messages']) {
      print('checking message $messageDepth');
      expect(message.index, equals(messageDepth++));
      expect(message.size, greaterThanOrEqualTo(0));
      expect(message.handler.type, equals('Function'));
      expect(message.location.type, equals('SourceLocation'));
      if (message.handler.name.contains('msgHandler')) {
        msgHandlerObjectId = message.messageObjectId;
      }
    }
    expect(msgHandlerObjectId, isNotNull);

    // Get object.
    Instance object = await isolate.getObject(msgHandlerObjectId) as Instance;
    expect(object.valueAsString, equals('34'));
  }
];

main(args) => runIsolateTests(args, tests, testeeBefore: startTimer);
