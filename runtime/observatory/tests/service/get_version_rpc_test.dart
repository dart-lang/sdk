// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    final result = await vm.invokeRpcNoUpgrade('getVersion', {});
    expect(result['type'], 'Version');
    expect(result['major'], 3);
    expect(result['minor'], 42);
    expect(result['_privateMajor'], 0);
    expect(result['_privateMinor'], 0);
  },
];

main(args) async => runVMTests(args, tests);
