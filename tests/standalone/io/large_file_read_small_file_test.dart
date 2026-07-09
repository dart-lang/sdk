// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

Future runWithTempDir(Future Function(String dir) callback) async {
  final tempDir = Directory.systemTemp.createTempSync("large_file_read");
  try {
    await callback(tempDir.path);
  } finally {
    tempDir.delete(recursive: true);
  }
}

main() async {
  // MSAN's malloc implementation will not free memory when shrinking
  // allocations via realloc (e.g. realloc(malloc(1 GB), new_size=10) will
  // hold on to the 1 GB).
  if (Platform.executable.contains('MSAN')) return;

  await runWithTempDir((String dir) async {
    final file = File(path.join(dir, 'hello_world.txt'));
    await file.writeAsString('hello world');
    final RandomAccessFile randomAccessFile = await file.open();

    try {
      final buffers = [];
      for (int i = 0; i < 100 * 1000; ++i) {
        if (i % 1000 == 0) {
          print(i);
        }
        // We issue a 1 MB read but get only a small typed data back. We hang on
        // to those buffers. If the implementation actually malloc()ed 1 MB then
        // we would hang on to 100 GB and this test would OOM.
        // If the implementation instead correctly shrinks the buffer before
        // giving it to Dart as external typed data, we only consume ~ 100 KB.
        buffers.add(await randomAccessFile.read(1 * 1024 * 1024));
        await randomAccessFile.setPosition(0);

        // To avoid machines becoming unusable if the test fails, we'll fail
        // explicitly if we hit 2 GB.
        if (ProcessInfo.currentRss > 2 * 1024 * 1024 * 1024) {
          throw 'The dart:io implementation is buggy and uses too much memory';
        }
      }
      for (final buffer in buffers) {
        Expect.equals('hello world'.length, buffer.length);
      }
    } finally {
      randomAccessFile.close();
    }
  });
}
