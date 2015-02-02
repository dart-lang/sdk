// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  return isolate.rootLib.load().then((_) {
      // Set up a listener to wait for breakpoint events.
      Completer completer = new Completer();
      List events = [];
      isolate.vm.events.stream.listen((ServiceEvent event) {
        if (event.eventType == 'BreakpointReached') {
          print('Breakpoint reached');
          completer.complete();
        }
      });

      // Add the breakpoint.
      var script = isolate.rootLib.scripts[0];
      var line = 14;
      return isolate.addBreakpoint(script, line).then((ServiceObject bpt) {
          return completer.future;  // Wait for breakpoint reached.
      });
    });
},

// Get coverage for function, class, library, script, and isolate.
(Isolate isolate) {
  return isolate.getStack().then((ServiceMap stack) {
      // Make sure we are in the right place.
      expect(stack.type, equals('Stack'));
      expect(stack['frames'].length, greaterThanOrEqualTo(2));
      expect(stack['frames'][0]['function'].owningClass.name, equals('MyClass'));

      var lib = isolate.rootLib;
      var func = stack['frames'][0]['function'];
      expect(func.name, equals('myFunction'));
      var cls = stack['frames'][0]['function'].owningClass;
      expect(cls.name, equals('MyClass'));

      List tests = [];
      // Function
      tests.add(isolate.invokeRpcNoUpgrade('getCoverage',
                                           { 'targetId': func.id })
                .then((Map coverage) {
                    expect(coverage['type'], equals('CodeCoverage'));
                    expect(coverage['coverage'].length, equals(1));
                    expect(normalize(coverage['coverage'][0]['hits']),
                           equals([14, 1, 15, 1, 16, 0, 18, 1]));
                }));
      // Class
      tests.add(isolate.invokeRpcNoUpgrade('getCoverage',
                                           { 'targetId': cls.id })
                .then((Map coverage) {
                    expect(coverage['type'], equals('CodeCoverage'));
                    expect(coverage['coverage'].length, equals(1));
                    expect(normalize(coverage['coverage'][0]['hits']),
                           equals([14, 1, 15, 1, 16, 0, 18, 1,
                                   23, 1, 24, 1, 26, 0]));
                }));
      // Library
      tests.add(isolate.invokeRpcNoUpgrade('getCoverage',
                                           { 'targetId': lib.id })
                .then((Map coverage) {
                    expect(coverage['type'], equals('CodeCoverage'));
                    expect(coverage['coverage'].length, equals(3));
                    expect(normalize(coverage['coverage'][0]['hits']),
                           equals([14, 1, 15, 1, 16, 0, 18, 1,
                                   23, 1, 24, 1, 26, 0]));
                    expect(normalize(coverage['coverage'][1]['hits']).take(12),
                           equals([32, 0, 35, 0, 36, 0, 32, 1, 35, 1, 36, 0]));
                                   
                }));
      // Script
      tests.add(cls.load().then((_) {
            return isolate.invokeRpcNoUpgrade('getCoverage',
                                              { 'targetId': cls.script.id })
                .then((Map coverage) {
                    expect(coverage['type'], equals('CodeCoverage'));
                    expect(coverage['coverage'].length, equals(3));
                    expect(normalize(coverage['coverage'][0]['hits']),
                           equals([14, 1, 15, 1, 16, 0, 18, 1,
                                   23, 1, 24, 1, 26, 0]));
                    expect(normalize(coverage['coverage'][1]['hits']).take(12),
                           equals([32, 0, 35, 0, 36, 0, 32, 1, 35, 1, 36, 0]));
                });
          }));
      // Isolate
      tests.add(cls.load().then((_) {
            return isolate.invokeRpcNoUpgrade('getCoverage', {})
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
