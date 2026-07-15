// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';

import 'asset_server_client.dart';

void main() {
  group('AssetServerClient (Hybrid)', () {
    test('initializes and reports properties', () async {
      final client = await AssetServerClient.spawnHybrid();
      try {
        expect(client.baseUrl.scheme, 'http');
        expect(client.hasFlutter, anyOf(isTrue, isFalse));
        expect(client.isClosed, isFalse);
      } finally {
        await client.close();
      }
    });

    test('can add a package from files via RPC', () async {
      final client = await AssetServerClient.spawnHybrid();

      try {
        await client.addPackage({
          'pubspec.yaml': 'name: custom_rpc_pkg\nversion: 2.5.0',
          'lib/custom.dart': 'void doSomething() {}',
        });

        // Verify the server actually received and served it
        final response = await http.get(
          client.baseUrl.resolve('api/packages/custom_rpc_pkg'),
        );

        expect(response.statusCode, 200);
        final body = jsonDecode(response.body) as Map<String, Object?>;
        expect(body['name'], 'custom_rpc_pkg');

        final latest = body['latest'] as Map<String, Object?>;
        expect(latest['version'], '2.5.0');
      } finally {
        await client.close();
      }
    });

    test('addPackage throws RpcException on invalid input', () async {
      final client = await AssetServerClient.spawnHybrid();

      try {
        await client.addPackage({
          //'pubspec.yaml': 'name: custom_rpc_pkg\nversion: 2.5.0',
          'lib/custom.dart': 'void doSomething() {}',
        });
        fail('Expected an RpcException');
      } on RpcException {
        // pass
      } finally {
        await client.close();
      }
    });
  });
}
