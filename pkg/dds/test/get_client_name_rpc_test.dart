// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

void fooBar() {}

final test = <IsolateTest>[
  (VmService service, IsolateRef isolate) async {
    // Each client has a default name based on the order of connection to the
    // service.
    var clientName = await service.getClientName();
    expect(clientName.name, 'client1');

    // Set a custom client name and check it was set properly.
    await service.setClientName('foobar');
    clientName = await service.getClientName();
    expect(clientName.name, 'foobar');

    // Clear the client name and check that we're using the default again.
    await service.setClientName();
    clientName = await service.getClientName();
    expect(clientName.name, 'client1');
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      test,
      'get_client_name_rpc_test.dart',
      testeeConcurrent: fooBar,
      pauseOnStart: true,
    );
