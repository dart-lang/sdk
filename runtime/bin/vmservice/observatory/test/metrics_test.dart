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
  isolate.get('metrics').then((ServiceMap metrics) {
    expect(metrics['type'], equals('MetricList'));
    var members = metrics['members'];
    expect(members, isList);
    expect(members.length, equals(1));
    var counter = members[0];
    expect(counter['name'], equals('a.b.c'));
    expect(counter['value'], equals(1234.5));
}),

(Isolate isolate) =>
  isolate.get('metrics/a.b.c').then((ServiceMap counter) {
    expect(counter['name'], equals('a.b.c'));
    expect(counter['value'], equals(1234.5));
}),

(Isolate isolate) =>
  isolate.get('metrics/a.b.d').then((DartError err) {
    expect(err is DartError, isTrue);
}),

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
