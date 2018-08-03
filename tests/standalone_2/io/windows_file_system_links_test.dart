// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "dart:io";
import "dart:isolate";

testJunctionTypeDelete() {
  var temp =
      Directory.systemTemp.createTempSync('dart_windows_file_system_links');
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';

  new Directory(x).createSync();
  new Link(y).create(x).then((_) {
    Expect.isTrue(new Directory(y).existsSync());
    Expect.isTrue(new Directory(x).existsSync());
    Expect.isTrue(FileSystemEntity.isLinkSync(y));
    Expect.isFalse(FileSystemEntity.isLinkSync(x));
    Expect.isTrue(FileSystemEntity.isDirectorySync(y));
    Expect.isTrue(FileSystemEntity.isDirectorySync(x));
    Expect.equals(FileSystemEntityType.directory, FileSystemEntity.typeSync(y));
    Expect.equals(FileSystemEntityType.directory, FileSystemEntity.typeSync(x));
    Expect.equals(FileSystemEntityType.link,
        FileSystemEntity.typeSync(y, followLinks: false));
    Expect.equals(FileSystemEntityType.directory,
        FileSystemEntity.typeSync(x, followLinks: false));
    Expect.equals(x, new Link(y).targetSync());

    // Test Junction pointing to a missing directory.
    new Directory(x).deleteSync();
    Expect.isTrue(new Link(y).existsSync());
    Expect.isFalse(new Directory(x).existsSync());
    Expect.isTrue(FileSystemEntity.isLinkSync(y));
    Expect.isFalse(FileSystemEntity.isLinkSync(x));
    Expect.isFalse(FileSystemEntity.isDirectorySync(y));
    Expect.isFalse(FileSystemEntity.isDirectorySync(x));
    Expect.equals(FileSystemEntityType.link, FileSystemEntity.typeSync(y));
    Expect.equals(FileSystemEntityType.notFound, FileSystemEntity.typeSync(x));
    Expect.equals(FileSystemEntityType.link,
        FileSystemEntity.typeSync(y, followLinks: false));
    Expect.equals(FileSystemEntityType.notFound,
        FileSystemEntity.typeSync(x, followLinks: false));
    Expect.equals(x, new Link(y).targetSync());

    // Delete Junction pointing to a missing directory.
    new Link(y).deleteSync();
    Expect.isFalse(FileSystemEntity.isLinkSync(y));
    Expect.equals(FileSystemEntityType.notFound, FileSystemEntity.typeSync(y));
    Expect.throws(() => new Link(y).targetSync());

    new Directory(x).createSync();
    new Link(y).create(x).then((_) {
      Expect.equals(FileSystemEntityType.link,
          FileSystemEntity.typeSync(y, followLinks: false));
      Expect.equals(FileSystemEntityType.directory,
          FileSystemEntity.typeSync(x, followLinks: false));
      Expect.equals(x, new Link(y).targetSync());

      // Delete Junction pointing to an existing directory.
      new Directory(y).deleteSync();
      Expect.equals(
          FileSystemEntityType.notFound, FileSystemEntity.typeSync(y));
      Expect.equals(FileSystemEntityType.notFound,
          FileSystemEntity.typeSync(y, followLinks: false));
      Expect.equals(
          FileSystemEntityType.directory, FileSystemEntity.typeSync(x));
      Expect.equals(FileSystemEntityType.directory,
          FileSystemEntity.typeSync(x, followLinks: false));
      Expect.throws(() => new Link(y).targetSync());

      temp.deleteSync(recursive: true);
    });
  });
}

main() {
  // Links on other platforms are tested by file_system_[async_]links_test.
  if (Platform.operatingSystem == 'windows') {
    testJunctionTypeDelete();
  }
}
