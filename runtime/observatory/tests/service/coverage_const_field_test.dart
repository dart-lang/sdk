// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE = 14;

class Bar {
  static const String field = "field"; // LINE
}

void testFunction() {
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    var stack = await isolate.getStack();

    // Make sure we are in the right place.
    expect(stack.type, 'Stack');
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    expect(stack['frames'][0].function.name, 'testFunction');

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
        if (line == LINE) {
          match = (match | 1);
        } else if (line == LINE - 3) {
          // static const field LINE is defined at LINE - 3.
          match = (match | 2);
        }
      }
    }
    // Neither LINE nor Bar.field should be added into coverage.
    expect(match, 0);
  },
  resumeIsolate
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
