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

Future<void> copyTestProjects(Uri copyTargetUri, Logger logger) async {
  final pkgNativeAssetsBuilderUri = Platform.script.resolve(
      '../../../../third_party/pkg/native/pkgs/native_assets_builder/');
  // Reuse the test projects from `pkg:native`.
  final testProjectsUri = pkgNativeAssetsBuilderUri.resolve('test/data/');
  final manifestUri = testProjectsUri.resolve('manifest.yaml');
  final manifestFile = File.fromUri(manifestUri);
  final manifestString = await manifestFile.readAsString();
  final manifestYaml = loadYamlDocument(manifestString);
  final manifest = [
    for (final path in manifestYaml.contents as YamlList) Uri(path: path)
  ];
  final filesToCopy =
      manifest.where((e) => e.pathSegments.last != 'pubspec.yaml').toList();
  final filesToModify =
      manifest.where((e) => e.pathSegments.last == 'pubspec.yaml').toList();

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
      'path: ../../../',
      'path: ${pkgNativeAssetsBuilderUri.toFilePath().replaceAll('\\', '/')}',
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
final logger = Logger('')
  ..level = Level.ALL
  ..onRecord.listen((record) {
    printOnFailure('${record.level.name}: ${record.time}: ${record.message}');
  });

final dartExecutable = Uri.file(Platform.resolvedExecutable);

Future<void> nativeAssetsTest(
  String packageUnderTest,
  Future<void> Function(Uri) fun,
) async {
  assert(const [
    'dart_app',
    'native_add',
  ].contains(packageUnderTest));
  return await inTempDir((tempUri) async {
    await copyTestProjects(tempUri, logger);
    final packageUri = tempUri.resolve('$packageUnderTest/');
    await runPubGet(workingDirectory: packageUri, logger: logger);
    return await fun(packageUri);
  });
}

Future<run_process.RunProcessResult> runDart({
  required List<String> arguments,
  Uri? workingDirectory,
  required Logger? logger,
}) async {
  final result = await runProcess(
    executable: dartExecutable,
    arguments: arguments,
    workingDirectory: workingDirectory,
    logger: logger,
  );
  expect(result.exitCode, 0);
  return result;
}
