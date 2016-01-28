// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

doThrow() {
  throw "TheException"; // Line 13.
  return "end of doThrow";
}

var tests = [
  hasStoppedWithUnhandledException,
  (Isolate isolate) async {
    var stack = await isolate.getStack();
    expect(stack['frames'][0].function.name, equals('doThrow'));
  }
];

main(args) => runIsolateTests(args,
                              tests,
                              pause_on_unhandled_exceptions: true,
                              testeeConcurrent: doThrow);
