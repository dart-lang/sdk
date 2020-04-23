// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ServerTest);
  });
}

@reflectiveTest
class ServerTest extends AbstractLspAnalysisServerIntegrationTest {
  Future<void> test_diagnosticServer() async {
    await initialize();

    // Send the custom request to the LSP server to get the Dart diagnostic
    // server info.
    final server = await getDiagnosticServer();

    expect(server.port, isNotNull);
    expect(server.port, isNonZero);
    expect(server.port, isPositive);

    // Ensure the server was actually started.
    final client = HttpClient();
    var request = await client
        .getUrl(Uri.parse('http://localhost:${server.port}/status'));
    final response = await request.close();
    final responseBody = await utf8.decodeStream(response.cast<List<int>>());
    expect(responseBody, contains('<title>Analysis Server</title>'));
  }

  Future<void> test_exit_inintializedWithShutdown() async {
    await initialize();
    await sendShutdown();
    sendExit();

    await client.channel.closed.timeout(const Duration(seconds: 10),
        onTimeout: () =>
            fail('Server channel did not close within 10 seconds'));

    final exitCode = await client.exitCode.timeout(const Duration(seconds: 10),
        onTimeout: () => fail('Server process did not exit within 10 seconds'));

    expect(exitCode, equals(0));
  }

  Future<void> test_exit_initializedWithoutShutdown() async {
    // Send a request that we can wait for, to ensure the server is fully ready
    // before we send exit. Otherwise the exit notification won't be handled for
    // a long time (while the server starts up) and will exceed the 10s timeout.
    await initialize();
    sendExit();

    await client.channel.closed.timeout(const Duration(seconds: 10),
        onTimeout: () =>
            fail('Server channel did not close within 10 seconds'));

    final exitCode = await client.exitCode.timeout(const Duration(seconds: 10),
        onTimeout: () => fail('Server process did not exit within 10 seconds'));

    expect(exitCode, equals(1));
  }

  Future<void> test_exit_uninintializedWithShutdown() async {
    await sendShutdown();
    sendExit();

    await client.channel.closed.timeout(const Duration(seconds: 10),
        onTimeout: () =>
            fail('Server channel did not close within 10 seconds'));

    final exitCode = await client.exitCode.timeout(const Duration(seconds: 10),
        onTimeout: () => fail('Server process did not exit within 10 seconds'));

    expect(exitCode, equals(0));
  }

  Future<void> test_exit_uninitializedWithoutShutdown() async {
    // This tests the same as test_exit_withoutShutdown but without sending
    // initialize. It can't be as strict with the timeout as the server may take
    // time to start up (we can't tell when it's ready without sending a request).

    sendExit();

    await client.channel.closed;
    final exitCode = await client.exitCode;

    expect(exitCode, equals(1));
  }
}
