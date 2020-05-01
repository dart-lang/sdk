// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:async_helper/async_minitest.dart";

void testNullSafetyMode(String filePath, String uri, String expected) {
  File mainIsolate = new File(filePath);
  mainIsolate.writeAsStringSync('''
    library spawn_tests;

    import \'dart:isolate\';

    void main() async {
      const String debugName = \'spawnedIsolate\';
      final exitPort = ReceivePort();
      final port = new ReceivePort();
      port.listen((msg) {
          print(msg);
          port.close();
      });

      final isolate = await Isolate.spawnUri(
        Uri.parse(\'$uri\'),
          [\'re: hi\'],
          port.sendPort,
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

  // Generate code for an isolate to run in strong mode.
  File strongIsolate = new File("$tmpDirPath/strong_isolate.dart");
  strongIsolate.writeAsStringSync('''
    library SpawnUriStrongIsolate;
    main(List<String> args, replyTo) {
      var data = args[0];
      try {
        int x = null as int;
        replyTo.send(\'re: weak\');
      } catch (ex) {
        replyTo.send(\'re: strong\');
      }
    }
    ''');

  // Generate code for an isolate to run in weak mode.
  File weakIsolate = new File("$tmpDirPath/weak_isolate.dart");
  weakIsolate.writeAsStringSync('''
    // @dart=2.7
    library SpawnUriStrongIsolate;
    main(List<String> args, replyTo) {
      var data = args[0];
      try {
        int x = null as int;
        replyTo.send(\'re: weak\');
      } catch (ex) {
        replyTo.send(\'re: strong\');
      }
    }
    ''');

  try {
    // Strong Isolate Spawning another Strong Isolate using spawnUri.
    testNullSafetyMode(
        "$tmpDirPath/strong_strong.dart", strongIsolate.path, 're: strong');

    // Strong Isolate Spawning a Weak Isolate using spawnUri.
    testNullSafetyMode(
        "$tmpDirPath/strong_weak.dart", weakIsolate.path, 're: weak');

    // Weak Isolate Spawning a Strong Isolate using spawnUri.
    testNullSafetyMode(
        "$tmpDirPath/weak_strong.dart", strongIsolate.path, 're: strong');

    // Weak Isolate Spawning a Weak Isolate using spawnUri.
    testNullSafetyMode(
        "$tmpDirPath/weak_weak.dart", weakIsolate.path, 're: weak');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
