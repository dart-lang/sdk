// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dap/dap.dart';
import 'package:dds/src/dap/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_server.dart';

/// A [RegExp] that matches the "Connecting to VM Service" banner that is sent
/// by the DAP adapter as the first output event for a debug session.
final dapVmServiceBannerPattern = RegExp(
    r'Connecting to VM Service at ([^\s]+)\s|Connected to the VM Service');

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

/// A [RegExp] that matches the "The Dart VM service is listening on" banner that is sent
/// by the VM when not using --write-service-info.
final vmServiceBannerPattern =
    RegExp(r'The Dart VM service is listening on ([^\s]+)\s');

/// The root of the SDK containing the current running VM.
final sdkRoot = path.dirname(path.dirname(Platform.resolvedExecutable));

/// Expects the lines in [actual] to match the relevant matcher in [expected],
/// ignoring differences in line endings and trailing whitespace.
void expectLines(String actual, List<Object> expected) {
  expect(
    actual.replaceAll('\r\n', '\n').trim().split('\n'),
    equals(expected),
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
      const TypeMatcher<RequestException>().having(
        (r) => r.message,
        'message',
        TypeMatcher<Response>()
            .having((r) => r.success, 'success', isFalse)
            .having((r) => r.message, 'message', messageMatcher),
      ),
    ),
  );
}

/// Returns the 1-base line in [file] that contains [searchText].
int lineWith(File file, String searchText) =>
    file.readAsLinesSync().indexWhere((line) => line.contains(searchText)) + 1;

/// Starts a process paused (and with pause-on-exit).
Future<Process> startDartProcessPaused(
  String script,
  List<String> args, {
  required String cwd,
  List<String>? vmArgs,
  required bool pauseOnExit,
}) async {
  final vmPath = Platform.resolvedExecutable;
  vmArgs ??= [];
  vmArgs.addAll([
    '--enable-vm-service=0',
    '--pause_isolates_on_start',
    // Use pause-on-exit so we don't lose async output events in attach tests.
    if (pauseOnExit) '--pause_isolates_on_exit',
  ]);
  final processArgs = [
    ...vmArgs,
    script,
    ...args,
  ];

  return Process.start(
    vmPath,
    processArgs,
    workingDirectory: cwd,
  );
}

/// Monitors [process] for the VM Service banner and extracts the URI.
Future<Uri> waitForStdoutVmServiceBanner(Process process) {
  final vmServiceUriCompleter = Completer<Uri>();

  late StreamSubscription<String> vmServiceBannerSub;
  vmServiceBannerSub = process.stdout.transform(utf8.decoder).listen(
    (line) {
      final match = vmServiceBannerPattern.firstMatch(line);
      if (match != null) {
        vmServiceUriCompleter.complete(Uri.parse(match.group(1)!));
        vmServiceBannerSub.cancel();
      }
    },
    onDone: () {
      if (!vmServiceUriCompleter.isCompleted) {
        vmServiceUriCompleter.completeError('Stream ended');
      }
    },
  );

  return vmServiceUriCompleter.future;
}

/// A helper class containing the DAP server/client for DAP integration tests.
class DapTestSession {
  DapTestServer server;
  DapTestClient client;
  final Directory testDir =
      Directory.systemTemp.createTempSync('dart-sdk-dap-test');
  late final Directory testAppDir;
  late final Directory testPackagesDir;

  DapTestSession._(this.server, this.client) {
    testAppDir = testDir.createTempSync('app');
    createPubspec(testAppDir, 'my_test_project');
    testPackagesDir = testDir.createTempSync('packages');
  }

  /// Adds package with [name] (optionally at [packageFolderUri]) to the
  /// project in [dir].
  ///
  /// If [packageFolderUri] is not supplied, will use [Isolate.resolvePackageUri]
  /// assuming the package is available to the tests.
  Future<void> addPackageDependency(
    Directory dir,
    String name, [
    Uri? packageFolderUri,
  ]) async {
    final proc = await Process.run(
      Platform.resolvedExecutable,
      [
        'pub',
        'add',
        name,
        if (packageFolderUri != null) ...[
          '--path',
          packageFolderUri.toFilePath(),
        ],
      ],
      workingDirectory: dir.path,
    );
    expect(
      proc.exitCode,
      isZero,
      reason: '${proc.stdout}\n${proc.stderr}'.trim(),
    );
  }

  /// Create a simple package named `foo` that has an empty `foo` function and
  /// a top-level variable `fooGlobal`.
  Future<(Uri, File)> createFooPackage([String? filename]) {
    return createSimplePackage(
      'foo',
      '''
var fooGlobal = 'Hello, foo!';

foo() {
  // Does nothing.
}
      ''',
      filename,
    );
  }

