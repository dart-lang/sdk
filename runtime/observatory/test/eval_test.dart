// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

int globalVar = 100;

class MyClass {
  static int staticVar = 1000;

  static void printValue(int value) {
    print(value);   // line 16
  }
}

void testFunction() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      MyClass.printValue(10000);
    }
  }
}

var tests = [

// Go to breakpoint at line 16.
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
      var line = 16;
      return isolate.addBreakpoint(script, line).then((ServiceObject bpt) {
          return completer.future;  // Wait for breakpoint reached.
      });
    });
},

// Evaluate against library, class, and instance.
(Isolate isolate) {
  return isolate.getStack().then((ServiceMap stack) {
      // Make sure we are in the right place.
      expect(stack.type, equals('Stack'));
      expect(stack['frames'].length, greaterThanOrEqualTo(2));
      expect(stack['frames'][0]['function'].name, equals('printValue'));
      expect(stack['frames'][0]['function'].owningClass.name, equals('MyClass'));

      var lib = isolate.rootLib;
      var cls = stack['frames'][0]['function'].owningClass;
      var instance = stack['frames'][0]['vars'][0]['value'];

      List evals = [];
      evals.add(isolate.eval(lib, 'globalVar + 5').then((result) {
            print(result);
            expect(result.valueAsString, equals('105'));
          }));
      evals.add(isolate.eval(lib, 'globalVar + staticVar + 5').then((result) {
            expect(result.type, equals('Error'));
          }));
      evals.add(isolate.eval(cls, 'globalVar + staticVar + 5').then((result) {
            print(result);
            expect(result.valueAsString, equals('1105'));
          }));
      evals.add(isolate.eval(cls, 'this + 5').then((result) {
            expect(result.type, equals('Error'));
          }));
      evals.add(isolate.eval(instance, 'this + 5').then((result) {
            print(result);
            expect(result.valueAsString, equals('10005'));
          }));
      evals.add(isolate.eval(instance, 'this + frog').then((result) {
            expect(result.type, equals('Error'));
          }));
      return Future.wait(evals);
  });
},

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
