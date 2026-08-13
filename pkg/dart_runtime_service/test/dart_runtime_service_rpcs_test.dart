// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/src/dart_runtime_service_options.dart';
import 'package:dart_runtime_service/src/dart_runtime_service_rpcs.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import 'utils/utilities.dart';

void main() {
  group('$DartRuntimeServiceRpcs:', () {
    test('getClientName + setClientName', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client = await vmServiceConnectUri(service.uri.toString());
      var response = await client.getClientName();
      final defaultName = response.name;

      await client.setClientName('foobar');
      response = await client.getClientName();
      expect(response.name, 'foobar');

      await client.setClientName();
      response = await client.getClientName();
      expect(response.name, defaultName);
    });
  });
}
