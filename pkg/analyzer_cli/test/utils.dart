// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:path/path.dart' as pathos;

/// Gets the test directory in a way that works with package:test
/// See <https://github.com/dart-lang/test/issues/110> for more info.
final String testDirectory = pathos.dirname(
    pathos.fromUri((reflectClass(_TestUtils).owner as LibraryMirror).uri));

/// Recursively copy the specified [src] directory (or file)
/// to the specified destination path.
Future<void> recursiveCopy(FileSystemEntity src, String dstPath) async {
  if (src is Directory) {
    await (new Directory(dstPath)).create(recursive: true);
    for (FileSystemEntity entity in src.listSync()) {
      await recursiveCopy(
          entity, pathos.join(dstPath, pathos.basename(entity.path)));
    }
  } else if (src is File) {
    await src.copy(dstPath);
  }
}

/// Creates a temporary directory and passes its path to [fn]. Once [fn]
/// completes, the temporary directory and all its contents will be deleted.
///
/// Returns the return value of [fn].
Future<dynamic> withTempDirAsync(Future<dynamic> fn(String path)) async {
  var tempDir = (await Directory.systemTemp.createTemp('analyzer_')).path;
  try {
    return await fn(tempDir);
  } finally {
    await new Directory(tempDir).delete(recursive: true);
  }
}

class _TestUtils {}
