// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// An abstraction over [Process] from 'dart:io' to allow mocking in tests.
class ProcessRunner {
  final Map<String, String>? environment;

  const ProcessRunner({this.environment});

  ProcessResult runSync(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? stderrEncoding,
    Encoding? stdoutEncoding,
  }) {
    return Process.runSync(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: _mergedEnv(environment),
      stderrEncoding: stderrEncoding,
      stdoutEncoding: stdoutEncoding,
    );
  }

  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    return Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: _mergedEnv(environment),
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
  }

  Map<String, String>? _mergedEnv(Map<String, String>? environment) {
    var merged = <String, String>{...?this.environment, ...?environment};
    return merged.isNotEmpty ? merged : null;
  }
}
