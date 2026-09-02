// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:devtools_shared/devtools_shared.dart' show DtdInfo;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';

const _kDtdAotSnapshotName = 'dart_tooling_daemon_aot.dart.snapshot';
const _kDtdAotProductSnapshotName =
    'dart_tooling_daemon_aot_product.dart.snapshot';
const _kDtdJitSnapshotName = 'dart_tooling_daemon.dart.snapshot';
const _kMachineFlag = '--machine';
const _kDtdDdsStartedEvent = 'server.dtdStarted';

final _logger = Logger('DTD');

List<String> _findDtdSnapshots(
  String snapshotDir, {
  required bool runFromBuildRoot,
}) {
  final isAot = const bool.fromEnvironment('dart.vm.aot');
  final isProduct = const bool.fromEnvironment('dart.vm.product');

  final aotSnapshots = isProduct
      ? [_kDtdAotProductSnapshotName, _kDtdAotSnapshotName]
      : [_kDtdAotSnapshotName, _kDtdAotProductSnapshotName];

  final candidateNames = isAot
      ? [...aotSnapshots, _kDtdJitSnapshotName]
      : [_kDtdJitSnapshotName, ...aotSnapshots];

  final results = <String>[];
  for (final name in candidateNames) {
    final directPath = path.join(snapshotDir, name);
    if (File(directPath).existsSync() && !results.contains(directPath)) {
      results.add(directPath);
    }
    if (runFromBuildRoot) {
      final genPath = path.join(snapshotDir, 'gen', name);
      if (File(genPath).existsSync() && !results.contains(genPath)) {
        results.add(genPath);
      }
    }
  }
  return results;
}

/// Locates the directory containing the Dart Tooling Daemon (DTD) snapshot
/// and whether the SDK is running from the build root.
(String, {bool runFromBuildRoot}) getDTDSnapshotDirInfo() {
  // Find SDK path.
  (String, {bool runFromBuildRoot})? trySDKPath(String executablePath) {
    // The common case: [path.dirname] called twice on Platform.executable.
    // Confirm by asserting that `./bin/snapshots/` exists.
    var sdkPath = path.absolute(path.dirname(path.dirname(executablePath)));
    var snapshotsDir = path.join(sdkPath, 'bin', 'snapshots');
    var runFromBuildRoot = false;
    final type = FileSystemEntity.typeSync(snapshotsDir);
    if (type != FileSystemEntityType.directory &&
        type != FileSystemEntityType.link) {
      // Checked out Dart SDK (e.g., ./out/ReleaseX64/dart ... or in google3).
      sdkPath = path.absolute(path.dirname(executablePath));
      snapshotsDir = sdkPath;
      runFromBuildRoot = true;
    }

    // Try to locate the DTD snapshot to determine if we're able to find
    // the SDK snapshots with this SDK path.
    final snapshots = _findDtdSnapshots(
      snapshotsDir,
      runFromBuildRoot: runFromBuildRoot,
    );
    if (snapshots.isEmpty) {
      return null;
    }
    return (snapshotsDir, runFromBuildRoot: runFromBuildRoot);
  }

  final info =
      trySDKPath(Platform.resolvedExecutable) ??
      trySDKPath(Platform.executable);
  if (info == null) {
    throw StateError(
      'Unable to locate DTD snapshots directory from '
      '${Platform.resolvedExecutable} or ${Platform.executable}',
    );
  }
  return info;
}

/// Returns the directory containing the Dart Tooling Daemon snapshot.
String getDTDSnapshotDir() => getDTDSnapshotDirInfo().$1;

/// Parses the JSON details emitted by DTD when started with `--machine`
/// (see `DartToolingDaemon.startService` in `pkg/dtd_impl/lib/src/dart_tooling_daemon.dart`).
///
/// Returns [DtdInfo] if [message] contains valid tooling daemon details, or
/// `null` otherwise.
DtdInfo? _parseDtdDetails(
  String message, {
  required bool machineMode,
  required bool printDtdUri,
}) {
  try {
    final json = jsonDecode(message) as Map<String, Object?>;
    if (json case {
      'tooling_daemon_details': {
        'uri': final String uri,
        'trusted_client_secret': final String secret,
      },
    }) {
      if (printDtdUri || machineMode) {
        DevToolsUtils.printOutput('Serving the Dart Tooling Daemon at $uri', {
          'event': _kDtdDdsStartedEvent,
          'params': {'uri': uri},
        }, machineMode: machineMode);
      }
      return DtdInfo(Uri.parse(uri), secret: secret);
    }
  } catch (_) {
    // Ignore non-json or malformed output lines.
  }
  return null;
}

