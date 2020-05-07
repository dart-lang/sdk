// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:async_helper/async_minitest.dart";

void testNullSafetyMode(String filePath, String version, String expected) {
  File mainIsolate = new File(filePath);
  mainIsolate.writeAsStringSync('''
    // $version
    import \'dart:isolate\';

    spawnFunc(List args) {
      var data = args[0];
      var replyTo = args[1];
      try {
        int x = null as int;
        replyTo.send(\'re: weak\');
      } catch (ex) {
        replyTo.send(\'re: strong\');
      }
    }

    void main() async {
      const String debugName = \'spawnedIsolate\';
      final exitPort = ReceivePort();
      final port = new ReceivePort();
      port.listen((msg) {
          print(msg);
          port.close();
      });

      final isolate = await Isolate.spawn(
          spawnFunc,
          [\'re: hi\', port.sendPort],
          paused: false,
          debugName: debugName,
          onExit: exitPort.sendPort);

      // Explicitly await spawned isolate exit to enforce main isolate not
      // completing (and the stand-alone runtime exiting) before the spawned
      // isolate is done.
      await exitPort.first;
    }
    ''');
  var exec = Platform.resolvedExecutable;
  var args = <String>[];
  args.add("--enable-experiment=non-nullable");
  args.add(mainIsolate.path);
  var result = Process.runSync(exec, args);
  expect(result.stdout.contains('$expected'), true);
}

void main() {
  // Create temporary directory.
  var tmpDir = Directory.systemTemp.createTempSync();
  var tmpDirPath = tmpDir.path;

  try {
    // Strong Isolate Spawning another Strong Isolate using spawn.
    testNullSafetyMode("$tmpDirPath/strong.dart", '', 're: strong');

    // Weak Isolate Spawning a Weak Isolate using spawn.
    testNullSafetyMode("$tmpDirPath/weak.dart", '@dart=2.6', 're: weak');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
