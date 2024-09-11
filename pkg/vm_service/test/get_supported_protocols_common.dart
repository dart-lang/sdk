// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

VMTest expectedProtocolTest(List<String> expectedProtocols) =>
    (VmService service) async {
      final protocols = (await service.getSupportedProtocols()).protocols!;
      expect(protocols.length, expectedProtocols.length);
      for (final protocol in protocols) {
        expect(expectedProtocols.contains(protocol.protocolName), true);
        expect(protocol.minor, greaterThanOrEqualTo(0));
        expect(protocol.major, greaterThan(0));
      }
    };
