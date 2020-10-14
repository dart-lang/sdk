// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:async_helper/async_minitest.dart";

void generateIsolateSource(String filePath, String version) {
  File isolateSource = new File(filePath);
  isolateSource.writeAsStringSync('''
      // @dart=$version
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
}

void generateOutput(String sourcePath, String outPath, String type) {
  var exec = Platform.resolvedExecutable;
  var args = <String>[];
  args.add("--snapshot-kind=$type");
  args.add("--snapshot=$outPath");
  args.add("--enable-experiment=non-nullable");
  args.add(sourcePath);
  var result = Process.runSync(exec, args);
  print('snapshot $type stdout: ${result.stdout}');
  print('snapshot $type stderr: ${result.stderr}');
}

void generateKernel(String sourcePath, String outPath) {
  generateOutput(sourcePath, outPath, "kernel");
}

void generateAppJIT(String sourcePath, String outPath) {
  generateOutput(sourcePath, outPath, "app-jit");
}

void testNullSafetyMode(String filePath, String expected) {
  var exec = Platform.resolvedExecutable;
  var args = <String>[];
  args.add("--enable-experiment=non-nullable");
  args.add(filePath);
  var result = Process.runSync(exec, args);
  print('test stdout: ${result.stdout}');
  print('test stderr: ${result.stderr}');
  expect(result.stdout.contains('$expected'), true);
}
