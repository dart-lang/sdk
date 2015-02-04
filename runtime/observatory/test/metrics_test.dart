// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

import 'dart:profiler';

void script() {
  var counter = new Counter('a.b.c', 'description');
  Metrics.register(counter);
  counter.value = 1234.5;
}

var tests = [

(Isolate isolate) =>
  isolate.refreshDartMetrics().then((Map metrics) {
    expect(metrics.length, equals(1));
    var counter = metrics['metrics/a.b.c'];
    expect(counter.name, equals('a.b.c'));
    expect(counter.value, equals(1234.5));
}),

(Isolate isolate) =>
  isolate.invokeRpc('getIsolateMetric', { 'metricId': 'metrics/a.b.c' })
      .then((ServiceMetric counter) {
    expect(counter.name, equals('a.b.c'));
    expect(counter.value, equals(1234.5));
  }),

(Isolate isolate) =>
  isolate.invokeRpc('getIsolateMetric', { 'metricId': 'metrics/a.b.d' })
      .then((DartError err) {
    expect(err is DartError, isTrue);
  }),
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
