// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Environment for subprocesses: never let depot_tools update itself from an
/// unattended run.
const _environment = {'DEPOT_TOOLS_UPDATE': '0'};

/// Thrown when a subprocess exits with a non-zero exit code.
final class ProcessFailure implements Exception {
  final List<String> command;
  final ProcessResult result;

  ProcessFailure(this.command, this.result);

  @override
  String toString() => [
        '`${command.join(' ')}` failed with exit code ${result.exitCode}.',
        if ('${result.stdout}'.trim().isNotEmpty) '${result.stdout}'.trim(),
        if ('${result.stderr}'.trim().isNotEmpty) '${result.stderr}'.trim(),
      ].join('\n');
}

/// Starts [executable] and returns the running [Process].
Future<Process> startProcess(String executable, List<String> arguments) =>
    Process.start(executable, arguments, environment: _environment);

/// Runs [executable] and returns its result, regardless of the exit code.
Future<ProcessResult> runProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) =>
    Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: _environment,
    );

/// Runs [executable] and returns its stdout, throwing a [ProcessFailure] if
/// it exits with a non-zero exit code.
Future<String> runChecked(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final result = await runProcess(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    throw ProcessFailure([executable, ...arguments], result);
  }
  return result.stdout as String;
}

/// Whether the user has LOAS credentials (from `gcert`) that are valid for at
/// least [minRemaining].
///
/// The tool proxy, the `gchat` and `mpa` CLIs and `git cl` (via `sso://`)
/// all need them.
Future<bool> hasLoasCredentials({
  Duration minRemaining = const Duration(minutes: 5),
}) async {
  final result = await runProcess('gcertstatus', [
    '--check_remaining=${minRemaining.inMinutes}m',
    '--check_ssh=false',
    '--quiet',
  ]);
  return result.exitCode == 0;
}
