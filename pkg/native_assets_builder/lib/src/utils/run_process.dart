// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

/// Runs a process async and captures the exit code and standard out.
///
/// Supports streaming output using a [Logger].
Future<RunProcessResult> runProcess({
  required String executable,
  required List<String> arguments,
  Uri? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool throwOnFailure = true,
  required Logger logger,
}) async {
  if (Platform.isWindows && !includeParentEnvironment) {
    const winEnvKeys = [
      'SYSTEMROOT',
    ];
    final newEnvironment = {
      ...{
        for (final winEnvKey in winEnvKeys)
          winEnvKey: Platform.environment[winEnvKey]!,
      },
      if (environment != null) ...environment,
    };
    environment = newEnvironment;
  }

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
    includeParentEnvironment: includeParentEnvironment,
    runInShell: Platform.isWindows && !includeParentEnvironment,
  );

  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (s) {
      logger.fine(s);
      stdoutBuffer.add(s);
    },
    onDone: stdoutCompleter.complete,
  );
  process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (s) {
      logger.severe(s);
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
    throw ProcessInvocationException(result);
  }
  return result;
}

class RunProcessResult extends ProcessResult {
  final String command;

  final int _exitCode;

  // For some reason super.exitCode returns 0.
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

class ProcessInvocationException implements Exception {
  final RunProcessResult runProcessResult;

  ProcessInvocationException(this.runProcessResult);

  String get message => '''A process run failed.
$runProcessResult''';

  @override
  String toString() => message;
}
