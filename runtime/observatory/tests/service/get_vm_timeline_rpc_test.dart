// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override --complete_timeline

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

primeTimeline() {
  Timeline.startSync('apple');
  Timeline.finishSync();
}

List<Map> filterForDartEvents(List<Map> events) {
  return events.where((event) => event['cat'] == 'Dart').toList();
}

var tests = [
  (VM vm) async {
    Map result = await vm.invokeRpcNoUpgrade('_getVMTimeline', {});
    expect(result['type'], equals('_Timeline'));
    expect(result['traceEvents'], new isInstanceOf<List>());
    List<Map> dartEvents = filterForDartEvents(result['traceEvents']);
    expect(dartEvents.length, equals(1));
    Map dartEvent = dartEvents[0];
    expect(dartEvent['name'], equals('apple'));
  },
];

main(args) async => runVMTests(args, tests, testeeBefore: primeTimeline);
