// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

import 'dart:developer';

void script() {
  var counter = new Counter('a.b.c', 'description');
  Metrics.register(counter);
  counter.value = 1234.5;
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Map metrics = await isolate.refreshDartMetrics();
    expect(metrics.length, equals(1));
    var counter = metrics['metrics/a.b.c'];
    expect(counter.name, equals('a.b.c'));
    expect(counter.value, equals(1234.5));
  },
  (Isolate isolate) async {
    var params = {'metricId': 'metrics/a.b.c'};
    ServiceMetric counter =
        await isolate.invokeRpc('_getIsolateMetric', params) as ServiceMetric;
    expect(counter.name, equals('a.b.c'));
    expect(counter.value, equals(1234.5));
  },
  (Isolate isolate) async {
    bool caughtException = false;
    try {
      await isolate
          .invokeRpc('_getIsolateMetric', {'metricId': 'metrics/a.b.d'});
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message,
          "_getIsolateMetric: invalid 'metricId' parameter: metrics/a.b.d");
    }
    expect(caughtException, isTrue);
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
