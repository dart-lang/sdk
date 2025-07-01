// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:test/test.dart';

void main() {
  group('dart mcp-server', () {
    for (var withExperiment in const [true, false]) {
      test(
          'can be connected with a client with${withExperiment ? '' : 'out'} the experiment flag',
          () async {
        final client = TestMCPClient();
        addTearDown(client.shutdown);
        final serverConnection =
            await client.connectStdioServer(Platform.resolvedExecutable, [
          'mcp-server',
          if (withExperiment) '--experimental-mcp-server',
        ]);
        final initializeResult = await serverConnection.initialize(
            InitializeRequest(
                protocolVersion: ProtocolVersion.latestSupported,
                capabilities: client.capabilities,
                clientInfo: client.implementation));

        expect(
            initializeResult.protocolVersion, ProtocolVersion.latestSupported);
        serverConnection.notifyInitialized();

        expect(
          await serverConnection.listTools(ListToolsRequest()),
          isNotEmpty,
        );
      });
    }
  });
}

base class TestMCPClient extends MCPClient {
  TestMCPClient()
      : super(Implementation(name: 'test client', version: '0.1.0'));
}
