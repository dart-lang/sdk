// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:test/test.dart';

Future main() async {
  var asyncLink;
  var syncLink;

  test('Non-UTF8 Link', () async {
    Directory.current = await Directory.systemTemp.createTemp();
    final path = join(Directory.current.path, 'foobar');
    final rawPath = Directory.current.rawPath.toList();
    rawPath.add(47);
    rawPath.add(182);

    final f = new Directory(path);
    await f.create();
    expect(await f.exists(), isTrue);

    final rawName = new Uint8List.fromList(rawPath);
    asyncLink = new Link.fromRawPath(rawName);

    asyncLink = await asyncLink.create(path);
    expect(await asyncLink.exists(), isTrue);

    await for (final e in Directory.current.list()) {
      if (e is Link) {
        if (Platform.isWindows) {
          // Windows replaces invalid characters with � when creating file system
          // entities.
          final raw = e.rawPath;
          expect(raw.sublist(raw.length - 3), [239, 191, 189]);
        } else {
          expect(e.rawPath.last, 182);
        }
      }
    }

    expect(asyncLink.absolute.rawPath, rawPath);
    expect(await asyncLink.resolveSymbolicLinks(), path);
    expect(await asyncLink.target(), path);
    await asyncLink.delete();
  });

  test('Non-UTF8 Link Sync', () {
    Directory.current = Directory.systemTemp.createTempSync();
    final path = join(Directory.current.path, 'foobar');
    final rawPath = Directory.current.rawPath.toList();
    rawPath.add(47); // '/'
    rawPath.add(182); // invalid UTF-8 character.

    final f = new Directory(path);
    f.createSync();
    expect(f.existsSync(), isTrue);

    final rawName = new Uint8List.fromList(rawPath);
    syncLink = new Link.fromRawPath(rawName);

    syncLink.createSync(path);
    expect(syncLink.existsSync(), isTrue);

    for (final e in Directory.current.listSync()) {
      if (e is Link) {
        if (Platform.isWindows) {
          // Windows replaces invalid characters with � when creating file system
          // entities.
          final raw = e.rawPath;
          expect(raw.sublist(raw.length - 3), [239, 191, 189]);
        } else {
          expect(e.rawPath.last, 182);
        }
      }
    }
    expect(syncLink.absolute.rawPath, rawPath);
    expect(syncLink.resolveSymbolicLinksSync(), path);
    expect(syncLink.targetSync(), path);
    syncLink.deleteSync();
  });

  tearDown(() {
    if ((asyncLink != null) && asyncLink.existsSync()) {
      asyncLink.deleteSync();
    }
    if ((syncLink != null) && syncLink.existsSync()) {
      syncLink.deleteSync();
    }
  });
}
