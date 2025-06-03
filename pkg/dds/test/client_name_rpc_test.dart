// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

final tests = <VMTest>[
  (VmService service) async {
    // This will be 'client2' instead of 'client1' because the Dart Tooling
    // Daemon that is managed by DDS will connect the first client to this
    // VM Service connection.
    final defaultClientName = 'client2';
    final clientName = 'agent-007';
    var result = await service.getClientName();
    expect(result.name, defaultClientName);

    // Set the name for this client.
    await service.setClientName(clientName);

    // Check it was set properly.
    result = await service.getClientName();
    expect(result.name, clientName);

    // Check clearing works properly.
    await service.setClientName();

    result = await service.getClientName();
    expect(result.name, defaultClientName);
  },
];

void main([args = const <String>[]]) => runVMTests(
      args,
      tests,
      'client_name_rpc_test.dart',
    );
