// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library get_ports_rpc_test;

import 'dart:isolate' hide Isolate;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var port1;
var port2;

void warmup() {
  port1 = new RawReceivePort(null);
  port2 = new RawReceivePort((_) {});
}

int countHandlerMatches(ports, matcher) {
  var matches = 0;
  for (var port in ports) {
    if (matcher(port['handler'])) {
      matches++;
    }
  }
  return matches;
}

bool nullMatcher(handler) {
  return handler.isNull;
}

bool closureMatcher(handler) {
  return handler.isClosure;
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    dynamic result = await isolate.invokeRpc('_getPorts', {});
    expect(result['type'], equals('_Ports'));
    expect(result['ports'], isList);
    var ports = result['ports'];
    // There are at least two ports: the two created in warm up. Some OSes
    // will have other ports open but we do not try and test for these.
    expect(ports.length, greaterThanOrEqualTo(2));
    expect(countHandlerMatches(ports, nullMatcher), greaterThanOrEqualTo(1));
    expect(countHandlerMatches(ports, closureMatcher), greaterThanOrEqualTo(1));
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
