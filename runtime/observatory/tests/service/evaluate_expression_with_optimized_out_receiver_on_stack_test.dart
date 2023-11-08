// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

import 'dart:async';
import 'dart:_internal'; // ignore: import_internal_library, unused_import

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

String examineStackExpression(String variableName) {
  // The returned string is the evaluation expression. We try to make it so that
  // the evaluated expression exercises OSR, Deopt, StackTrace.
  //
  // Even though the expression we build doesn't use `this`, the expression is
  // evaluated in the context of a closure that's inside an instance method. So
  // the evaluation function will be an instance method that does receive a
  // receiver that was "<optimized out>".
  // => The purpose of the test is to see if having the sentinal as receiver
  // causes any issues.
  final entries = [
    // Obtain stack while eval function is unoptimized
    'triggerStackTrace()',

    // Get eval function OSRed
    'for (int i = 0; i < 100 * 1000; ++i) i',

    // Obtain stack while eval function is optimized.
    'triggerStackTrace()',

    // Deopt eval function.
    'triggerDeopt()',
  ];
  final round = entries.join(', ');
  return 'returnFirst([$variableName, $round, $round, $round])';
}

@pragma('vm:never-inline')
dynamic triggerDeopt() {
  print('triggerDeopt');
  VMInternalsForTesting.deoptimizeFunctionsOnStack();  // ignore: undefined_identifier
}

@pragma('vm:never-inline')
dynamic triggerStackTrace() {
  print('triggerStackTrace');
  return StackTrace.current;
}

@pragma('vm:never-inline')
dynamic returnFirst(List l) {
  print('returnFirst');
  return l.first;
}

breakHere() {}

use(dynamic v) => v;

class C {
  var instVar = 1;

  method(methodParam) {
    var methodTemp = 3;
    use(methodTemp);
    [4].forEach((outerParam) {
      var outerTemp = 5;
      use(outerTemp);
      [6].forEach((innerParam) {
        var innerTemp = 7;
        use(innerTemp);
        breakHere();
      });
    });
  }
}

Future testMethod(Isolate isolate) async {
  final rootLib = await isolate.rootLibrary.load() as Library;
  final function = rootLib.functions.singleWhere((f) => f.name == 'breakHere');
  final bpt = await isolate.addBreakpointAtEntry(function);
  print("Breakpoint: $bpt");

  final stream = await isolate.vm.getEventStream(VM.kDebugStream);
  final hitBreakpointFuture = stream.firstWhere((event) {
    print("Event $event");
    return event.kind == ServiceEvent.kPauseBreakpoint;
  });

  Future handleBreakpoint() async {
    Future checkValue(String expr, String value) async {
      print('Evaluating "$expr".');
      const frameNumber = 1;
      final dynamic r = await isolate.evalFrame(frameNumber, expr);
      print(' -> result $r');
      expect(r.valueAsString, equals(value));
    }

    print('waiting for breakpoint');
    await hitBreakpointFuture;
    print('got breakpoint');
    await checkValue(examineStackExpression('this'), '<optimized out>');
    await checkValue(examineStackExpression('instVar'), '<optimized out>');
    await checkValue(examineStackExpression('innerParam'), '6');
    await checkValue(examineStackExpression('innerTemp'), '7');

    await isolate.resume();
    print('resuming ');
  }

  await Future.wait([
    handleBreakpoint(),
    rootLib.evaluate('C().method(2)'),
  ]);
}

final tests = <IsolateTest>[
  testMethod,
];

main(args) => runIsolateTests(args, tests);
