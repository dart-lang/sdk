// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_common.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';
import 'service_test_common.dart';

testMain() async {
  print('1');
  while (true) {}
}

var tests = <IsolateTest>[
  // Stopped at 'debugger' statement.
  isolateIsRunning,
  // Kill the app
  (Isolate isolate) async {
    Map<String, dynamic> params = <String, dynamic>{};
    ServiceObject result = await isolate.invokeRpc('kill', params);
    expect(result.type, equals('Success'));
  }
];

main(args) async => runIsolateTests(args, tests, testeeConcurrent: testMain);
