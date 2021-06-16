// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_server.dart';

/// Whether to run the DAP server in-process with the tests, or externally in
/// another process.
///
/// By default tests will run the DAP server out-of-process to match the real
/// use from editors, but this complicates debugging the adapter. Set this env
/// variables to run the server in-process for easier debugging (this can be
/// simplified in VS Code by using a launch config with custom CodeLens links).
final useInProcessDap = Platform.environment['DAP_TEST_INTERNAL'] == 'true';

/// Expects [actual] to equal the lines [expected], ignoring differences in line
/// endings.
void expectLines(String actual, List<String> expected) {
  expect(actual.replaceAll('\r\n', '\n'), equals(expected.join('\n')));
}

/// A helper function to wrap all tests in a library with setup/teardown functions
/// to start a shared server for all tests in the library and an individual
/// client for each test.
testDap(FutureOr<void> Function(DapTestSession session) tests) {
  final session = DapTestSession();

  setUpAll(session.setUpAll);
  tearDownAll(session.tearDownAll);
  setUp(session.setUp);
  tearDown(session.tearDown);

  return tests(session);
}

/// A helper class provided to DAP integration tests run with [testDap] to
/// easily share setup/teardown without sharing state across tests from different
/// files.
class DapTestSession {
  late DapTestServer server;
  late DapTestClient client;
  final _testFolders = <Directory>[];

  /// Creates a file in a temporary folder to be used as an application for testing.
  ///
  /// The file will be deleted at the end of the test run.
  File createTestFile(String content) {
    final testAppDir = Directory.systemTemp.createTempSync('dart-sdk-dap-test');
    _testFolders.add(testAppDir);
    final testFile = File(path.join(testAppDir.path, 'test_file.dart'));
    testFile.writeAsStringSync(content);
    return testFile;
  }

  FutureOr<void> setUp() async {
    client = await _startClient(server);
  }

  FutureOr<void> setUpAll() async {
    server = await _startServer();
  }

  FutureOr<void> tearDown() => client.stop();

  FutureOr<void> tearDownAll() async {
    await server.stop();

    // Clean up any temp folders created during the test runs.
    _testFolders.forEach((dir) => dir.deleteSync(recursive: true));
  }

  /// Creates and connects a new [DapTestClient] to [server].
  FutureOr<DapTestClient> _startClient(DapTestServer server) async {
    // Since we don't get a signal from the DAP server when it's ready and we
    // just started it, add a short retry to connections.
    var attempt = 1;
    while (attempt++ <= 20) {
      try {
        return await DapTestClient.connect(server.port);
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    throw 'Failed to connect to DAP server on port ${server.port}'
        ' after $attempt attempts. Did the server start correctly?';
  }

  /// Starts a DAP server that can be shared across tests.
  FutureOr<DapTestServer> _startServer() async {
    return useInProcessDap
        ? await InProcessDapTestServer.create()
        : await OutOfProcessDapTestServer.create();
  }
}
