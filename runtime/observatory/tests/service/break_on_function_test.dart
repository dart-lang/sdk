// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override  --verbose_debug

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:developer';

testFunction(flag) {  // Line 11
  if (flag) {
    print("Yes");
  } else {
    print("No");
  }
}

testMain() {
  debugger();
  testFunction(true);
  testFunction(false);
  print("Done");
}

var tests = [

hasStoppedAtBreakpoint,

// Add breakpoint
(Isolate isolate) async {
  var rootLib = await isolate.rootLibrary.load();
  var function = rootLib.functions.singleWhere((f) => f.name == 'testFunction');

  var bpt = await isolate.addBreakpointAtEntry(function);
  expect(bpt is Breakpoint, isTrue);
  print(bpt);
},

resumeIsolate,

hasStoppedAtBreakpoint,
stoppedAtLine(11),
resumeIsolate,

hasStoppedAtBreakpoint,
stoppedAtLine(11),
resumeIsolate,

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
