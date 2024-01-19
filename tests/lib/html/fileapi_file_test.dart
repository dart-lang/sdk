// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:async_helper/async_minitest.dart';

main() {
  if (!FileSystem.supported) return;
  // Prepend this file name to prevent collisions among tests runnning on the
  // same browser.
  const prefix = 'fileapi_file_';

  test('fileDoesntExist', () async {
    final fs = await window.requestFileSystem(100);
    try {
      await fs.root!.getFile('${prefix}file2');
      fail("file found");
    } on DomException catch (error) {
      expect(DomException.NOT_FOUND, error.name);
    }
  });

  test('fileCreate', () async {
    final fs = await window.requestFileSystem(100);
    var fileObj = await fs.root!.createFile('${prefix}file4');
    expect(fileObj.name, equals('${prefix}file4'));
    expect(fileObj.isFile, isTrue);

    var metadata = await fileObj.getMetadata();
    var changeTime = metadata.modificationTime;

    // Increased Windows buildbots can sometimes be particularly slow.
    expect(new DateTime.now().difference(changeTime).inMinutes < 4, isTrue);
    expect(metadata.size, equals(0));
  });
}
