// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

Future main() async {
  var asyncDir;
  var syncDir;

  test('Non-UTF8 Directory Listing', () async {
    Directory.current = await Directory.systemTemp.createTemp();
    final rawPath = new Uint8List.fromList([182]);
    asyncDir = new Directory.fromRawPath(rawPath);

    await asyncDir.create();
    expect(await asyncDir.exists(), isTrue);

    await for (final e in Directory.current.list()) {
      expect(e.rawPath.last, 182);
    }
    await asyncDir.delete(recursive: true);
  });

  test('Non-UTF8 Directory Sync Listing', () {
    Directory.current = Directory.systemTemp.createTempSync();
    final rawPath = new Uint8List.fromList([182]);
    syncDir = new Directory.fromRawPath(rawPath);

    syncDir.createSync();
    expect(syncDir.existsSync(), isTrue);

    for (final e in Directory.current.listSync()) {
      expect(e.rawPath.last, 182);
    }

    syncDir.deleteSync(recursive: true);
  });

  tearDown(() {
    if ((asyncDir != null) && asyncDir.existsSync()) {
      asyncDir.deleteSync(recursive: true);
    }
    if ((syncDir != null) && syncDir.existsSync()) {
      syncDir.deleteSync(recursive: true);
    }
  });
}
