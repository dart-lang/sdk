// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:isolate';

int counter = 0;
const stoppedAtLine = 23;
var port = new RawReceivePort(msgHandler);

// This name is used in a test below.
void msgHandler(_) {
}

void periodicTask(_) {
  counter++;
  port.sendPort.send(34);
  counter++;  // Line 23.  We set our breakpoint here.
  counter++;
  if (counter % 300 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  new Timer.periodic(const Duration(milliseconds:10), periodicTask);
}

var tests = [

// Add breakpoint
(Isolate isolate) async {
  await isolate.rootLib.load();

  // Set up a listener to wait for breakpoint events.
  Completer completer = new Completer();
  var subscription;
  subscription = isolate.vm.events.stream.listen((ServiceEvent event) {
    if (event.eventType == ServiceEvent.kPauseBreakpoint) {
      print('Breakpoint reached');
      subscription.cancel();
      completer.complete();
    }
  });

  var script = isolate.rootLib.scripts[0];
  await script.load();

  // Add the breakpoint.
  var result = await isolate.addBreakpoint(script, stoppedAtLine);
  expect(result is Breakpoint, isTrue);
  Breakpoint bpt = result;
  expect(bpt.type, equals('Breakpoint'));
  expect(bpt.script.id, equals(script.id));
  expect(bpt.script.tokenToLine(bpt.tokenPos), equals(stoppedAtLine));
  expect(isolate.breakpoints.length, equals(1));

  await completer.future;  // Wait for breakpoint events.
},

// Get stack
(Isolate isolate) async {
  var stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));

  // Sanity check.
  expect(stack['frames'].length, greaterThanOrEqualTo(1));
  Script script = stack['frames'][0]['script'];
  expect(script.tokenToLine(stack['frames'][0]['tokenPos']),
         equals(stoppedAtLine));

  // Iterate over frames.
  var frameDepth = 0;
  for (var frame in stack['frames']) {
    print('checking frame $frameDepth');
    expect(frame.type, equals('Frame'));
    expect(frame['depth'], equals(frameDepth++));
    expect(frame['code'].type, equals('Code'));
    expect(frame['function'].type, equals('Function'));
    expect(frame['script'].type, equals('Script'));
    expect(frame['tokenPos'], isNotNull);
  }

  // Sanity check.
  expect(stack['messages'].length, greaterThanOrEqualTo(1));

  // Iterate over messages.
  var messageDepth = 0;
  // objectId of message to be handled by msgHandler.
  var msgHandlerObjectId;
  for (var message in stack['messages']) {
    print('checking message $messageDepth');
    expect(message.type, equals('Message'));
    expect(message['_destinationPort'], isNotNull);
    expect(message['depth'], equals(messageDepth++));
    expect(message['name'], isNotNull);
    expect(message['size'], greaterThanOrEqualTo(1));
    expect(message['priority'], isNotNull);
    expect(message['handlerFunction'].type, equals('Function'));
    if (message['handlerFunction'].name.contains('msgHandler')) {
      msgHandlerObjectId = message['messageObjectId'];
    }
  }
  expect(msgHandlerObjectId, isNotNull);

  // Get object.
  var object = await isolate.getObject(msgHandlerObjectId);
  expect(object.valueAsString, equals('34'));
}

];

main(args) => runIsolateTests(args, tests, testeeBefore: startTimer);
