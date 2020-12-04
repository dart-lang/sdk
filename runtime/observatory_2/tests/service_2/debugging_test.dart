// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'dart:async';

int counter = 0;

void periodicTask(_) {
  counter++;
  counter++; // Line 15.  We set our breakpoint here.
  counter++;
  if (counter % 300 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  new Timer.periodic(const Duration(milliseconds: 10), periodicTask);
}

var tests = <IsolateTest>[
// Pause
  (Isolate isolate) async {
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseInterrupted) {
        subscription.cancel();
        completer.complete();
      }
    });
    isolate.pause();
    await completer.future;
  },

// Resume
  (Isolate isolate) async {
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
  },

// Add breakpoint
  (Isolate isolate) async {
    await isolate.rootLibrary.load();

    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print('Breakpoint reached');
        subscription.cancel();
        completer.complete();
      }
    });

    var script = isolate.rootLibrary.scripts[0];
    await script.load();

    // Add the breakpoint.
    var result = await isolate.addBreakpoint(script, 15);
    expect(result is Breakpoint, isTrue);
    Breakpoint bpt = result;
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location.script.id, equals(script.id));
    expect(bpt.location.script.tokenToLine(bpt.location.tokenPos), equals(15));
    expect(isolate.breakpoints.length, equals(1));

    await completer.future; // Wait for breakpoint events.
  },

// We are at the breakpoint on line 15.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    expect(script.name, endsWith('debugging_test.dart'));
    expect(
        script.tokenToLine(stack['frames'][0].location.tokenPos), equals(15));
  },

// Stepping
  (Isolate isolate) async {
    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print('Breakpoint reached');
        subscription.cancel();
        completer.complete();
      }
    });

    await isolate.stepOver();
    await completer.future; // Wait for breakpoint events.
  },

// We are now at line 16.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    expect(script.name, endsWith('debugging_test.dart'));
    expect(
        script.tokenToLine(stack['frames'][0].location.tokenPos), equals(16));
  },

// Remove breakpoint
  (Isolate isolate) async {
    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kBreakpointRemoved) {
        print('Breakpoint removed');
        expect(isolate.breakpoints.length, equals(0));
        subscription.cancel();
        completer.complete();
      }
    });

    expect(isolate.breakpoints.length, equals(1));
    var bpt = isolate.breakpoints.values.first;
    await isolate.removeBreakpoint(bpt);
    await completer.future;
  },

// Resume
  (Isolate isolate) async {
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
  },

// Add breakpoint at function entry
  (Isolate isolate) async {
    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print('Breakpoint reached');
        subscription.cancel();
        completer.complete();
      }
    });

    // Find a specific function.
    ServiceFunction function = isolate.rootLibrary.functions
        .firstWhere((f) => f.name == 'periodicTask');
    expect(function, isNotNull);

    // Add the breakpoint at function entry
    var result = await isolate.addBreakpointAtEntry(function);
    expect(result is Breakpoint, isTrue);
    Breakpoint bpt = result;
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location.script.name, equals('debugging_test.dart'));
    expect(bpt.location.script.tokenToLine(bpt.location.tokenPos), equals(12));
    expect(isolate.breakpoints.length, equals(1));

    await completer.future; // Wait for breakpoint events.
  },

// We are now at line 13.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    expect(script.name, endsWith('debugging_test.dart'));
    expect(
        script.tokenToLine(stack['frames'][0].location.tokenPos), equals(12));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: startTimer);
