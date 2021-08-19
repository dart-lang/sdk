// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/src/dap/logging.dart';
import 'package:dds/src/dap/protocol_generated.dart';
import 'package:package_config/package_config.dart';
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

/// Whether to print all protocol traffic to stdout while running tests.
///
/// This is useful for debugging locally or on the bots and will include both
/// DAP traffic (between the test DAP client and the DAP server) and the VM
/// Service traffic (wrapped in a custom 'dart.log' event).
final verboseLogging = Platform.environment['DAP_TEST_VERBOSE'] == 'true';

/// A [RegExp] that matches the `path` part of a VM Service URI that contains
/// an authentication token.
final vmServiceAuthCodePathPattern = RegExp(r'^/[\w_\-=]{5,15}/ws$');

/// A [RegExp] that matches the "Connecting to VM Service" banner that is sent
/// as the first output event for a debug session.
final vmServiceUriPattern = RegExp(r'Connecting to VM Service at ([^\s]+)\s');

/// Expects [actual] to equal the lines [expected], ignoring differences in line
/// endings and trailing whitespace.
void expectLines(String actual, List<String> expected) {
  expect(
    actual.replaceAll('\r\n', '\n').trim(),
    equals(expected.join('\n').trim()),
  );
}

/// Expects [actual] starts with [expected], ignoring differences in line
/// endings and trailing whitespace.
void expectLinesStartWith(String actual, List<String> expected) {
  expect(
    actual.replaceAll('\r\n', '\n').trim(),
    startsWith(expected.join('\n').trim()),
  );
}

/// Expects [response] to fail with a `message` matching [messageMatcher].
expectResponseError<T>(Future<T> response, Matcher messageMatcher) {
  expect(
    response,
    throwsA(
      const TypeMatcher<Response>()
          .having((r) => r.success, 'success', isFalse)
          .having((r) => r.message, 'message', messageMatcher),
    ),
  );
}

/// Returns the 1-base line in [file] that contains [searchText].
int lineWith(File file, String searchText) =>
    file.readAsLinesSync().indexWhere((line) => line.contains(searchText)) + 1;

/// A helper class containing the DAP server/client for DAP integration tests.
class DapTestSession {
  DapTestServer server;
  DapTestClient client;
  final Directory _testDir =
      Directory.systemTemp.createTempSync('dart-sdk-dap-test');
  late final Directory testAppDir;
  late final Directory testPackageDir;
  var _packageConfig = PackageConfig.empty;

  DapTestSession._(this.server, this.client) {
    testAppDir = _testDir.createTempSync('app');
    testPackageDir = _testDir.createTempSync('packages');
  }

  /// Create a simple package named `foo` that has an empty `foo` function.
  Future<Uri> createFooPackage() {
    return createSimplePackage(
      'foo',
      '''
foo() {
  // Does nothing.
}
      ''',
    );
  }

  /// Creates a simple package script and adds the package to
  /// .dart_tool/package_config.json
  Future<Uri> createSimplePackage(
    String name,
    String content,
  ) async {
    final dartToolDirectory =
        Directory(path.join(testAppDir.path, '.dart_tool'))..createSync();
    final packageConfigJsonFile =
        File(path.join(dartToolDirectory.path, 'package_config.json'));
    final packageConfigJsonUri = Uri.file(packageConfigJsonFile.path);

    // Write the packages Dart implementation file.
    final testPackageDirectory = Directory(path.join(testPackageDir.path, name))
      ..createSync(recursive: true);
    final testFile = File(path.join(testPackageDirectory.path, '$name.dart'));
    testFile.writeAsStringSync(content);

    // Add this new package to the PackageConfig.
    final newPackage = Package(name, Uri.file('${testPackageDirectory.path}/'));
    _packageConfig = PackageConfig([..._packageConfig.packages, newPackage]);

    // Write the PackageConfig to disk.
    final sink = packageConfigJsonFile.openWrite();
    PackageConfig.writeString(_packageConfig, sink, packageConfigJsonUri);
    await sink.close();

    return Uri.parse('package:$name/$name.dart');
  }

  /// Creates a file in a temporary folder to be used as an application for testing.
  ///
  /// The file will be deleted at the end of the test run.
  File createTestFile(String content) {
    final testFile = File(path.join(testAppDir.path, 'test_file.dart'));
    testFile.writeAsStringSync(content);
    return testFile;
  }

  Future<void> tearDown() async {
    await client.stop();
    await server.stop();

    // Clean up any temp folders created during the test runs.
    _testDir.deleteSync(recursive: true);
  }

  static Future<DapTestSession> setUp({List<String>? additionalArgs}) async {
    final server = await _startServer(additionalArgs: additionalArgs);
    final client = await DapTestClient.connect(
      server,
      captureVmServiceTraffic: verboseLogging,
      logger: verboseLogging ? print : null,
    );
    return DapTestSession._(server, client);
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
