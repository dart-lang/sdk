// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:expect/expect.dart";

testAsync() async {
  final tmp = await Directory.systemTemp.createTemp("non_utf8_file_test_async");

  try {
    final rawPath = new Uint8List.fromList([182]);
    final asyncFile = new File.fromRawPath(rawPath);
    if (Platform.isMacOS || Platform.isIOS) {
      try {
        await asyncFile.create();
      } on FileSystemException catch (e) {
        // Macos doesn"t support non-UTF-8 paths.
        await tmp.delete(recursive: true);
        return;
      }
    } else {
      await asyncFile.create();
    }
    Expect.isTrue(await asyncFile.exists());

    for (final file in tmp.listSync()) {
      // FIXME(bkonyi): reenable when rawPath is exposed.
      /*
      if (Platform.isWindows) {
        // Windows replaces invalid characters with � when creating file system
        // entities.
        final raw = file.rawPath;
        Expect.listEquals(raw.sublist(raw.length - 3), [239, 191, 189]);
      } else {
        Expect.equals(file.rawPath.last, 182);
      }
      */
      // FIXME(bkonyi): this isn"t true on some versions of MacOS. Why?
      if (!Platform.isMacOS && !Platform.isIOS) {
        Expect.isTrue(file.path.endsWith("�"));
      }
    }
    await asyncFile.delete();
  } finally {
    await tmp.delete(recursive: true);
  }
}

testSync() {
  final tmp = Directory.systemTemp.createTempSync("non_utf8_file_test_sync");
  try {
    final rawPath = new Uint8List.fromList([182]);
    final syncFile = new File.fromRawPath(rawPath);

    if (Platform.isMacOS || Platform.isIOS) {
      try {
        syncFile.createSync();
      } on FileSystemException catch (e) {
        // Macos doesn"t support non-UTF-8 paths.
        tmp.deleteSync(recursive: true);
        return;
      }
    } else {
      syncFile.createSync();
    }
    Expect.isTrue(syncFile.existsSync());

    for (final file in tmp.listSync()) {
      // FIXME(bkonyi): reenable when rawPath is exposed.
      /*
      if (Platform.isWindows) {
        // Windows replaces invalid characters with � when creating file system
        // entities.
        final raw = file.rawPath;
        Expect.listEquals(raw.sublist(raw.length - 3), [239, 191, 189]);
      } else {
        Expect.equals(file.rawPath.last, 182);
      }
      */
      // FIXME(bkonyi): this isn"t true on some versions of MacOS. Why?
      if (!Platform.isMacOS && !Platform.isIOS) {
        Expect.isTrue(file.path.endsWith("�"));
      }
    }
    syncFile.deleteSync();
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

main() async {
  await testAsync();
  testSync();
}
