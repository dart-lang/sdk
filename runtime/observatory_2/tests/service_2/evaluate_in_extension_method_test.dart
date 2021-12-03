// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/models.dart' show InstanceKind;
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

extension Foo on String {
  int parseInt(int x) {
    debugger();
    return foo();
  }

  int foo() => 42;
}

void testFunction() {
  print("10".parseInt(21));
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    Instance result;
    result = await isolate.evalFrame(0, 'x') as Instance;
    expect(result.valueAsString, equals('21'));
    expect(result.kind, equals(InstanceKind.int));

    result = await isolate.evalFrame(0, 'this') as Instance;
    expect(result.valueAsString, equals('10'));
    expect(result.kind, equals(InstanceKind.string));

    result = await isolate.evalFrame(0, 'foo()') as Instance;
    expect(result.valueAsString, equals('42'));
    expect(result.kind, equals(InstanceKind.int));

    result = await isolate.evalFrame(0, 'foo() + x') as Instance;
    expect(result.valueAsString, equals('63'));
    expect(result.kind, equals(InstanceKind.int));

    result =
        await isolate.evalFrame(0, 'foo() + x + int.parse(this)') as Instance;
    expect(result.valueAsString, equals('73'));
    expect(result.kind, equals(InstanceKind.int));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
