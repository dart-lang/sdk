// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

int globalVar = 100;

class MyClass {
  static void myFunction(int value) {
    print(value);  // line 14
    if (value < 0) {
      print("negative");
    } else {
      print("positive");
    }
  }

  static void otherFunction(int value) {
    if (value < 0) {
      print("otherFunction <");
    } else {
      print("otherFunction >=");
    }
  }
}

void testFunction() {
  MyClass.otherFunction(-100);
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      MyClass.myFunction(10000);
    }
  }
}

List normalize(List coverage) {
  // The exact coverage numbers may vary based on how many times
  // things run.  Normalize the data to 0 or 1.
  List normalized = [];
  for (int i = 0; i < coverage.length; i += 2) {
    normalized.add(coverage[i]);
    normalized.add(coverage[i+1] == 0 ? 0 : 1);
  }
  return normalized;
}

var tests = [

// Go to breakpoint at line 14.
(Isolate isolate) {
  return isolate.rootLibrary.load().then((_) {
      // Set up a listener to wait for breakpoint events.
      Completer completer = new Completer();
      isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
        var subscription;
        subscription = stream.listen((ServiceEvent event) {
          if (event.kind == ServiceEvent.kPauseBreakpoint) {
            print('Breakpoint reached');
            completer.complete();
            subscription.cancel();
          }
        });
      });

      // Create a timer to set a breakpoint with a short delay.
      new Timer(new Duration(milliseconds: 2000), () {
        // Add the breakpoint.
        print('Setting breakpoint.');
        var script = isolate.rootLibrary.scripts[0];
        var line = 14;
        isolate.addBreakpoint(script, line);
      });

      return completer.future;
    });
},

// Get coverage for function, class, library, script, and isolate.
(Isolate isolate) {
  return isolate.getStack().then((ServiceMap stack) {
      // Make sure we are in the right place.
      expect(stack.type, equals('Stack'));
      expect(stack['frames'].length, greaterThanOrEqualTo(2));
      expect(stack['frames'][0].function.name, equals('myFunction'));
      expect(stack['frames'][0].function.dartOwner.name, equals('MyClass'));

      var lib = isolate.rootLibrary;
      var func = stack['frames'][0].function;
      expect(func.name, equals('myFunction'));
      var cls = func.dartOwner;
      expect(cls.name, equals('MyClass'));

      List tests = [];
      // Function
      tests.add(isolate.invokeRpcNoUpgrade('_getCoverage',
                                           { 'targetId': func.id })
                .then((Map coverage) {
                    expect(coverage['type'], equals('CodeCoverage'));
                    expect(coverage['coverage'].length, equals(1));
                    expect(normalize(coverage['coverage'][0]['hits']),
                           equals([15, 1, 16, 1, 17, 0, 19, 1]));
                }));
      // Class
      tests.add(isolate.invokeRpcNoUpgrade('_getCoverage',
                                           { 'targetId': cls.id })
                .then((Map coverage) {
                    expect(coverage['type'], equals('CodeCoverage'));
                    expect(coverage['coverage'].length, equals(1));
                    expect(normalize(coverage['coverage'][0]['hits']),
                           equals([15, 1, 16, 1, 17, 0, 19, 1,
                                   24, 1, 25, 1, 27, 0]));
                }));
      // Library
      tests.add(isolate.invokeRpcNoUpgrade('_getCoverage',
                                           { 'targetId': lib.id })
                .then((Map coverage) {
                    expect(coverage['type'], equals('CodeCoverage'));
                    expect(coverage['coverage'].length, equals(3));
                    expect(normalize(coverage['coverage'][0]['hits']),
                           equals([15, 1, 16, 1, 17, 0, 19, 1,
                                   24, 1, 25, 1, 27, 0]));
                    expect(normalize(coverage['coverage'][1]['hits']).take(12),
                           equals([33, 1, 36, 1, 37, 0, 32, 1, 45, 0, 46, 0]));
                }));
      // Script
      tests.add(cls.load().then((_) {
            return isolate.invokeRpcNoUpgrade(
                '_getCoverage',
                { 'targetId': cls.location.script.id })
                .then((Map coverage) {
                    expect(coverage['type'], equals('CodeCoverage'));
                    expect(coverage['coverage'].length, equals(3));
                    expect(normalize(coverage['coverage'][0]['hits']),
                           equals([15, 1, 16, 1, 17, 0, 19, 1,
                                   24, 1, 25, 1, 27, 0]));
                    expect(normalize(coverage['coverage'][1]['hits']).take(12),
                           equals([33, 1, 36, 1, 37, 0, 32, 1, 45, 0, 46, 0]));
                });
          }));
      // Isolate
      tests.add(cls.load().then((_) {
            return isolate.invokeRpcNoUpgrade('_getCoverage', {})
                .then((Map coverage) {
                    expect(coverage['type'], equals('CodeCoverage'));
                    expect(coverage['coverage'].length, greaterThan(100));
                });
          }));
      return Future.wait(tests);
  });
},

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
