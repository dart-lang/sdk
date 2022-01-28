// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/models.dart' show InstanceKind;
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

extension on String {
  String printAndReturnHello() {
    String response = "Hello from String '$this'";
    print(response);
    return response;
  }
}

void testFunction() {
  String x = "hello";
  String value = x.printAndReturnHello();
  debugger();
  print("value = $value");
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    Instance result =
        await isolate.evalFrame(0, 'x.printAndReturnHello()') as Instance;
    expect(result.valueAsString, equals("Hello from String 'hello'"));
    expect(result.kind, equals(InstanceKind.string));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
