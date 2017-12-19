// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override --vm-name=Walter

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    var result = await vm.invokeRpcNoUpgrade('getVM', {});
    expect(result['type'], equals('VM'));
    expect(result['name'], equals('Walter'));
    expect(result['architectureBits'], isPositive);
    expect(result['targetCPU'], new isInstanceOf<String>());
    expect(result['hostCPU'], new isInstanceOf<String>());
    expect(result['version'], new isInstanceOf<String>());
    expect(result['pid'], new isInstanceOf<int>());
    expect(result['startTime'], isPositive);
    expect(result['isolates'].length, isPositive);
    expect(result['isolates'][0]['type'], equals('@Isolate'));
  },
];

main(args) async => runVMTests(args, tests);
