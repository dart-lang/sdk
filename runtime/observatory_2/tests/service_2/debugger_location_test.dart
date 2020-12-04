// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:observatory_2/debugger.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:developer';

const int LINE_A = 21;
const int LINE_B = 111;
const int LINE_C = 11;

void testFunction() {
  int i = 0;
  while (i == 0) {
    debugger();
    print('loop'); // Line A.
    print('loop');
  }
}

class TestDebugger extends Debugger {
  TestDebugger(this.isolate, this.stack);

  VM get vm => isolate.vm;
  Isolate isolate;
  ServiceMap stack;
  int currentFrame = 0;
}

void debugger_location_dummy_function() {}

class DebuggerLocationTestFoo {
  DebuggerLocationTestFoo(this.field);
  DebuggerLocationTestFoo.named();

  void method() {}
  void madness() {}

  int field;
}

class DebuggerLocationTestBar {}

Future<Debugger> initDebugger(Isolate isolate) {
  return isolate.getStack().then((stack) {
    return new TestDebugger(isolate, stack);
  });
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Parse '' => current position
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(debugger, '');
    expect(loc.valid, isTrue);
    expect(loc.toString(), equals('debugger_location_test.dart:$LINE_A:5'));
  },

// Parse line
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(debugger, '18');
    expect(loc.valid, isTrue);
    expect(loc.toString(), equals('debugger_location_test.dart:18'));
  },

// Parse line + col
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(debugger, '16:11');
    expect(loc.valid, isTrue);
    expect(loc.toString(), equals('debugger_location_test.dart:16:11'));
  },

// Parse script + line
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(
        debugger, 'debugger_location_test.dart:16');
    expect(loc.valid, isTrue);
    expect(loc.toString(), equals('debugger_location_test.dart:16'));
  },

// Parse script + line + col
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(
        debugger, 'debugger_location_test.dart:16:11');
    expect(loc.valid, isTrue);
    expect(loc.toString(), equals('debugger_location_test.dart:16:11'));
  },

// Parse bad script
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(debugger, 'bad.dart:15');
    expect(loc.valid, isFalse);
    expect(loc.toString(),
        equals('invalid source location (Script \'bad.dart\' not found)'));
  },

// Parse function
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(debugger, 'testFunction');
    expect(loc.valid, isTrue);
    expect(loc.toString(), equals('testFunction'));
  },

// Parse bad function
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(debugger, 'doesNotReallyExist');
    expect(loc.valid, isFalse);
    expect(
        loc.toString(),
        equals(
            'invalid source location (Function \'doesNotReallyExist\' not found)'));
  },

// Parse constructor
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc = await DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo');
    expect(loc.valid, isTrue);
    // TODO(turnidge): Printing a constructor currently adds
    // another class qualifier at the front.  Do we want to change
    // this to be more consistent?
    expect(loc.toString(),
        equals('DebuggerLocationTestFoo.DebuggerLocationTestFoo'));
  },

// Parse named constructor
  (Isolate isolate) async {
    var debugger = await initDebugger(isolate);
    var loc =
        await DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo.named');
    expect(loc.valid, isTrue);
    // TODO(turnidge): Printing a constructor currently adds
    // another class qualifier at the front.  Do we want to change
    // this to be more consistent?
    expect(loc.toString(),
        equals('DebuggerLocationTestFoo.DebuggerLocationTestFoo.named'));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
