// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' hide Isolate;
import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import '../common/test_helper.dart';

late final RawReceivePort port1;
late final RawReceivePort port2;

void warmup() {
  port1 = RawReceivePort(null);
  port2 = RawReceivePort((_) {});
}

int countHandlerMatches(
  List<Map<String, dynamic>> ports,
  bool Function(InstanceRef) matcher,
) {
  int matches = 0;
  for (final port in ports) {
    if (matcher(InstanceRef.parse(port['handler'])!)) {
      matches++;
    }
  }
  return matches;
}

bool nullMatcher(InstanceRef handler) {
  return handler.kind == InstanceKind.kNull;
}

bool closureMatcher(InstanceRef handler) {
  return handler.kind == InstanceKind.kClosure;
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final result =
        (await service.callMethod('_getPorts', isolateId: isolateId)).json!;
    expect(result['type'], equals('_Ports'));
    expect(result['ports'], isList);
    final ports = result['ports'].cast<Map<String, dynamic>>();
    // There are at least two ports: the two created in warm up. Some OSes
    // will have other ports open but we do not try and test for these.
    expect(ports.length, greaterThanOrEqualTo(2));
    expect(countHandlerMatches(ports, nullMatcher), greaterThanOrEqualTo(1));
    expect(countHandlerMatches(ports, closureMatcher), greaterThanOrEqualTo(1));
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_ports_rpc_test.dart',
      testeeBefore: warmup,
    );
