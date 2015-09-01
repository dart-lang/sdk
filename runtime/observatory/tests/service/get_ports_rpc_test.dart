// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

library get_ports_rpc_test;

import 'dart:isolate' hide Isolate;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

var port1;
var port2;

void warmup() {
  port1 = new RawReceivePort(null);
  port2 = new RawReceivePort((_) {
  });
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

var tests = [
  (Isolate isolate) async {
    var result = await isolate.invokeRpc('_getPorts', {});
    expect(result['type'], equals('_Ports'));
    expect(result['ports'], isList);
    var ports = result['ports'];
    // There are three ports: the two created in warmup and the stdin listener
    // created by the test harness.
    expect(ports.length, equals(3));
    expect(countHandlerMatches(ports, nullMatcher), equals(1));
    expect(countHandlerMatches(ports, closureMatcher), equals(2));
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore:warmup);
