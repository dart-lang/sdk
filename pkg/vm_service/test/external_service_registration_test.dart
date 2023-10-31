// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

const serviceName = 'serviceName';
const serviceAlias = 'serviceAlias';

final tests = <IsolateTest>[
  (VmService primaryClient, IsolateRef isolateRef) async {
    // Register two unique services.
    await primaryClient.registerService(serviceName, serviceAlias);
    await primaryClient.registerService(serviceName + '2', serviceAlias + '2');

    try {
      // Try to register with an existing service name.
      await primaryClient.registerService(serviceName, serviceAlias);
      fail('Successfully registered service with duplicate name');
    } on RPCError catch (e) {
      expect(e.code, RPCErrorKind.kServiceAlreadyRegistered.code);
      expect(e.message, 'Service already registered');
    }
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'external_service_registration_test.dart',
    );
