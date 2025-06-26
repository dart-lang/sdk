// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:test/test.dart';

void main() {
  group('dart mcp-server', () {
    test('can be connected with a client', () async {
      final client = TestMCPClient();
      addTearDown(client.shutdown);
      final serverConnection = await client.connectStdioServer(
          Platform.resolvedExecutable,
          ['mcp-server', '--experimental-mcp-server']);
      final initializeResult = await serverConnection.initialize(
          InitializeRequest(
              protocolVersion: ProtocolVersion.latestSupported,
              capabilities: client.capabilities,
              clientInfo: client.implementation));

      expect(initializeResult.protocolVersion, ProtocolVersion.latestSupported);
      serverConnection.notifyInitialized();

      expect(
        await serverConnection.listTools(ListToolsRequest()),
        isNotEmpty,
      );
    });

    test('requires the --experimental-mcp-server flag', () async {
      final processResult =
          await Process.run(Platform.resolvedExecutable, ['mcp-server']);
      expect(processResult.exitCode, isNot(0));
      expect(processResult.stderr,
          contains('Missing required flag --experimental-mcp-server'));
    });
  });
}

base class TestMCPClient extends MCPClient {
  TestMCPClient()
      : super(Implementation(name: 'test client', version: '0.1.0'));
}
