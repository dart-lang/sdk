// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/legacy/async_minitest.dart'; // ignore: deprecated_member_use

main() {
  if (!FileSystem.supported) return;
  // Prepend this file name to prevent collisions among tests running on the
  // same browser.
  const prefix = 'fileapi_directory_';

  test('directoryDoesntExist', () async {
    final fs = await window.requestFileSystem(100);
    try {
      await fs.root!.getDirectory('${prefix}directory2');
    } on DomException catch (error) {
      expect(DomException.NOT_FOUND, error.name);
    }
  });

  test('directoryCreate', () async {
    final fs = await window.requestFileSystem(100);
    var entry = await fs.root!.createDirectory('${prefix}directory3');
    expect(entry.name, equals('${prefix}directory3'));
  });
}
