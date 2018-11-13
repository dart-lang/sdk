// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:test/test.dart';

Future main() async {
  var asyncLink;
  var syncLink;
  const dirName = 'foobar';

  test('Non-UTF8 Link', () async {
    Directory tmp =
        await Directory.systemTemp.createTemp('non_utf8_link_test_async');
    try {
      tmp = new Directory(await tmp.resolveSymbolicLinks());
      final path = join(tmp.path, dirName);
      final rawPath =
          utf8.encode(path).sublist(0, path.length - dirName.length).toList();
      rawPath.add(47);
      rawPath.add(182);

      final f = new Directory(path);
      await f.create();
      expect(await f.exists(), isTrue);

      final rawName = new Uint8List.fromList(rawPath);
      asyncLink = new Link.fromRawPath(rawName);

      if (Platform.isMacOS || Platform.isIOS) {
        try {
          asyncLink = await asyncLink.create(path);
        } on FileSystemException catch (e) {
          // Macos doesn't support non-UTF-8 paths.
          await tmp.delete(recursive: true);
          return;
        }
      } else {
        asyncLink = await asyncLink.create(path);
      }
      expect(await asyncLink.exists(), isTrue);

      await for (final e in tmp.list()) {
        if (e is Link) {
          // FIXME(bkonyi): reenable when rawPath is exposed.
          /*
          if (Platform.isWindows) {
            // Windows replaces invalid characters with � when creating file system
            // entities.
            final raw = e.rawPath;
            expect(raw.sublist(raw.length - 3), [239, 191, 189]);
          } else {
            expect(e.rawPath.last, 182);
          }
          */
          expect(e.path, path);
        }
      }

      // FIXME(bkonyi): reenable when rawPath is exposed.
      // expect(asyncLink.absolute.rawPath, rawPath);
      expect(await asyncLink.resolveSymbolicLinks(), path);
      expect(await asyncLink.target(), path);
      await asyncLink.delete();
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  test('Non-UTF8 Link Sync', () {
    Directory tmp =
        Directory.systemTemp.createTempSync('non_utf8_link_test_sync');
    try {
      tmp = new Directory(tmp.resolveSymbolicLinksSync());
      final path = join(tmp.path, dirName);
      final rawPath =
          utf8.encode(path).sublist(0, path.length - dirName.length).toList();
      rawPath.add(47); // '/'
      rawPath.add(182); // invalid UTF-8 character.

      final f = new Directory(path);
      f.createSync();
      expect(f.existsSync(), isTrue);

      final rawName = new Uint8List.fromList(rawPath);
      syncLink = new Link.fromRawPath(rawName);

      if (Platform.isMacOS || Platform.isIOS) {
        try {
          syncLink.createSync(path);
        } on FileSystemException catch (e) {
          // Macos doesn't support non-UTF-8 paths.
          tmp.deleteSync(recursive: true);
          return;
        }
      } else {
        syncLink.createSync(path);
      }
      expect(syncLink.existsSync(), isTrue);

      for (final e in tmp.listSync()) {
        if (e is Link) {
          // FIXME(bkonyi): reenable when rawPath is exposed.
          /*
          if (Platform.isWindows) {
            // Windows replaces invalid characters with � when creating file system
            // entities.
            final raw = e.rawPath;
            expect(raw.sublist(raw.length - 3), [239, 191, 189]);
          } else {
            expect(e.rawPath.last, 182);
          }
          */
          expect(e.path, path);
        }
      }
      // FIXME(bkonyi): reenable when rawPath is exposed.
      // expect(syncLink.absolute.rawPath, rawPath);
      expect(syncLink.resolveSymbolicLinksSync(), path);
      expect(syncLink.targetSync(), path);
      syncLink.deleteSync();
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });
}
