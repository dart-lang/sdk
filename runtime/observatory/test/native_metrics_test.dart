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
    isolate.refreshNativeMetrics().then((Map metrics) {
      expect(metrics.length, greaterThan(1));
      expect(metrics.length, greaterThan(1));
      var foundOldHeapCapacity = metrics.values.any((m) =>
          m.name == 'heap.old.capacity');
      expect(foundOldHeapCapacity, equals(true));
  }),

(Isolate isolate) =>
  isolate.invokeRpc('getIsolateMetric',
                    { 'metricId': 'metrics/native/heap.old.used' })
      .then((ServiceMetric counter) {
    expect(counter.type, equals('Counter'));
    expect(counter.name, equals('heap.old.used'));
  }),

(Isolate isolate) =>
    isolate.invokeRpc('getIsolateMetric',
                      { 'metricId': 'metrics/native/doesnotexist' })
          .then((DartError err) {
    expect(err is DartError, isTrue);
  }),

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