/// Starts the Dart Tooling Daemon as a child process using `dartaotruntime`.
///
/// * [machineMode]: Whether the output should be machine-readable (JSON).
/// * [printDtdUri]: Whether to print the DTD serving URI to stdout.
/// * [snapshotPath]: The file path to the DTD AOT snapshot.
Future<DtdInfo?> _startDtdProcess({
  required bool machineMode,
  required bool printDtdUri,
  required String snapshotPath,
}) async {
  final execDir = path.dirname(Platform.resolvedExecutable);
  final execName = Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime';
  final candidateExes = <String>[
    path.join(execDir, execName),
    path.join(path.dirname(execDir), 'bin', execName),
    path.join(path.dirname(execDir), execName),
  ];
  String? dartAotRuntime;
  for (final exe in candidateExes) {
    if (File(exe).existsSync()) {
      dartAotRuntime = exe;
      break;
    }
  }

  if (dartAotRuntime == null) {
    _logger.warning(
      'Could not find dartaotruntime executable to run $snapshotPath',
    );
    return null;
  }

  try {
    final process = await Process.start(dartAotRuntime, [
      snapshotPath,
      _kMachineFlag,
    ], mode: ProcessStartMode.detachedWithStdio);

    final completer = Completer<DtdInfo?>();
    StreamSubscription<String>? stdoutSub;
    StreamSubscription<String>? stderrSub;

    try {
      stdoutSub = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              final dtdInfo = _parseDtdDetails(
                line,
                machineMode: machineMode,
                printDtdUri: printDtdUri,
              );
              if (dtdInfo != null && !completer.isCompleted) {
                completer.complete(dtdInfo);
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.complete(null);
              }
            },
            onError: (_) {
              if (!completer.isCompleted) {
                completer.complete(null);
              }
            },
          );

      stderrSub = process.stderr.transform(utf8.decoder).listen((data) {
        if (data.isNotEmpty) {
          _logger.warning('DTD process stderr: $data');
        }
      });

      final result = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process.kill();
          return null;
        },
      );

      if (result == null) {
        process.kill();
      }
      return result;
    } finally {
      await stdoutSub?.cancel();
      await stderrSub?.cancel();
    }
  } catch (e, st) {
    _logger.warning('Failed to start DTD process from $snapshotPath', e, st);
    return null;
  }
}

/// Starts a Dart Tooling Daemon instance as a separate isolate or process.
Future<DtdInfo?> startDtd({
  required bool machineMode,
  required bool printDtdUri,
}) async {
  final (snapshotDir, :runFromBuildRoot) = getDTDSnapshotDirInfo();
  final snapshotPaths = _findDtdSnapshots(
    snapshotDir,
    runFromBuildRoot: runFromBuildRoot,
  );

  final isAotVm = const bool.fromEnvironment('dart.vm.aot');

  for (final snapshotPath in snapshotPaths) {
    final isAotSnapshot =
        snapshotPath.endsWith(_kDtdAotSnapshotName) ||
        snapshotPath.endsWith(_kDtdAotProductSnapshotName);

    if (isAotSnapshot && !isAotVm) {
      final dtdInfo = await _startDtdProcess(
        snapshotPath: snapshotPath,
        machineMode: machineMode,
        printDtdUri: printDtdUri,
      );
      if (dtdInfo != null) {
        return dtdInfo;
      }
      continue;
    }

    final completer = Completer<DtdInfo?>();

    final exitPort = ReceivePort()
      ..listen((_) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
    final errorPort = ReceivePort()
      ..listen((message) {
        if (message case [final Object error, final Object stackTrace]) {
          _logger.warning('DTD isolate error: $error\n$stackTrace');
        } else {
          _logger.warning('DTD isolate error: $message');
        }
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
    final receivePort = ReceivePort()
      ..listen((message) {
        if (message is String) {
          final dtdInfo = _parseDtdDetails(
            message,
            machineMode: machineMode,
            printDtdUri: printDtdUri,
          );
          if (dtdInfo != null && !completer.isCompleted) {
            completer.complete(dtdInfo);
          }
        }
      });

    Isolate? isolate;
    try {
      isolate = await Isolate.spawnUri(
        Uri.file(snapshotPath),
        [_kMachineFlag],
        receivePort.sendPort,
        onExit: exitPort.sendPort,
        onError: errorPort.sendPort,
      );
      final result = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          isolate?.kill(priority: Isolate.immediate);
          return null;
        },
      );
      if (result != null) {
        return result;
      }
      isolate.kill(priority: Isolate.immediate);
    } catch (e, st) {
      _logger.warning('Failed to spawn DTD isolate from $snapshotPath', e, st);
    } finally {
      receivePort.close();
      errorPort.close();
      exitPort.close();
    }
  }

  return null;
}
