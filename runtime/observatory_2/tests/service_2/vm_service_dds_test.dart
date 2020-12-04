// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/dds.dart';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

final tests = <DDSTest>[
  (VM vm, DartDevelopmentService dds) async {
    final client = WebSocketVM(
      WebSocketVMTarget(
        dds.wsUri.toString(),
      ),
    );
    final result = await client.invokeRpcNoUpgrade('getSupportedProtocols', {});
    final protocols = result['protocols'];
    expect(protocols.length, 2);
    bool supportsVmProtocol = false;
    bool supportsDdsProtocol = false;
    for (final protocol in protocols) {
      if (protocol['protocolName'] == 'VM Service') {
        supportsVmProtocol = true;
      } else if (protocol['protocolName'] == 'DDS') {
        supportsDdsProtocol = true;
      }
    }
    expect(supportsVmProtocol, true);
    expect(supportsDdsProtocol, true);
  }
];

main(args) async => runDDSTests(args, tests);
