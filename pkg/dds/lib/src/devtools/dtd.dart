// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:devtools_shared/devtools_shared.dart' show DTDConnectionInfo;
import 'package:path/path.dart' as path;

import 'utils.dart';

Future<DTDConnectionInfo> startDtd({
  required bool machineMode,
  required bool printDtdUri,
}) async {
  final sdkPath = File(Platform.resolvedExecutable).parent.parent.path;
  final dtdSnapshot = path.absolute(
    sdkPath,
    'bin',
    'snapshots',
    'dart_tooling_daemon.dart.snapshot',
  );

  final completer = Completer<DTDConnectionInfo>();
  void completeForError() => completer.complete((uri: null, secret: null));

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
          completer.complete((uri: uri, secret: secret));
        }
      } catch (_) {
        completeForError();
      }
    });

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

  final result = await completer.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () => (uri: null, secret: null),
  );
  receivePort.close();
  errorPort.close();
  exitPort.close();
  return result;
}
