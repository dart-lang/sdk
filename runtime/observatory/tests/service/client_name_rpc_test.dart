// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    final defaultClientName = 'client1';
    final clientName = 'agent-007';
    var result = await vm.invokeRpcNoUpgrade('getClientName', {});
    expect(result['type'], 'ClientName');
    expect(result['name'], defaultClientName);

    // Set the name for this client.
    result = await vm.invokeRpcNoUpgrade(
      'setClientName',
      {
        'name': clientName,
      },
    );
    expect(result['type'], 'Success');

    // Check it was set properly.
    result = await vm.invokeRpcNoUpgrade('getClientName', {});
    expect(result['type'], 'ClientName');
    expect(result['name'], clientName);

    // Check clearing works properly.
    result = await vm.invokeRpcNoUpgrade(
      'setClientName',
      {
        'name': '',
      },
    );
    expect(result['type'], 'Success');

    result = await vm.invokeRpcNoUpgrade('getClientName', {});
    expect(result['type'], 'ClientName');
    expect(result['name'], defaultClientName);
  },
  // Try to set an invalid agent name for this client.
  (VM vm) async {
    try {
      await vm.invokeRpcNoUpgrade(
        'setClientName',
        {
          'name': 42,
        },
      );
      fail('Successfully set invalid client name');
    } on ServerRpcException catch (e) {/* expected */}
  },
  // Missing parameters.
  (VM vm) async {
    try {
      await vm.invokeRpcNoUpgrade('setClientName', {});
      fail('Successfully set name with no type');
    } on ServerRpcException catch (e) {/* expected */}
  },
];

main(args) async => runVMTests(
      args,
      tests,
      enableService: false,
    );
