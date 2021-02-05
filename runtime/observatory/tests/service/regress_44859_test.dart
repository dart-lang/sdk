// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

void script() {}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Map metrics = await isolate.refreshDartMetrics();
    expect(metrics.length, 0);
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
