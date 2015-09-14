// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

var tests = [
  (VM vm) async {
    var result = await vm.invokeRpcNoUpgrade('getVersion', {});
    expect(result['type'], equals('Version'));
    expect(result['major'], equals(3));
    expect(result['minor'], equals(0));
    expect(result['_privateMajor'], equals(0));
    expect(result['_privateMinor'], equals(0));
  },
];

main(args) async => runVMTests(args, tests);
