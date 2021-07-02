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

/// A logger to use to log all traffic (both DAP and VM) to stdout.
///
/// If the enviroment variable is `DAP_TEST_VERBOSE` then `print` will be used,
/// otherwise there will be no verbose logging.
///
///   DAP_TEST_VERBOSE=true pub run test --chain-stack-traces test/dap/integration
///
///
/// When using the out-of-process DAP, this causes `--verbose` to be passed to
/// the server which causes it to write all traffic to `stdout` which is then
/// picked up by [OutOfProcessDapTestServer] and passed to this logger.
final logger =
    Platform.environment['DAP_TEST_VERBOSE'] == 'true' ? print : null;

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

/// Returns the 1-base line in [file] that contains [searchText].
int lineWith(File file, String searchText) =>
    file.readAsLinesSync().indexWhere((line) => line.contains(searchText)) + 1;

/// A helper function to wrap all tests in a library with setup/teardown functions
/// to start a shared server for all tests in the library and an individual
/// client for each test.
testDap(
  Future<void> Function(DapTestSession session) tests, {
  List<String>? additionalArgs,
}) {
  final session = DapTestSession(additionalArgs: additionalArgs);

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
  final List<String>? additionalArgs;

  DapTestSession({this.additionalArgs});

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

  Future<void> setUp() async {
    client = await _startClient(server);
  }

  Future<void> setUpAll() async {
    server = await _startServer(logger: logger, additionalArgs: additionalArgs);
  }

  Future<void> tearDown() => client.stop();

  Future<void> tearDownAll() async {
    await server.stop();

    // Clean up any temp folders created during the test runs.
    _testFolders.forEach((dir) => dir.deleteSync(recursive: true));
  }

  /// Creates and connects a new [DapTestClient] to [server].
  Future<DapTestClient> _startClient(DapTestServer server) async {
    // Since we don't get a signal from the DAP server when it's ready and we
    // just started it, add a short retry to connections.
    // Since the bots can be quite slow, it may take 6-7 seconds for the server
    // to initially start up (including compilation).
    var attempt = 1;
    while (attempt++ <= 100) {
      try {
        return await DapTestClient.connect(server.host, server.port);
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    final errorMessage = StringBuffer();
    errorMessage.writeln(
      'Failed to connect to DAP server on port ${server.port}'
      ' after $attempt attempts. Did the server start correctly?',
    );

    final serverErrorLogs = server.errorLogs;
    if (serverErrorLogs.isNotEmpty) {
      errorMessage.writeln('Server errors:');
      errorMessage.writeAll(serverErrorLogs);
    }

    throw Exception(errorMessage.toString());
  }

  /// Starts a DAP server that can be shared across tests.
  Future<DapTestServer> _startServer({
    Logger? logger,
    List<String>? additionalArgs,
  }) async {
    return useInProcessDap
        ? await InProcessDapTestServer.create(logger: logger)
        : await OutOfProcessDapTestServer.create(
            logger: logger,
            additionalArgs: additionalArgs,
          );
  }
}
