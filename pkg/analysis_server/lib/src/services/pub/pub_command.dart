// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/utilities/process.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:path/path.dart' as path;

/// A class for interacting with the `pub` command.
///
/// `pub` commands will be queued and not run concurrently.
class PubCommand {
  static const String _pubEnvironmentKey = 'PUB_ENVIRONMENT';

  /// An environment variable that can be set to prevent a [PubCommand] from
  /// being created/used by the analysis server.
  ///
  /// This is generally intended for integration tests to prevent them spawning
  /// pub commands while testing other functionality.
  static const String disablePubCommandEnvironmentKey =
      'DART_SERVER_DISABLE_PUB_COMMAND';

  final InstrumentationService _instrumentationService;
  late final ProcessRunner _processRunner;
  late final String _pubEnvironmentValue;

  /// Active processes that should be killed when shutting down.
  final _activeProcesses = <Process>{};

  /// Tracks the last queued command to avoid overlapping because pub does not
  /// do its own locking when accessing the cache.
  ///
  /// https://github.com/dart-lang/pub/issues/1178
  ///
  /// This does not prevent running concurrently with commands spawned by other
  /// tools (such as the IDE).
  var _lastQueuedCommand = Future<void>.value();

  PubCommand(this._instrumentationService, this._processRunner) {
    // When calling the `pub` command, we must add an identifier to the
    // PUB_ENVIRONMENT environment variable (joined with colons).
    const pubEnvString = 'analysis_server.pub_api';
    final existingPubEnv = Platform.environment[_pubEnvironmentKey];
    _pubEnvironmentValue = [
      if (existingPubEnv?.isNotEmpty ?? false) existingPubEnv,
      pubEnvString,
    ].join(':');
  }

  /// Runs `pub outdated --show-all` and returns the results.
  ///
  /// If any error occurs executing the command, returns an empty list.
  Future<List<PubOutdatedPackageDetails>> outdatedVersions(
      String pubspecPath) async {
    final packageDirectory = path.dirname(pubspecPath);
    final result = await _runPubJsonCommand(
        ['outdated', '--show-all', '--json'],
        workingDirectory: packageDirectory);

    if (result == null) {
      return [];
    }

    final packages =
        (result['packages'] as List<dynamic>?)?.cast<Map<String, Object?>>();
    if (packages == null) {
      return [];
    }

    return packages
        .map(
          (json) => PubOutdatedPackageDetails(
            json['package'] as String,
            currentVersion: _version(json, 'current'),
            latestVersion: _version(json, 'latest'),
            resolvableVersion: _version(json, 'resolvable'),
            upgradableVersion: _version(json, 'upgradable'),
          ),
        )
        .toList();
  }

  /// Terminates any in-process commands with [ProcessSignal.sigterm].
  void shutdown() {
    for (var process in _activeProcesses) {
      _instrumentationService.logInfo('Terminating process ${process.pid}');
      process.kill();
    }
  }

  /// Runs a pub command and decodes JSON from `stdout`.
  ///
  /// Returns null if:
  ///   - exit code is non-zero
  ///   - returned text cannot be decoded as JSON
  Future<Map<String, Object?>?> _runPubJsonCommand(List<String> args,
      {required String workingDirectory}) async {
    // Atomically replace the lastQueuedCommand future with our own to ensure
    // only one command waits on any previous commands future.
    final completer = Completer<void>();
    final lastCommand = _lastQueuedCommand;
    _lastQueuedCommand = completer.future;
    // And wait for that previous command to finish.
    await lastCommand.catchError((_) {});

    try {
      _instrumentationService.logInfo('Starting pub command $args');
      final process = await _processRunner.start(
          Platform.resolvedExecutable, ['pub', ...args],
          workingDirectory: workingDirectory,
          environment: {_pubEnvironmentKey: _pubEnvironmentValue});
      _activeProcesses.add(process);

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      _activeProcesses.remove(process);

      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;

      if (exitCode != 0) {
        _instrumentationService
            .logError('pub command returned $exitCode exit code: $stderr.');
        return null;
      }

      try {
        final results = jsonDecode(stdout);
        _instrumentationService.logInfo('pub command completed successfully');
        return results as Map<String, Object?>?;
      } catch (e) {
        _instrumentationService
            .logError('pub command returned invalid JSON: $e.');
        return null;
      }
    } catch (e) {
      _instrumentationService.logError('pub command failed to run: $e.');
      return null;
    } finally {
      completer.complete();
    }
  }

  String? _version(Map<String, Object?> json, String type) {
    final versionType = json[type] as Map<String, Object?>?;
    final version =
        versionType != null ? versionType['version'] as String? : null;
    return version;
  }
}

class PubOutdatedPackageDetails {
  final String packageName;
  final String? currentVersion;
  final String? latestVersion;
  final String? resolvableVersion;
  final String? upgradableVersion;

  PubOutdatedPackageDetails(
    this.packageName, {
    required this.currentVersion,
    required this.latestVersion,
    required this.resolvableVersion,
    required this.upgradableVersion,
  });
}
