// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    var result = await vm.invokeRpcNoUpgrade('getVMTimelineMicros', {});
    expect(result['type'], equals('Timestamp'));
    expect(result['timestamp'], isPositive);
  },
];

main(args) async => runVMTests(args, tests);
