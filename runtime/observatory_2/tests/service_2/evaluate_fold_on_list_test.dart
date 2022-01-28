// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/models.dart' show InstanceKind;
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

void testFunction() {
  List<String> x = ["a", "b", "c"];
  int xCombinedLength = x.fold<int>(
      0, (previousValue, element) => previousValue + element.length);
  debugger();
  print("xCombinedLength = $xCombinedLength");
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    Instance result = await isolate.evalFrame(0, '''x.fold<int>(
              0, (previousValue, element) => previousValue + element.length)''')
        as Instance;
    expect(result.valueAsString, equals('3'));
    expect(result.kind, equals(InstanceKind.int));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
