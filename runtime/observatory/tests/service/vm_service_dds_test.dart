// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/dds.dart';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

final tests = <DDSTest>[
  (VM vm, DartDevelopmentService dds) async {
    final client = WebSocketVM(
      WebSocketVMTarget(
        dds.remoteVmServiceWsUri.toString(),
      ),
    );
    expect(client.wasOrIsConnected, false);
    try {
      await client.load();
      fail(
          'When DDS is connected, direct connections to the VM service should fail.');
    } on NetworkRpcException catch (e) {
      expect(e.message, 'WebSocket closed due to error');
    }
    expect(client.wasOrIsConnected, false);
  }
];

main(args) async => runDDSTests(args, tests);
