// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/src/dap/logging.dart';
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

/// A [RegExp] that matches the `path` part of a VM Service URI that contains
/// an authentication token.
final vmServiceAuthCodePathPattern = RegExp(r'^/[\w_\-=]{5,15}/ws$');

/// A [RegExp] that matches the "Connecting to VM Service" banner that is sent
/// as the first output event for a debug session.
final vmServiceUriPattern = RegExp(r'Connecting to VM Service at ([^\s]+)\s');

/// Expects [actual] to equal the lines [expected], ignoring differences in line
/// endings.
void expectLines(String actual, List<String> expected) {
  expect(actual.replaceAll('\r\n', '\n'), equals(expected.join('\n')));
}

/// Returns the 1-base line in [file] that contains [searchText].
int lineWith(File file, String searchText) =>
    file.readAsLinesSync().indexWhere((line) => line.contains(searchText)) + 1;

/// A helper class containing the DAP server/client for DAP integration tests.
class DapTestSession {
  DapTestServer server;
  DapTestClient client;
  final _testFolders = <Directory>[];

  DapTestSession._(this.server, this.client);

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

  static Future<DapTestSession> setUp({List<String>? additionalArgs}) async {
    final server = await _startServer(additionalArgs: additionalArgs);
    final client = await DapTestClient.connect(server);
    return DapTestSession._(server, client);
  }

  Future<void> tearDown() async {
    await client.stop();
    await server.stop();

    // Clean up any temp folders created during the test runs.
    _testFolders
      ..forEach((dir) => dir.deleteSync(recursive: true))
      ..clear();
  }

  /// Starts a DAP server that can be shared across tests.
  static Future<DapTestServer> _startServer({
    Logger? logger,
    List<String>? additionalArgs,
  }) async {
    return useInProcessDap
        ? await InProcessDapTestServer.create(
            logger: logger,
            additionalArgs: additionalArgs,
          )
        : await OutOfProcessDapTestServer.create(
            logger: logger,
            additionalArgs: additionalArgs,
          );
  }
}
