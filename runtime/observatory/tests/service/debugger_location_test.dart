// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:observatory/debugger.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:developer';

const int LINE_A = 22;
const int LINE_B = 112;
const int LINE_C = 12;

void testFunction() {
  int i = 0;
  while (i == 0) {
    debugger();
    print('loop');  // Line A.
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

void debugger_location_dummy_function() {
}

class DebuggerLocationTestFoo {
  DebuggerLocationTestFoo(this.field);
  DebuggerLocationTestFoo.named();

  void method() {}
  void madness() {}

  int field;
}

class DebuggerLocationTestBar {
}

Future<Debugger> initDebugger(Isolate isolate) {
  return isolate.getStack().then((stack) {
    return new TestDebugger(isolate, stack);
  });
}

var tests = [

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
  var loc = await DebuggerLocation.parse(debugger, 'unittest.dart:15');
  expect(loc.valid, isTrue);
  expect(loc.toString(), equals('unittest.dart:15'));
},

// Parse script + line + col
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var loc = await DebuggerLocation.parse(debugger, 'unittest.dart:15:10');
  expect(loc.valid, isTrue);
  expect(loc.toString(), equals('unittest.dart:15:10'));
},

// Parse bad script
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var loc = await DebuggerLocation.parse(debugger, 'bad.dart:15');
  expect(loc.valid, isFalse);
  expect(loc.toString(), equals(
      'invalid source location (Script \'bad.dart\' not found)'));
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
  expect(loc.toString(), equals(
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
  expect(loc.toString(), equals(
      'DebuggerLocationTestFoo.DebuggerLocationTestFoo'));
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
  expect(loc.toString(), equals(
      'DebuggerLocationTestFoo.DebuggerLocationTestFoo.named'));
},

// Parse method
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var loc =
      await DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo.method');
  expect(loc.valid, isTrue);
  expect(loc.toString(), equals('DebuggerLocationTestFoo.method'));
},

// Parse method
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var loc =
      await DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo.field=');
  expect(loc.valid, isTrue);
  expect(loc.toString(), equals('DebuggerLocationTestFoo.field='));
},

// Parse bad method
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var loc =
    await DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo.missing');
  expect(loc.valid, isFalse);
  expect(loc.toString(), equals(
      'invalid source location '
      '(Function \'DebuggerLocationTestFoo.missing\' not found)'));
},

// Complete function + script
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var completions = await DebuggerLocation.complete(debugger, 'debugger_loc');
  expect(completions.toString(), equals(
      '[debugger_location_dummy_function,'
      ' debugger_location.dart:,'
      ' debugger_location_test.dart:]'));
},

// Complete class
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var completions =
      await DebuggerLocation.complete(debugger, 'DebuggerLocationTe');
  expect(completions.toString(), equals(
      '[DebuggerLocationTestBar,'
      ' DebuggerLocationTestFoo]'));
},

// No completions: unqualified name
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var completions =
      await DebuggerLocation.complete(debugger, 'debugger_locXYZZY');
  expect(completions.toString(), equals('[]'));
},

// Complete method
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var completions =
      await DebuggerLocation.complete(debugger, 'DebuggerLocationTestFoo.m');
  expect(completions.toString(), equals(
      '[DebuggerLocationTestFoo.madness,'
      ' DebuggerLocationTestFoo.method]'));
},

// No completions: qualified name
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var completions =
      await DebuggerLocation.complete(debugger, 'DebuggerLocationTestFoo.q');
  expect(completions.toString(), equals('[]'));
},

// Complete script
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var completions =
      await DebuggerLocation.complete(debugger, 'debugger_location_te');
  expect(completions.toString(), equals(
      '[debugger_location_test.dart:]'));
},

// Complete script:line
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var completions =
      await DebuggerLocation.complete(debugger,
                                      'debugger_location_test.dart:11');
  expect(completions.toString(), equals(
      '[debugger_location_test.dart:${LINE_B + 0} ,'
      ' debugger_location_test.dart:${LINE_B + 0}:,'
      ' debugger_location_test.dart:${LINE_B + 1} ,'
      ' debugger_location_test.dart:${LINE_B + 1}:,'
      ' debugger_location_test.dart:${LINE_B + 2} ,'
      ' debugger_location_test.dart:${LINE_B + 2}:,'
      ' debugger_location_test.dart:${LINE_B + 3} ,'
      ' debugger_location_test.dart:${LINE_B + 3}:,'
      ' debugger_location_test.dart:${LINE_B + 4} ,'
      ' debugger_location_test.dart:${LINE_B + 4}:,'
      ' debugger_location_test.dart:${LINE_B + 5} ,'
      ' debugger_location_test.dart:${LINE_B + 5}:]'));
},

// Complete script:line:col
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var completions =
      await DebuggerLocation.complete(debugger,
                                      'debugger_location_test.dart:$LINE_C:2');
  expect(completions.toString(), equals(
      '[debugger_location_test.dart:$LINE_C:2 ,'
      ' debugger_location_test.dart:$LINE_C:20 ,'
      ' debugger_location_test.dart:$LINE_C:21 ,'
      ' debugger_location_test.dart:$LINE_C:22 ,'
      ' debugger_location_test.dart:$LINE_C:23 ,'
      ' debugger_location_test.dart:$LINE_C:24 ]'));
},

// Complete without the script name.
(Isolate isolate) async {
  var debugger = await initDebugger(isolate);
  var completions = await DebuggerLocation.complete(debugger, '$LINE_C:2');
  expect(completions.toString(), equals(
      '[debugger_location_test.dart:$LINE_C:2 ,'
      ' debugger_location_test.dart:$LINE_C:20 ,'
      ' debugger_location_test.dart:$LINE_C:21 ,'
      ' debugger_location_test.dart:$LINE_C:22 ,'
      ' debugger_location_test.dart:$LINE_C:23 ,'
      ' debugger_location_test.dart:$LINE_C:24 ]'));
},

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
