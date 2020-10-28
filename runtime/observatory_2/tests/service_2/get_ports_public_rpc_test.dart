// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' hide Isolate;
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var port1;
var port2;
var port3;

void warmup() {
  port1 = RawReceivePort(null, 'port1');
  port2 = RawReceivePort((_) {});
  port3 = RawReceivePort((_) {}, 'port3');
  port3.close();
  RawReceivePort((_) {}, 'port4');
}

int countNameMatches(ports, name) {
  var matches = 0;
  for (var port in ports) {
    if (port['debugName'] == name) {
      matches++;
    }
  }
  return matches;
}

final tests = <IsolateTest>[
  (Isolate isolate) async {
    dynamic result = await isolate.invokeRpcNoUpgrade('getPorts', {});
    expect(result['type'], 'PortList');
    expect(result['ports'], isList);
    final ports = result['ports'];
    // There are at least three ports: the three created in warm up that
    // weren't closed. Some OSes will have other ports open but we do not try
    // and test for these.
    expect(ports.length, greaterThanOrEqualTo(3));
    expect(countNameMatches(ports, 'port1'), 1);
    expect(countNameMatches(ports, 'port3'), 0);
    expect(countNameMatches(ports, 'port4'), 1);
    expect(countNameMatches(ports, ''), greaterThanOrEqualTo(1));
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
