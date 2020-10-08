// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

final tests = <VMTest>[
  (VM vm) async {
    final result = await vm.invokeRpcNoUpgrade('getSupportedProtocols', {});
    expect(result['type'], equals('ProtocolList'));
    final List<Map> protocols =
        result['protocols'].cast<Map<String, dynamic>>();
    expect(protocols.length, useDds ? 2 : 1);

    final expectedProtocols = <String>{
      'VM Service',
      if (useDds) 'DDS',
    };

    for (final protocol in protocols) {
      final protocolName = protocol['protocolName'];
      expect(expectedProtocols.contains(protocolName), isTrue);
      expect(protocol['major'] > 0, isTrue);
      expect(protocol['minor'] >= 0, isTrue);
    }
  },
];

main(args) async => runVMTests(args, tests);
