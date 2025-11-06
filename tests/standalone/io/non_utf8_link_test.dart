// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:expect/expect.dart";
import "package:path/path.dart";

const dirName = "foobar";

testAsync() async {
  Directory tmp = await Directory.systemTemp.createTemp(
    "non_utf8_link_test_async",
  );
  try {
    tmp = new Directory(await tmp.resolveSymbolicLinks());
    final path = join(tmp.path, dirName);
    final rawPath = utf8
        .encode(path)
        .sublist(0, path.length - dirName.length)
        .toList();
    rawPath.add(47);
    rawPath.add(182);

    final f = new Directory(path);
    await f.create();
    Expect.isTrue(await f.exists());

    final rawName = new Uint8List.fromList(rawPath);
    var asyncLink = new Link.fromRawPath(rawName);

    if (Platform.isMacOS || Platform.isIOS) {
      try {
        asyncLink = await asyncLink.create(path);
      } on FileSystemException catch (e) {
        // Macos doesn"t support non-UTF-8 paths.
        await tmp.delete(recursive: true);
        return;
      }
    } else {
      asyncLink = await asyncLink.create(path);
    }
    Expect.isTrue(await asyncLink.exists());

    await for (final e in tmp.list()) {
      if (e is Link) {
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
        Expect.equals(e.path, path);
      }
    }

    // FIXME(bkonyi): reenable when rawPath is exposed.
    // expect(asyncLink.absolute.rawPath, rawPath);
    Expect.equals(await asyncLink.resolveSymbolicLinks(), path);
    Expect.equals(await asyncLink.target(), path);
    await asyncLink.delete();
  } finally {
    await tmp.delete(recursive: true);
  }
}

testSync() {
  Directory tmp = Directory.systemTemp.createTempSync(
    "non_utf8_link_test_sync",
  );
  try {
    tmp = new Directory(tmp.resolveSymbolicLinksSync());
    final path = join(tmp.path, dirName);
    final rawPath = utf8
        .encode(path)
        .sublist(0, path.length - dirName.length)
        .toList();
    rawPath.add(47); // "/"
    rawPath.add(182); // invalid UTF-8 character.

    final f = new Directory(path);
    f.createSync();
    Expect.isTrue(f.existsSync());

    final rawName = new Uint8List.fromList(rawPath);
    final syncLink = new Link.fromRawPath(rawName);

    if (Platform.isMacOS || Platform.isIOS) {
      try {
        syncLink.createSync(path);
      } on FileSystemException catch (e) {
        // Macos doesn"t support non-UTF-8 paths.
        tmp.deleteSync(recursive: true);
        return;
      }
    } else {
      syncLink.createSync(path);
    }
    Expect.isTrue(syncLink.existsSync());

    for (final e in tmp.listSync()) {
      if (e is Link) {
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
        Expect.equals(e.path, path);
      }
    }
    // FIXME(bkonyi): reenable when rawPath is exposed.
    // expect(syncLink.absolute.rawPath, rawPath);
    Expect.equals(syncLink.resolveSymbolicLinksSync(), path);
    Expect.equals(syncLink.targetSync(), path);
    syncLink.deleteSync();
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

main() async {
  await testAsync();
  testSync();
}
