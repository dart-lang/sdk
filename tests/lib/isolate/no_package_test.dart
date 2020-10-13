// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:async_helper/async_minitest.dart";

void testNoPackages(String filePath, Uri uri, String expected) {
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
          [\'$expected\'],
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
  args.add(mainIsolate.path);
  var result = Process.runSync(exec, args);
  print('stdout: ${result.stdout}');
  print('stderr: ${result.stderr}');
  expect(result.stdout.contains('$expected'), true);
}

void main() {
  // Create temporary directory.
  var tmpDir = Directory.systemTemp.createTempSync();
  var tmpDirPath = tmpDir.path;

  // Generate code for an isolate to run without any package specification.
  File noPackageIsolate = new File("$tmpDirPath/no_package.dart");
  noPackageIsolate.writeAsStringSync('''
    library SpawnUriIsolate;
    main(List<String> args, replyTo) {
      var data = args[0];
      replyTo.send(data);
    }
    ''');

  try {
    // Isolate Spawning another Isolate without any package specification.
    testNoPackages("$tmpDirPath/no_package_isolate.dart",
        Uri.file(noPackageIsolate.path), 're: no package');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
