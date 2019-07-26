// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:path/path.dart" as p;

import "snapshot_test_helper.dart";

Future<void> main(List<String> args) async {
  if (args.contains('--child')) {
    print('done');
    return;
  }

  if (!Platform.script.toString().endsWith(".dart")) {
    print("This test must run from source");
    return;
  }

  await withTempDir((String tmp) async {
    // We don't support snapshot with code on IA32.
    final String appSnapshotKind =
        Platform.version.contains("ia32") ? "app" : "app-jit";

    await Process.run(Platform.executable, [
      '--snapshot=$tmp/fib.dart.snapshot',
      '--snapshot-kind=$appSnapshotKind',
      Platform.script.toFilePath(),
      '--child'
    ]);

    final onExit = RawReceivePort();
    final onError = RawReceivePort();

    onError.handler = (e) {
      onError.close();
      onExit.close();
      throw e;
    };

    onExit.handler = (_) {
      onError.close();
      onExit.close();
    };

    await Isolate.spawnUri(
        Uri.file('$tmp/fib.dart.snapshot'), ['--child'], null,
        onExit: onExit.sendPort, onError: onError.sendPort);
  });
}
