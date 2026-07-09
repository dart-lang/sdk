// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/service_test_common.dart';
import 'get_ports_rpc_lib.dart' as testee_lib;

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

void main([args = const <String>[]]) => IsolateTestHarness(
      'get_ports_rpc_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final result =
          (await service.callMethod('_getPorts', isolateId: isolateId)).json!;
      expect(result['type'], equals('_Ports'));
      expect(result['ports'], isList);
      final ports = result['ports'].cast<Map<String, dynamic>>();
      // There are at least two ports: the two created in warm up. Some OSes
      // will have other ports open but we do not try and test for these.
      expect(ports.length, greaterThanOrEqualTo(2));
      expect(
        countHandlerMatches(ports, nullMatcher),
        greaterThanOrEqualTo(1),
      );
      expect(
        countHandlerMatches(ports, closureMatcher),
        greaterThanOrEqualTo(1),
      );
    }).run(testeeMain: testee_lib.main);
