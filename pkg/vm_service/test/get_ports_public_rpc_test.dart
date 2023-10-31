// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' hide Isolate;
import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

late final RawReceivePort port1;
late final RawReceivePort port2;
late final RawReceivePort port3;

void warmup() {
  port1 = RawReceivePort(null, 'port1');
  port2 = RawReceivePort((_) {});
  port3 = RawReceivePort((_) {}, 'port3');
  port3.close();
  RawReceivePort((_) {}, 'port4');
}

int countNameMatches(List<InstanceRef> ports, String name) {
  int matches = 0;
  for (final port in ports) {
    if (port.debugName == name) {
      matches++;
    }
  }
  return matches;
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final result = await service.getPorts(isolateId);
    final ports = result.ports!;
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

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_ports_public_rpc_test.dart',
      testeeBefore: warmup,
    );