  /// Sets up packages for macro support.
  Future<void> enableMacroSupport() async {
    // Compute a path to the local package that we can use.
    final dapIntegrationTestFolder = path.dirname(Platform.script.toFilePath());
    assert(path.split(dapIntegrationTestFolder).last == 'integration');

    final sdkRoot =
        path.normalize(path.join(dapIntegrationTestFolder, '../../../../..'));
    final macrosPath = path.join(sdkRoot, 'pkg', 'macros');
    await addPackageDependency(testAppDir, 'macros', Uri.file(macrosPath));

    createTestFile(
      filename: 'analysis_options.yaml',
      '''
analyzer:
  enable-experiment:
    - macros
''',
    );
  }

  void createPubspec(Directory dir, String projectName) {
    final pubspecFile = File(path.join(dir.path, 'pubspec.yaml'));
    pubspecFile
      ..createSync()
      ..writeAsStringSync('''
name: $projectName
version: 1.0.0

environment:
  sdk: '>=3.3.0 <4.0.0'
''');
  }

  /// Creates a simple package script and adds the package to
  /// .dart_tool/package_config.json
  Future<(Uri, File)> createSimplePackage(
    String name,
    String content, [
    String? filename,
  ]) async {
    filename ??= '$name.dart';
    final packageDir = Directory(path.join(testPackagesDir.path, name))
      ..createSync(recursive: true);
    final packageLibDir = Directory(path.join(packageDir.path, 'lib'))
      ..createSync(recursive: true);

    // Create a pubspec and a implementation file in the lib folder.
    createPubspec(packageDir, name);
    final testFile = File(path.join(packageLibDir.path, filename));
    testFile.writeAsStringSync(content);

    // Add this new package as a dependency for the app.
    final fileUri = Uri.file('${packageDir.path}/');
    await addPackageDependency(testAppDir, name, fileUri);

    return (Uri.parse('package:$name/$filename'), testFile);
  }

  /// Creates a file in a temporary folder to be used as an application for testing.
  ///
  /// The file will be deleted at the end of the test run.
  File createTestFile(String content, {String filename = 'test_file.dart'}) {
    final testFile = File(path.join(testAppDir.path, path.normalize(filename)));
    Directory(path.dirname(testFile.path)).createSync(recursive: true);
    testFile.writeAsStringSync(content);
    return testFile;
  }

  Future<void> tearDown() async {
    // If the test hasn't already sent terminate, do that before shutting down.
    if (!client.hasSentTerminateRequest) {
      await client.terminate();
    }
    await client.stop();
    await server.stop();

    // Clean up any temp folders created during the test runs.
    await tryDelete(testDir);
  }

  /// Tries to delete [dir] multiple times before printing a warning and giving up.
  ///
  /// This avoids "The process cannot access the file because it is being
  /// used by another process" errors on Windows trying to delete folders that
  /// have only very recently been unlocked.
  Future<void> tryDelete(Directory dir) async {
    const maxAttempts = 10;
    const delay = Duration(milliseconds: 100);
    var attempt = 0;
    while (++attempt <= maxAttempts) {
      try {
        testDir.deleteSync(recursive: true);
        break;
      } catch (e) {
        if (attempt == maxAttempts) {
          print('Failed to delete $testDir after $maxAttempts attempts.\n$e');
          break;
        }
        await Future.delayed(delay);
      }
    }
  }

  static Future<DapTestSession> setUp({
    List<String>? additionalArgs,
  }) async {
    final server = await startServer(additionalArgs: additionalArgs);
    final client = await DapTestClient.connect(
      server,
      captureVmServiceTraffic: verboseLogging,
      logger: verboseLogging ? print : null,
    );
    return DapTestSession._(server, client);
  }

  /// Starts a DAP server that can be shared across tests.
  static Future<DapTestServer> startServer({
    Logger? logger,
    Function? onError,
    List<String>? additionalArgs,
  }) async {
    return useInProcessDap
        ? await InProcessDapTestServer.create(
            logger: logger,
            onError: onError,
            additionalArgs: additionalArgs,
          )
        : await OutOfProcessDapTestServer.create(
            logger: logger,
            onError: onError,
            additionalArgs: additionalArgs,
          );
  }
}

/// A helper to run [testFunc] as a test in various configurations of URI
/// support.
///
/// This should be used to ensure coverage of each configuration where
/// breakpoints and stack traces are being tested.
@isTest
void testWithUriConfigurations(
  DapTestSession Function() dapFunc,
  String name,
  FutureOr<void> Function() testFunc,
) {
  for (final (supportUris, sendFileUris) in [
    (false, false),
    (true, false),
    (true, true),
  ]) {
    test('$name (supportUris: $supportUris, sendFileUris: $sendFileUris)', () {
      final client = dapFunc().client;
      client.supportUris = supportUris;
      client.sendFileUris = sendFileUris;
      return testFunc();
    });
  }
}
