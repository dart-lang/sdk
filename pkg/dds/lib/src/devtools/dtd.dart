// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:devtools_shared/devtools_shared.dart' show DtdInfo;
import 'package:path/path.dart' as path;

import 'utils.dart';

String getDTDSnapshotDir() {
  // This logic is originally from pkg/dartdev/lib/src/sdk.dart
  //
  // Find SDK path.
  (String, bool)? trySDKPath(String executablePath) {
    // The common case, and how cli_util.dart computes the Dart SDK directory,
    // [path.dirname] called twice on Platform.executable. We confirm by
    // asserting that the directory `./bin/snapshots/` exists in this directory:
    var sdkPath = path.absolute(path.dirname(path.dirname(executablePath)));
    var snapshotsDir = path.join(sdkPath, 'bin', 'snapshots');
    var runFromBuildRoot = false;
    final type = FileSystemEntity.typeSync(snapshotsDir);
    if (type != FileSystemEntityType.directory &&
        type != FileSystemEntityType.link) {
      // This is the less common case where the user is in
      // the checked out Dart SDK, and is executing `dart` via:
      // ./out/ReleaseX64/dart ... or in google3.
      sdkPath = path.absolute(path.dirname(executablePath));
      snapshotsDir = sdkPath;
      runFromBuildRoot = true;
    }

    // Try to locate the DartDev snapshot to determine if we're able to find
    // the SDK snapshots with this SDK path. This is meant to handle
    // non-standard SDK layouts that can involve symlinks (e.g., Brew
    // installations, google3 tests, etc).
    if (!File(
      path.join(snapshotsDir, 'dartdev.dart.snapshot'),
    ).existsSync()) {
      return null;
    }
    return (sdkPath, runFromBuildRoot);
  }

  final (sdkPath, runFromBuildRoot) = trySDKPath(Platform.resolvedExecutable) ??
      trySDKPath(Platform.executable)!;

  final String snapshotDir;
  if (runFromBuildRoot) {
    snapshotDir = sdkPath;
  } else {
    snapshotDir = path.absolute(sdkPath, 'bin', 'snapshots');
  }

  return snapshotDir;
}

Future<DtdInfo?> startDtd({
  required bool machineMode,
  required bool printDtdUri,
}) async {
  final snapshotDir = getDTDSnapshotDir();
  final dtdAotSnapshot =  path.absolute(
    snapshotDir,
    'dart_tooling_daemon_aot.dart.snapshot',
  );
  final dtdSnapshot =  path.absolute(
    snapshotDir,
    'dart_tooling_daemon.dart.snapshot',
  );

  final completer = Completer<DtdInfo?>();
  void completeForError() => completer.complete(null);

  final exitPort = ReceivePort()
    ..listen((_) {
      completeForError();
    });
  final errorPort = ReceivePort()
    ..listen((_) {
      completeForError();
    });
  final receivePort = ReceivePort()
    ..listen((message) {
      try {
        // [message] is a JSON encoded String from package:dtd_impl.
        final json = jsonDecode(message) as Map<String, Object?>;
        if (json
            case {
              'tooling_daemon_details': {
                'uri': String uri,
                'trusted_client_secret': String secret,
              }
            }) {
          if (printDtdUri || machineMode) {
            DevToolsUtils.printOutput(
              'Serving the Dart Tooling Daemon at $uri',
              {
                'event': 'server.dtdStarted',
                'params': {'uri': uri},
              },
              machineMode: machineMode,
            );
          }
          completer.complete(DtdInfo(Uri.parse(uri), secret: secret));
        }
      } catch (_) {
        completeForError();
      }
    });

  try {
    // Try to spawn an isolate using the AOT snapshot of the tooling daemon.
    await Isolate.spawnUri(
      Uri.file(dtdAotSnapshot),
      ['--machine'],
      receivePort.sendPort,
      onExit: exitPort.sendPort,
      onError: errorPort.sendPort,
    );
  } catch (_, __) {
    // Spawning an isolate using the AOT snapshot of the tooling daemon failed,
    // we are probably in a JIT VM, try again using the JIT snapshot of the
    // tooling daemon.
    try {
      await Isolate.spawnUri(
        Uri.file(dtdSnapshot),
        ['--machine'],
        receivePort.sendPort,
        onExit: exitPort.sendPort,
        onError: errorPort.sendPort,
      );
    } catch (_, __) {
      completeForError();
    }
  }

  final result = await completer.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () => null,
  );
  receivePort.close();
  errorPort.close();
  exitPort.close();
  return result;
}
