// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

/// [expectMissingProtocol] allows for a single protocol to be missing. See
/// https://github.com/dart-lang/sdk/issues/54835 for context. This test will
/// fail without this flag on AOT configurations when DDS is expected since DDS
/// isn't currently setup to run with dart_precompiled_runtime. This flag is
/// meant to cause this test to fail if
/// https://github.com/dart-lang/sdk/issues/54841 is resolved so this test can
/// be updated.
VMTest expectedProtocolTest(
  List<String> expectedProtocols, {
  bool expectMissingProtocol = false,
}) =>
    (VmService service) async {
      final protocols = (await service.getSupportedProtocols()).protocols!;
      final expectedLength =
          expectedProtocols.length - (expectMissingProtocol ? 1 : 0);
      expect(protocols.length, expectedLength);
      for (final protocol in protocols) {
        expect(expectedProtocols.contains(protocol.protocolName), true);
        expect(protocol.minor, greaterThanOrEqualTo(0));
        expect(protocol.major, greaterThan(0));
      }
    };
