// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

import 'dart:async';
import 'dart:math' as math;

breakHere() {}

use(dynamic v) => v;

class C {
  var instVar = 1;
  static var classVar = 2;

  method(methodParam) {
    var methodTemp = 4;
    use(methodTemp);
    [5].forEach((outerParam) {
      var outerTemp = 6;
      use(outerTemp);
      [7].forEach((innerParam) {
        var innerTemp = 8;
        use(innerTemp);
        breakHere();
      });
    });
  }

  static method2(methodParam) {
    var methodTemp = 4;
    use(methodTemp);
    [5].forEach((outerParam) {
      var outerTemp = 6;
      use(outerTemp);
      [7].forEach((innerParam) {
        var innerTemp = 8;
        use(innerTemp);
        breakHere();
      });
    });
  }

  method3(methodParam) {
    var methodTemp = 4;
    use(methodTemp);
    breakHere();
  }

  static var closureWithReturnedHome;
  method4(methodParam) {
    var methodTemp = 4;
    use(methodTemp);
    [5].forEach((outerParam) {
      var outerTemp = 6;
      use(outerTemp);
      closureWithReturnedHome = (innerParam) {
        var innerTemp = 8;
        use(innerTemp);
        breakHere();
      };
    });
  }
}

Future testMethod(Isolate isolate) async {
  // silence analyzer.
  expect(math.sqrt(4), equals(2));
  Library rootLib = await isolate.rootLibrary.load();
  ServiceFunction function =
      rootLib.functions.singleWhere((f) => f.name == 'breakHere');
  Breakpoint bpt = await isolate.addBreakpointAtEntry(function);
  print("Breakpoint: $bpt");
  expect(bpt is Breakpoint, isTrue);  // I.e, not null.

  bool hitBreakpoint = false;
  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  var sub;
  sub = stream.listen((ServiceEvent event) async {
    print("Event $event");
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      var frameNumber = 1, r;
      r = await isolate.evalFrame(frameNumber, '123');  /// instance: ok
      expect(r.valueAsString, equals('123'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'this');  /// scope: ok
      expect(r.clazz.name, equals('C'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'instVar');  /// instance: continued
      expect(r.valueAsString, equals('1'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'classVar'); /// instance: continued
      expect(r.valueAsString, equals('2'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'methodParam');  /// scope: continued
      expect(r.valueAsString, equals('3'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'methodTemp');  /// scope: continued
      expect(r.valueAsString, equals('4'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'outerParam');  /// scope: continued
      expect(r.valueAsString, equals('5'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'outerTemp');  /// scope: continued
      expect(r.valueAsString, equals('6'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'innerParam');  /// instance: continued
      expect(r.valueAsString, equals('7'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'innerTemp');  /// instance: continued
      expect(r.valueAsString, equals('8'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'math.sqrt');  /// instance: continued
      expect(r.isClosure, isTrue);  /// instance: continued

      hitBreakpoint = true;
      sub.cancel();  // Do not handle events for the other tests.
      isolate.resume();
    }
  });

  var result = await rootLib.evaluate('new C().method(3)');
  print("Result $result");
  expect(hitBreakpoint, isTrue);
}

Future testMethod2(Isolate isolate) async {
  Library rootLib = await isolate.rootLibrary.load();
  ServiceFunction function =
      rootLib.functions.singleWhere((f) => f.name == 'breakHere');
  Breakpoint bpt = await isolate.addBreakpointAtEntry(function);
  print("Breakpoint: $bpt");
  expect(bpt is Breakpoint, isTrue);  // I.e, not null.

  bool hitBreakpoint = false;
  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  var sub;
  sub = stream.listen((ServiceEvent event) async {
    print("Event $event");
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      var frameNumber = 1, r;
      r = await isolate.evalFrame(frameNumber, '123');
      expect(r.valueAsString, equals('123'));
      r = await isolate.evalFrame(frameNumber, 'this');
      expect(r is DartError, isTrue);
      r = await isolate.evalFrame(frameNumber, 'instVar');
      expect(r is DartError, isTrue);
      r = await isolate.evalFrame(frameNumber, 'classVar');
      expect(r.valueAsString, equals('2'));
      r = await isolate.evalFrame(frameNumber, 'methodParam');
      expect(r.valueAsString, equals('3'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'methodTemp');
      expect(r.valueAsString, equals('4'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'outerParam');
      expect(r.valueAsString, equals('5'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'outerTemp');
      expect(r.valueAsString, equals('6'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'innerParam');
      expect(r.valueAsString, equals('7'));
      r = await isolate.evalFrame(frameNumber, 'innerTemp');
      expect(r.valueAsString, equals('8'));
      r = await isolate.evalFrame(frameNumber, 'math.sqrt');
      expect(r.isClosure, isTrue);

      hitBreakpoint = true;
      sub.cancel();  // Do not handle events for the other tests.
      isolate.resume();
    }
  });

  var result = await rootLib.evaluate('C.method2(3)');
  print("Result $result");
  expect(hitBreakpoint, isTrue);
}

Future testMethod3(Isolate isolate) async {
  Library rootLib = await isolate.rootLibrary.load();
  ServiceFunction function =
      rootLib.functions.singleWhere((f) => f.name == 'breakHere');
  Breakpoint bpt = await isolate.addBreakpointAtEntry(function);
  print("Breakpoint: $bpt");
  expect(bpt is Breakpoint, isTrue);  // I.e, not null.

  bool hitBreakpoint = false;
  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  var sub;
  sub = stream.listen((ServiceEvent event) async {
    print("Event $event");
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      var frameNumber = 1, r;
      r = await isolate.evalFrame(frameNumber, '123');
      expect(r.valueAsString, equals('123'));
      r = await isolate.evalFrame(frameNumber, 'this');
      expect(r.clazz.name, equals('C'));
      r = await isolate.evalFrame(frameNumber, 'instVar');
      expect(r.valueAsString, equals('1'));
      r = await isolate.evalFrame(frameNumber, 'classVar');
      expect(r.valueAsString, equals('2'));
      r = await isolate.evalFrame(frameNumber, 'methodParam');
      expect(r.valueAsString, equals('3'));
      r = await isolate.evalFrame(frameNumber, 'methodTemp');
      expect(r.valueAsString, equals('4'));
      r = await isolate.evalFrame(frameNumber, 'math.sqrt');
      expect(r.isClosure, isTrue);

      hitBreakpoint = true;
      sub.cancel();  // Do not handle events for the other tests.
      isolate.resume();
    }
  });

  var result = await rootLib.evaluate('new C().method3(3)');
  print("Result $result");
  expect(hitBreakpoint, isTrue);
}


Future testMethod4(Isolate isolate) async {
  Library rootLib = await isolate.rootLibrary.load();
  ServiceFunction function =
      rootLib.functions.singleWhere((f) => f.name == 'breakHere');
  Breakpoint bpt = await isolate.addBreakpointAtEntry(function);
  print("Breakpoint: $bpt");
  expect(bpt is Breakpoint, isTrue);  // I.e, not null.

  bool hitBreakpoint = false;
  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  var sub;
  sub = stream.listen((ServiceEvent event) async {
    print("Event $event");
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      var frameNumber = 1, r;
      r = await isolate.evalFrame(frameNumber, '123');  /// instance: continued
      expect(r.valueAsString, equals('123'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'this');  /// scope: continued
      expect(r.clazz.name, equals('C'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'instVar');  /// instance: continued
      expect(r.valueAsString, equals('1'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'classVar');  /// instance: continued
      expect(r.valueAsString, equals('2'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'methodParam');  /// scope: continued
      expect(r.valueAsString, equals('3'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'methodTemp');  /// scope: continued
      expect(r.valueAsString, equals('4'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'outerParam');  /// scope: continued
      expect(r.valueAsString, equals('5'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'outerTemp');  /// scope: continued
      expect(r.valueAsString, equals('6'));  /// scope: continued
      r = await isolate.evalFrame(frameNumber, 'innerParam');  /// instance: continued
      expect(r.valueAsString, equals('7'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'innerTemp');  /// instance: continued
      expect(r.valueAsString, equals('8'));  /// instance: continued
      r = await isolate.evalFrame(frameNumber, 'math.sqrt');  /// instance: continued
      expect(r.isClosure, isTrue);  /// instance: continued

      hitBreakpoint = true;
      sub.cancel();  // Do not handle events for the other tests.
      isolate.resume();
    }
  });

  var result = await rootLib.evaluate(
      '(){ new C().method4(3); C.closureWithReturnedHome(7); }()');
  print("Result $result");
  expect(hitBreakpoint, isTrue);
}

var tests = <IsolateTest>[
  testMethod,
  testMethod2,
  testMethod3,
  testMethod4,
];

main(args) => runIsolateTests(args, tests);
