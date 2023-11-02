// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:expect/expect.dart";
import "test_utils.dart" show withTempDir;

const chunkCount = 8192;
const chunkSize = 8192;

Future<int> timeWrite(File file, chunks) async {
  final sink = file.openWrite();

  final Stopwatch stopwatch = new Stopwatch()..start();
  for (var chunk in chunks) {
    sink.add(chunk);
  }
  await sink.close();
  stopwatch.stop();

  Expect.equals(chunkCount * chunkSize, await file.length());

  await file.delete();

  return stopwatch.elapsedMilliseconds;
}

main() async {
  await withTempDir("regress50206", (Directory tempDir) async {
    File file = new File("${tempDir.path}/file.tmp");

    int arrayTime = 0;
    {
      var chunks = [];
      for (var i = 0; i < chunkCount; i++) {
        var chunk = new Uint8List(chunkSize);
        chunks.add(chunk);
      }
      arrayTime = await timeWrite(file, chunks);
      print("arrays: $arrayTime ms");
    }

    int unmodifiableArrayTime = 0;
    {
      var chunks = [];
      for (var i = 0; i < chunkCount; i++) {
        var chunk = new Uint8List(chunkSize).asUnmodifiableView();
        chunks.add(chunk);
      }
      unmodifiableArrayTime = await timeWrite(file, chunks);
      print("unmodifiable arrays: $unmodifiableArrayTime ms");
    }

    int viewTime = 0;
    {
      var chunks = [];
      var backing = new Uint8List(chunkSize * chunkCount);
      for (var i = 0; i < chunkCount; i++) {
        var chunk =
            new Uint8List.view(backing.buffer, i * chunkSize, chunkSize);
        chunks.add(chunk);
      }
      viewTime = await timeWrite(file, chunks);
      print("views: $viewTime ms");
    }

    int unmodifiableViewTime = 0;
    {
      var chunks = [];
      var backing = new Uint8List(chunkSize * chunkCount);
      for (var i = 0; i < chunkCount; i++) {
        var chunk = new Uint8List.view(backing.buffer, i * chunkSize, chunkSize)
            .asUnmodifiableView();
        chunks.add(chunk);
      }
      unmodifiableViewTime = await timeWrite(file, chunks);
      print("unmodifiable views: $unmodifiableViewTime ms");
    }

    // Assert with factor a 1000 to avoid the test being flaky from I/O
    // variance. If we copy the whole backing store for each view chunk, things
    // will be quadratically slower, i.e. more than a factor of 1000.
    Expect.isTrue(unmodifiableArrayTime / arrayTime < 1000);
    Expect.isTrue(viewTime / arrayTime < 1000);
    Expect.isTrue(unmodifiableViewTime / arrayTime < 1000);
  });
}
