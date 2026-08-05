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
    var server = await getDiagnosticServer();

    expect(server.port, isNotNull);
    expect(server.port, isNonZero);
    expect(server.port, isPositive);

    // Ensure the server was actually started.
    var client = HttpClient();
    var request = await client.getUrl(
      Uri.parse('http://localhost:${server.port}/status'),
    );
    var response = await request.close();
    var responseBody = await utf8.decodeStream(response.cast<List<int>>());
    expect(responseBody, contains('<title>Analysis Server</title>'));
  }

  /// A normal shutdown and exit should not result in the server flushing
  /// diagnostics (which usually happens as part of destroying analysis
  /// contexts) because this can result in clients like `dart analyze` seeing
  /// all diagnostics disappear. The client should be responsible for removing
  /// diagnostics if the server they are related to shuts down.
  Future<void> test_exit_doesNotFlushDiagnostics() async {
    failTestOnErrorDiagnostic = false;
    failTestOnAnyErrorNotification = false;

    newFile(mainFilePath, 'invalid');

    var diagnosticsFuture = publishedDiagnostics
        .where((params) => params.uri == mainFileUri)
        .toList();

    await initialize();
    await workspaceAnalysisComplete();
    await sendShutdown();
    sendExit();

    // Wait for all notifications and the stream to complete.
    var diagnostics = await diagnosticsFuture;

    // Expect only one notification, with diagnostics.
    expect(diagnostics, hasLength(1));
    expect(diagnostics.single.diagnostics, isNotEmpty);
  }

  Future<void> test_exit_initializedWithoutShutdown() async {
    // Send a request that we can wait for, to ensure the server is fully ready
    // before we send exit. Otherwise the exit notification won't be handled for
    // a long time (while the server starts up) and will exceed the 10s timeout.
    await initialize();
    sendExit();

    await channel.closed.timeout(
      const Duration(seconds: 10),
      onTimeout: () => fail('Server channel did not close within 10 seconds'),
    );

    var exitCode = await client!.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () => fail('Server process did not exit within 10 seconds'),
    );

    expect(exitCode, equals(1));
  }

  Future<void> test_exit_initializedWithShutdown() async {
    await initialize();
    await sendShutdown();
    sendExit();

    await channel.closed.timeout(
      const Duration(seconds: 10),
      onTimeout: () => fail('Server channel did not close within 10 seconds'),
    );

    var exitCode = await client!.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () => fail('Server process did not exit within 10 seconds'),
    );

    expect(exitCode, equals(0));
  }

  Future<void> test_exit_uninitializedWithoutShutdown() async {
    // This tests the same as test_exit_withoutShutdown but without sending
    // initialize. It can't be as strict with the timeout as the server may take
    // time to start up (we can't tell when it's ready without sending a request).

    sendExit();

    await channel.closed;
    var exitCode = await client!.exitCode;

    expect(exitCode, equals(1));
  }

  Future<void> test_exit_uninitializedWithShutdown() async {
    await sendShutdown();
    sendExit();

    await channel.closed.timeout(
      const Duration(seconds: 10),
      onTimeout: () => fail('Server channel did not close within 10 seconds'),
    );

    var exitCode = await client!.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () => fail('Server process did not exit within 10 seconds'),
    );

    expect(exitCode, equals(0));
  }
}
