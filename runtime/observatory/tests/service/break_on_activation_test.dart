// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

genRepeater(value) {
  return () => print(value);
}

genRepeaterNamed(value) {
  return ({x, y}) => print(value);
}

var r1;
var r2;
var r3;

var r1_named;
var r2_named;
var r3_named;

void testeeSetup() {
  // These closures have the same function.
  r1 = genRepeater('r1');
  r2 = genRepeater('r2');
  r3 = genRepeater('r3');

  // These closures have the same function.
  r1_named = genRepeaterNamed('r1_named');
  r2_named = genRepeaterNamed('r2_named');
  r3_named = genRepeaterNamed('r3_named');
}

void testeeDo() {
  r1();
  r2();
  r3();
}

void testeeDoNamed() {
  r1_named(y: 'Not a closure', x: 'Not a closure');
  r2_named(y: 'Not a closure', x: 'Not a closure');
  r3_named(y: 'Not a closure', x: 'Not a closure');
}


var tests = [
(Isolate isolate) async {
  var rootLib = await isolate.rootLibrary.load();

  var breaksHit = 0;

  var subscription;
  subscription = isolate.vm.events.stream.listen((ServiceEvent event) {
    if (event.eventType == ServiceEvent.kPauseBreakpoint) {
      print("Hit breakpoint ${event.breakpoint}");
      breaksHit++;
      isolate.resume();
    }
  });

  valueOfField(String name) {
    return rootLib.variables.singleWhere((v) => v.name == name).value;
  }
  var r1Ref = valueOfField('r1');
  var r2Ref = valueOfField('r2');
  var r3Ref = valueOfField('r3');

  var bpt1 = await isolate.addBreakOnActivation(r1Ref);
  print("Added breakpoint $bpt1");
  expect(bpt1 is Breakpoint, isTrue);
  expect(breaksHit, equals(0));
  print("testeeDo()");
  var res = await rootLib.evaluate("testeeDo()");
  expect(res is Instance, isTrue); // Not error.
  expect(breaksHit, equals(1));

  await isolate.removeBreakpoint(bpt1);
  print("Removed breakpoint $bpt1");
  print("testeeDo()");
  res = await rootLib.evaluate("testeeDo()");
  expect(res is Instance, isTrue); // Not error.
  expect(breaksHit, equals(1));

  await subscription.cancel();
},

(Isolate isolate) async {
  var rootLib = await isolate.rootLibrary.load();

  var breaksHit = 0;

  var subscription;
  subscription = isolate.vm.events.stream.listen((ServiceEvent event) {
    if (event.eventType == ServiceEvent.kPauseBreakpoint) {
      print("Hit breakpoint ${event.breakpoint}");
      breaksHit++;
      isolate.resume();
    }
  });

  valueOfField(String name) {
    return rootLib.variables.singleWhere((v) => v.name == name).value;
  }
  var r1Ref = valueOfField('r1_named');
  var r2Ref = valueOfField('r2_named');
  var r3Ref = valueOfField('r3_named');

  var bpt1 = await isolate.addBreakOnActivation(r1Ref);
  print("Added breakpoint $bpt1");
  expect(bpt1 is Breakpoint, isTrue);
  expect(breaksHit, equals(0));
  print("testeeDoNamed()");
  var res = await rootLib.evaluate("testeeDoNamed()");
  expect(res is Instance, isTrue); // Not error.
  expect(breaksHit, equals(1));

  await isolate.removeBreakpoint(bpt1);
  print("Removed breakpoint $bpt1");
  print("testeeDoNamed()");
  res = await rootLib.evaluate("testeeDoNamed()");
  expect(res is Instance, isTrue); // Not error.
  expect(breaksHit, equals(1));

  await subscription.cancel();
},

(Isolate isolate) async {
  var rootLib = await isolate.rootLibrary.load();

  var breaksHit = 0;

  var subscription;
  subscription = isolate.vm.events.stream.listen((ServiceEvent event) {
    if (event.eventType == ServiceEvent.kPauseBreakpoint) {
      print("Hit breakpoint ${event.breakpoint}");
      breaksHit++;
      isolate.resume();
    }
  });

  valueOfField(String name) {
    return rootLib.variables.singleWhere((v) => v.name == name).value;
  }
  var r1Ref = valueOfField('r1');
  var r2Ref = valueOfField('r2');
  var r3Ref = valueOfField('r3');

  var bpt1 = await isolate.addBreakOnActivation(r1Ref);
  print("Added breakpoint $bpt1");
  expect(bpt1 is Breakpoint, isTrue);
  expect(breaksHit, equals(0));
  print("testeeDo()");
  var res = await rootLib.evaluate("testeeDo()");
  expect(res is Instance, isTrue); // Not error.
  expect(breaksHit, equals(1));

  var bpt2 = await isolate.addBreakOnActivation(r2Ref);
  print("Added breakpoint $bpt2");
  expect(bpt2 is Breakpoint, isTrue);
  expect(breaksHit, equals(1));
  print("testeeDo()");
  res = await rootLib.evaluate("testeeDo()");
  expect(res is Instance, isTrue); // Not error.
  expect(breaksHit, equals(3));

  await isolate.removeBreakpoint(bpt1);
  print("Removed breakpoint $bpt1");
  print("testeeDo()");
  res = await rootLib.evaluate("testeeDo()");
  expect(res is Instance, isTrue); // Not error.
  expect(breaksHit, equals(4));

  await isolate.removeBreakpoint(bpt2);
  print("Removed breakpoint $bpt2");
  print("testeeDo()");
  res = await rootLib.evaluate("testeeDo()");
  expect(res is Instance, isTrue); // Not error.
  expect(breaksHit, equals(4));

  await subscription.cancel();
},

];

main(args) => runIsolateTests(args, tests, testeeBefore: testeeSetup);
