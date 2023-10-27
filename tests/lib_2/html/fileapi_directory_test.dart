// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:html';

import 'package:async_helper/async_minitest.dart';

main() {
  if (!FileSystem.supported) return;
  // Prepend this file name to prevent collisions among tests runnning on the
  // same browser.
  const prefix = 'fileapi_directory_';

  test('directoryDoesntExist', () async {
    final fs = await window.requestFileSystem(100);
    try {
      await fs.root.getDirectory('${prefix}directory2');
    } on DomException catch (error) {
      expect(DomException.NOT_FOUND, error.name);
    }
  });

  test('directoryCreate', () async {
    final fs = await window.requestFileSystem(100);
    var entry = await fs.root.createDirectory('${prefix}directory3');
    expect(entry.name, equals('${prefix}directory3'));
  });
}
