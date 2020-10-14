// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var result = await isolate.invokeRpcNoUpgrade('_collectAllGarbage', {});
    expect(result['type'], equals('Success'));
  },
];

main(args) async => runIsolateTests(args, tests);
