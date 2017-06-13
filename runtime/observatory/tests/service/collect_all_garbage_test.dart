// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

var tests = [
  (Isolate isolate) async {
    var result = await isolate.invokeRpcNoUpgrade('_collectAllGarbage', {});
    expect(result['type'], equals('Success'));
  },
];

main(args) async => runIsolateTests(args, tests);
