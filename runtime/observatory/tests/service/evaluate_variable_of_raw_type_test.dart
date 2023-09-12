// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory/models.dart' show InstanceKind;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

void testFunction() {
  List<dynamic> v = <dynamic>[1, 2, '3'];
  debugger();
  print("v = $v");
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    final result = await isolate.evalFrame(0, '''v.length''');
    print(result);
    final instance = result as Instance;
    expect(instance.valueAsString, equals('3'));
    expect(instance.kind, equals(InstanceKind.int));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
