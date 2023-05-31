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
  Uri get parent => File(toFilePath()).parent.uri;
}

const keepTempKey = 'KEEP_TEMPORARY_DIRECTORIES';

Future<void> inTempDir(
  Future<void> Function(Uri tempUri) fun, {
  String? prefix,
  bool keepTemp = false,
}) async {
  final tempDir = await Directory.systemTemp.createTemp(prefix);
  // Deal with Windows temp folder aliases.
  final tempUri =
      Directory(await tempDir.resolveSymbolicLinks()).uri.normalizePath();
  try {
    await fun(tempUri);
  } finally {
    if ((!Platform.environment.containsKey(keepTempKey) ||
            Platform.environment[keepTempKey]!.isEmpty) &&
        !keepTemp) {
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

final pkgNativeAssetsBuilderUri = Platform.script.resolve('../../');
final testProjectsUri =
    pkgNativeAssetsBuilderUri.resolve('test/test_projects/');

Future<void> copyTestProjects({
  Uri? sourceUri,
  required Uri targetUri,
}) async {
  sourceUri ??= testProjectsUri;
  final manifestUri = sourceUri.resolve('manifest.yaml');
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
    final sourceFile = File.fromUri(sourceUri.resolveUri(pathToCopy));
    final targetFileUri = targetUri.resolveUri(pathToCopy);
    final targetDirUri = targetFileUri.parent;
    final targetDir = Directory.fromUri(targetDirUri);
    if (!(await targetDir.exists())) {
      await targetDir.create(recursive: true);
    }

    // Copying files on MacOS and Windows preserves the source timestamps.
    // The builder will use the cached build if the timestamps are equal.
    // So just write the file instead.
    final targetFile = File.fromUri(targetFileUri);
    await targetFile.writeAsBytes(await sourceFile.readAsBytes());
  }
  for (final pathToModify in filesToModify) {
    final sourceFile = File.fromUri(sourceUri.resolveUri(pathToModify));
    final targetFileUri = targetUri.resolveUri(pathToModify);
    final sourceString = await sourceFile.readAsString();
    final modifiedString = sourceString.replaceAll(
      'path: ../../../',
      'path: ${pkgNativeAssetsBuilderUri.toFilePath().replaceAll('\\', '/')}',
    );
    await File.fromUri(targetFileUri)
        .writeAsString(modifiedString, flush: true);
  }
}

/// Logger that outputs the full trace when a test fails.
final logger = Logger('')
  ..level = Level.ALL
  ..onRecord.listen((record) {
    printOnFailure('${record.level.name}: ${record.time}: ${record.message}');
  });

final dartExecutable = File(Platform.resolvedExecutable).uri;
