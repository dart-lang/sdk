// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that using spawnUri to spawn an isolate from app-jit snapshot works.

import 'dart:io';
import 'dart:isolate';

import 'snapshot_test_helper.dart';

Future<void> main() =>
    runAppJitTest(Platform.script.resolve('appjit_spawnuri_test_body.dart'),
        runSnapshot: (snapshotPath) async {
      final exitPort = ReceivePort();
      final messagePort = ReceivePort();
      await Isolate.spawnUri(Uri.file(snapshotPath), [], messagePort.sendPort,
          onExit: exitPort.sendPort);
      final result = await Future.wait([messagePort.first, exitPort.first]);
      print('DONE (${result[0]})');
      return Result('Isolate.spawnUri(${Uri.file(snapshotPath)})',
          ProcessResult(0, 0, result[0], ''));
    });
