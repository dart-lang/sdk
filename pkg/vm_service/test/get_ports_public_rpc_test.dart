// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_ports_public_rpc_lib.dart' as testee_lib;

int countNameMatches(List<InstanceRef> ports, String name) {
  int matches = 0;
  for (final port in ports) {
    if (port.debugName == name) {
      matches++;
    }
  }
  return matches;
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_ports_public_rpc_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
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
    }).run(testeeMain: testee_lib.main);
