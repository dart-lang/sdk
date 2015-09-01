// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

int globalVar = 100;

class MyClass {
  static int staticVar = 1000;

  static void printValue(int value) {
    print(value);   // line 17
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
  return isolate.rootLibrary.load().then((_) {
      // Set up a listener to wait for breakpoint events.
      Completer completer = new Completer();
      isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
        var subscription;
        subscription = stream.listen((ServiceEvent event) {
          if (event.kind == ServiceEvent.kPauseBreakpoint) {
            print('Breakpoint reached');
            subscription.cancel();
            completer.complete();
          }
        });
      });

      // Add the breakpoint.
      var script = isolate.rootLibrary.scripts[0];
      var line = 17;
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
      expect(stack['frames'][0].function.name, equals('printValue'));
      expect(stack['frames'][0].function.dartOwner.name, equals('MyClass'));

      var lib = isolate.rootLibrary;
      var cls = stack['frames'][0].function.dartOwner;
      var instance = stack['frames'][0].variables[0]['value'];

      List evals = [];
      evals.add(lib.evaluate('globalVar + 5').then((result) {
            print(result);
            expect(result.valueAsString, equals('105'));
          }));
      evals.add(lib.evaluate('globalVar + staticVar + 5').then((result) {
            expect(result.type, equals('Error'));
          }));
      evals.add(cls.evaluate('globalVar + staticVar + 5').then((result) {
            print(result);
            expect(result.valueAsString, equals('1105'));
          }));
      evals.add(cls.evaluate('this + 5').then((result) {
            expect(result.type, equals('Error'));
          }));
      evals.add(instance.evaluate('this + 5').then((result) {
            print(result);
            expect(result.valueAsString, equals('10005'));
          }));
      evals.add(instance.evaluate('this + frog').then((result) {
            expect(result.type, equals('Error'));
          }));
      return Future.wait(evals);
  });
},

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
