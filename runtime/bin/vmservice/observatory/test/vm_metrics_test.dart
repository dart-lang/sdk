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
  isolate.get('metrics/vm').then((ServiceMap metrics) {
    expect(metrics['type'], equals('MetricList'));
    var members = metrics['members'];
    expect(members, isList);
    expect(members.length, greaterThan(1));
    var foundOldHeapCapacity = members.any((m) =>
        m.name == 'heap.old.capacity');
    expect(foundOldHeapCapacity, equals(true));
}),

(Isolate isolate) =>
  isolate.get('metrics/vm/heap.old.used').then((ServiceMap counter) {
    expect(counter.serviceType, equals('Counter'));
    expect(counter.name, equals('heap.old.used'));
}),

(Isolate isolate) =>
  isolate.get('metrics/vm/doesnotexist').then((DartError err) {
    expect(err is DartError, isTrue);
}),

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
