// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
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

/// Runs a process async and captures the exit code and standard out.
Future<RunProcessResult> runProcess({
  required String executable,
  required List<String> arguments,
  Uri? workingDirectory,
  Map<String, String>? environment,
  bool throwOnFailure = true,
  required Logger logger,
}) async {
  final printWorkingDir =
      workingDirectory != null && workingDirectory != Directory.current.uri;
  final commandString = [
    if (printWorkingDir) '(cd ${workingDirectory.toFilePath()};',
    ...?environment?.entries.map((entry) => '${entry.key}=${entry.value}'),
    executable,
    ...arguments.map((a) => a.contains(' ') ? "'$a'" : a),
    if (printWorkingDir) ')',
  ].join(' ');

  logger.info('Running `$commandString`.');

  final stdoutBuffer = <String>[];
  final stderrBuffer = <String>[];
  final stdoutCompleter = Completer<Object?>();
  final stderrCompleter = Completer<Object?>();
  final Process process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory?.toFilePath(),
    environment: environment,
  );

  process.stdout.transform(utf8.decoder).listen(
    (s) {
      logger.fine('  $s');
      stdoutBuffer.add(s);
    },
    onDone: stdoutCompleter.complete,
  );
  process.stderr.transform(utf8.decoder).listen(
    (s) {
      logger.shout('  $s');
      stderrBuffer.add(s);
    },
    onDone: stderrCompleter.complete,
  );

  final int exitCode = await process.exitCode;
  await stdoutCompleter.future;
  final String stdout = stdoutBuffer.join();
  await stderrCompleter.future;
  final String stderr = stderrBuffer.join();
  final result = RunProcessResult(
    pid: process.pid,
    command: '$executable ${arguments.join(' ')}',
    exitCode: exitCode,
    stdout: stdout,
    stderr: stderr,
  );
  if (throwOnFailure && result.exitCode != 0) {
    throw result;
  }
  return result;
}

class RunProcessResult extends ProcessResult {
  final String command;

  final int _exitCode;

  @override
  int get exitCode => _exitCode;

  final String _stderrString;

  @override
  String get stderr => _stderrString;

  final String _stdoutString;

  @override
  String get stdout => _stdoutString;

  RunProcessResult({
    required int pid,
    required this.command,
    required int exitCode,
    required String stderr,
    required String stdout,
  })  : _exitCode = exitCode,
        _stderrString = stderr,
        _stdoutString = stdout,
        super(pid, exitCode, stdout, stderr);

  @override
  String toString() => '''command: $command
exitCode: $exitCode
stdout: $stdout
stderr: $stderr''';
}

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
