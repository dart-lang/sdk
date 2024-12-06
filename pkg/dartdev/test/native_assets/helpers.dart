// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:native_assets_builder/src/utils/run_process.dart'
    as run_process;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

extension UriExtension on Uri {
  Uri get parent {
    return File(toFilePath()).parent.uri;
  }
}

const keepTempKey = 'KEEP_TEMPORARY_DIRECTORIES';

Future<void> inTempDir(Future<void> Function(Uri tempUri) fun) async {
  final tempDir = await Directory.systemTemp.createTemp();
  // Deal with Windows temp folder aliases.
  final tempUri =
      Directory(await tempDir.resolveSymbolicLinks()).uri.normalizePath();
  try {
    await fun(tempUri);
  } finally {
    if (!Platform.environment.containsKey(keepTempKey) ||
        Platform.environment[keepTempKey]!.isEmpty) {
      await tempDir.delete(recursive: true);
    }
  }
}

/// Runs a [Process].
///
/// If [logger] is provided, stream stdout and stderr to it.
///
/// If [captureOutput], captures stdout and stderr.
Future<run_process.RunProcessResult> runProcess({
  required Uri executable,
  List<String> arguments = const [],
  Uri? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  required Logger? logger,
  bool captureOutput = true,
  int expectedExitCode = 0,
  bool throwOnUnexpectedExitCode = false,
}) =>
    run_process.runProcess(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      logger: logger,
      captureOutput: captureOutput,
      expectedExitCode: expectedExitCode,
      throwOnUnexpectedExitCode: throwOnUnexpectedExitCode,
    );

Future<void> copyTestProjects(
    Uri copyTargetUri, Logger logger, Uri packageLocation) async {
  // Reuse the test projects from `pkg:native`.
  final testProjectsUri = packageLocation.resolve('test_data/');
  final manifestUri = testProjectsUri.resolve('manifest.yaml');
  final manifestFile = File.fromUri(manifestUri);
  final manifestString = await manifestFile.readAsString();
  final manifestYaml = loadYamlDocument(manifestString);
  final manifest = [
    for (final path in manifestYaml.contents as YamlList) Uri(path: path)
  ];
  final filesToCopy = manifest
      .where((e) => !(e.pathSegments.last.startsWith('pubspec') &&
          e.pathSegments.last.endsWith('.yaml')))
      .toList();
  final filesToModify = manifest
      .where((e) =>
          e.pathSegments.last.startsWith('pubspec') &&
          e.pathSegments.last.endsWith('.yaml'))
      .toList();

  for (final pathToCopy in filesToCopy) {
    final sourceFile = File.fromUri(testProjectsUri.resolveUri(pathToCopy));
    final targetUri = copyTargetUri.resolveUri(pathToCopy);
    final targetDirUri = targetUri.parent;
    final targetDir = Directory.fromUri(targetDirUri);
    if (!(await targetDir.exists())) {
      await targetDir.create(recursive: true);
    }
    await sourceFile.copy(targetUri.toFilePath());
  }
  for (final pathToModify in filesToModify) {
    final sourceFile = File.fromUri(testProjectsUri.resolveUri(pathToModify));
    final targetUri = copyTargetUri.resolveUri(pathToModify);
    final sourceString = await sourceFile.readAsString();
    final modifiedString = sourceString.replaceAll(
      'path: ../../',
      'path: ${packageLocation.toFilePath().replaceAll('\\', '/')}',
    );
    await File.fromUri(targetUri).writeAsString(modifiedString);
  }

  // If we're copying `my_native_library/` we need to simulate that its
  // native assets are pre-built
  final myNativeLibraryUri = copyTargetUri.resolve('my_native_library/');
  if (await Directory(myNativeLibraryUri.toFilePath()).exists()) {
    await runPubGet(
      workingDirectory: myNativeLibraryUri,
      logger: logger,
    );
    await runDart(
      arguments: ['tool/native.dart', 'build'],
      workingDirectory: myNativeLibraryUri,
      logger: logger,
    );
  }
}

Future<void> runPubGet({
  required Uri workingDirectory,
  required Logger logger,
}) async {
  final result = await runDart(
    arguments: ['pub', 'get'],
    workingDirectory: workingDirectory,
    logger: logger,
  );
  expect(result.exitCode, 0);
}

void expectDartAppStdout(String stdout) {
  expect(
    stdout,
    stringContainsInOrder(
      [
        'add(5, 6) = 11',
        'subtract(5, 6) = -1',
      ],
    ),
  );
}

/// Logger that outputs the full trace when a test fails.
Logger get logger => _logger ??= () {
      // A new logger is lazily created for each test so that the messages
      // captured by printOnFailure are scoped to the correct test.
      addTearDown(() => _logger = null);
      return _createTestLogger();
    }();

Logger? _logger;

Logger createCapturingLogger(List<String> capturedMessages) =>
    _createTestLogger(capturedMessages: capturedMessages);

Logger _createTestLogger({List<String>? capturedMessages}) =>
    Logger.detached('')
      ..level = Level.ALL
      ..onRecord.listen((record) {
        printOnFailure(
            '${record.level.name}: ${record.time}: ${record.message}');
        capturedMessages?.add(record.message);
      });

final dartExecutable = Uri.file(Platform.resolvedExecutable);

Future<void> nativeAssetsTest(
  String packageUnderTest,
  Future<void> Function(Uri) fun, {
  bool skipPubGet = false,
}) async =>
    await runPackageTest(
      packageUnderTest,
      skipPubGet,
      fun,
      const [
        'add_asset_link',
        'dart_app',
        'drop_dylib_link',
        'native_add_duplicate',
        'native_add',
        'native_dynamic_linking',
        'treeshaking_native_libs',
      ],
      Platform.script.resolve(
          '../../../../third_party/pkg/native/pkgs/native_assets_builder/'),
    );

Future<void> recordUseTest(
  String packageUnderTest,
  Future<void> Function(Uri) fun, {
  bool skipPubGet = false,
}) async =>
    await runPackageTest(
      packageUnderTest,
      skipPubGet,
      fun,
      const ['drop_dylib_recording'],
      Platform.script.resolve('../../../record_use/'),
    );

Future<void> runPackageTest(
  String packageUnderTest,
  bool skipPubGet,
  Future<void> Function(Uri) fun,
  List<String> validPackages,
  Uri packageLocation,
) async {
  assert(validPackages.contains(packageUnderTest));
  return await inTempDir((tempUri) async {
    await copyTestProjects(tempUri, logger, packageLocation);
    final packageUri = tempUri.resolve('$packageUnderTest/');
    if (!skipPubGet) {
      await runPubGet(workingDirectory: packageUri, logger: logger);
    }
    return await fun(packageUri);
  });
}

Future<run_process.RunProcessResult> runDart({
  required List<String> arguments,
  Uri? workingDirectory,
  required Logger? logger,
  bool expectExitCodeZero = true,
}) async {
  final result = await runProcess(
    executable: dartExecutable,
    arguments: arguments,
    workingDirectory: workingDirectory,
    logger: logger,
  );
  if (expectExitCodeZero) {
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      print(result.exitCode);
    }
    expect(result.exitCode, 0);
  }
  return result;
}
