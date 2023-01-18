// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check the VM correctly undoes the layers of mixin application to report the
// evaluation scope the frontend as the original mixin.

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

class S {}

class M {
  static String? foo;
  bar() {
    foo = "theExpectedValue";
    debugger();
  }
}

// MA2 -> S&M -> S -> Object
class MA extends S with M {}

testeeMain() {
  new MA().bar();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    var frame = (await isolate.getStack())['frames'][0];
    print(frame);
    expect(frame.function.name, equals("bar"));
    dynamic result = await isolate.evalFrame(0, "foo");
    print(result);
    expect(result.valueAsString, equals("theExpectedValue"));
  },
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testeeMain);
