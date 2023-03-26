// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    final result = await vm.invokeRpcNoUpgrade('getVersion', {});
    expect(result['type'], equals('Version'));
    expect(result['major'], equals(4));
    expect(result['minor'], equals(4));
    expect(result['_privateMajor'], equals(0));
    expect(result['_privateMinor'], equals(0));
  },
];

main(args) async => runVMTests(args, tests);
