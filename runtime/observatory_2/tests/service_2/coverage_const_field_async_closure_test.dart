// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_A = 15; // LINE_A - 4
const int LINE_B = 23; // LINE_A - 3

class Bar {
  static const String field = "field"; // LINE_A
}

Future<String> fooAsync(int x) async {
  if (x == 42) {
    return '*' * x;
  }
  return List.generate(x, (_) => 'xyzzy').join(' ');
} // LINE_B

void testFunction() async {
  await new Future.delayed(Duration(milliseconds: 500));
  fooAsync(42).then((_) {});
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    var stack = await isolate.getStack();

    // Make sure we are in the right place.
    expect(stack.type, 'Stack');
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    // Async closure of testFunction
    expect(stack['frames'][0].function.name, 'async_op');

    var root = isolate.rootLibrary;
    await root.load();
    Script script = root.scripts.first;
    await script.load();

    var params = {
      'reports': ['Coverage'],
      'scriptId': script.id,
      'forceCompile': true
    };
    var report = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    List<dynamic> ranges = report['ranges'];

    int match = 0;
    for (var range in ranges) {
      for (int i in range["coverage"]["hits"]) {
        int line = script.tokenToLine(i);
        if (line == null) {
          throw FormatException('token ${i} was missing source location');
        }
        // Check LINE.
        if (line == LINE_A || line == LINE_A - 3 || line == LINE_A - 4) {
          match = match + 1;
        }
        // _clearAsyncThreadStackTrace should have an invalid token position.
        expect(line, isNot(LINE_B));
      }
    }
    // Neither LINE nor Bar.field should be added into coverage.
    expect(match, 0);
  },
  resumeIsolate
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
