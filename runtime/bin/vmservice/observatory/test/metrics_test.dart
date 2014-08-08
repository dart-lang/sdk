// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library allocations_test;

import 'test_helper.dart';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'dart:io';

main() {
  String script = 'metrics_script.dart';
  var process = new TestLauncher(script);
  process.launch().then((port) {
    String addr = 'ws://localhost:$port/ws';
    new WebSocketVM(new WebSocketVMTarget(addr)).get('vm')
        .then((VM vm) => vm.isolates.first.load())
        .then((Isolate isolate) =>
          isolate.get('metrics').then((ServiceMap metrics) {
            expect(metrics['type'], equals('MetricList'));
            var members = metrics['members'];
            expect(members, isList);
            expect(members.length, equals(1));
            var counter = members[0];
            expect(counter['name'], equals('a.b.c'));
            expect(counter['value'], equals(1234.5));
            return isolate;
          }))
        .then((Isolate isolate) =>
          isolate.get('metrics/a.b.c').then((ServiceMap counter) {
            expect(counter['name'], equals('a.b.c'));
            expect(counter['value'], equals(1234.5));
            return isolate;
          }))
        .then((Isolate isolate) =>
          isolate.get('metrics/a.b.c.d').then((DartError err) {
            expect(err is DartError, isTrue);
            return isolate;
          }))
        .then((Isolate isolate) => exit(0));
  });
}
