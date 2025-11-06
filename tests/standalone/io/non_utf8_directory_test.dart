// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:expect/expect.dart";

testAsync() async {
  final tmp = await Directory.systemTemp.createTemp(
    "non_utf8_directory_test_async",
  );
  try {
    final rawPath = new Uint8List.fromList([182]);
    final asyncDir = new Directory.fromRawPath(rawPath);
    if (Platform.isMacOS || Platform.isIOS) {
      try {
        await asyncDir.create();
      } on FileSystemException catch (e) {
        // Macos doesn"t support non-UTF-8 paths.
        await tmp.delete(recursive: true);
        return;
      }
    } else {
      await asyncDir.create();
    }
    Expect.isTrue(await asyncDir.exists());

    await for (final e in tmp.list()) {
      // FIXME(bkonyi): reenable when rawPath is exposed.
      /*
        if (Platform.isWindows) {
          // Windows replaces invalid characters with � when creating file system
          // entities.
          final raw = e.rawPath;
          Expect.listEquals(raw.sublist(raw.length - 3), [239, 191, 189]);
        } else {
          Expect.equals(e.rawPath.last, 182);
        }
        */
    }
    await asyncDir.delete(recursive: true);
  } finally {
    await tmp.delete(recursive: true);
  }
}

testSync() {
  final tmp = Directory.systemTemp.createTempSync(
    "non_utf8_directory_test_sync",
  );
  try {
    final rawPath = new Uint8List.fromList([182]);
    final syncDir = new Directory.fromRawPath(rawPath);

    if (Platform.isMacOS || Platform.isIOS) {
      try {
        syncDir.createSync();
      } on FileSystemException catch (e) {
        // Macos doesn"t support non-UTF-8 paths.
        tmp.deleteSync(recursive: true);
        return;
      }
    } else {
      syncDir.createSync();
    }
    Expect.isTrue(syncDir.existsSync());

    for (final e in tmp.listSync()) {
      // FIXME(bkonyi): reenable when rawPath is exposed.
      /*
        if (Platform.isWindows) {
          // Windows replaces invalid characters with � when creating file system
          // entities.
          final raw = e.rawPath;
          Expect.listEquals(raw.sublist(raw.length - 3), [239, 191, 189]);
        } else {
          Expect.isTrue(e.rawPath.last, 182);
        }
        */
    }
    syncDir.deleteSync(recursive: true);
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

main() async {
  await testAsync();
  testSync();
}
