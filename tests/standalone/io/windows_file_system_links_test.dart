// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";

createJunction(String dst, String link, void callback()) {
  Process.run("cmd.exe", ["/c", "mklink /J $link $dst"]).then((result) {
    if (result.exitCode == 0) {
      callback();
    } else {
      throw new Exception('link creation failed');
    }
  });
}


testJunctionTypeDelete() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';

  new Directory(x).createSync();
  createJunction(x, y, () {
    Expect.isTrue(new Directory(y).existsSync());
    Expect.isTrue(new Directory(x).existsSync());
    Expect.isTrue(FileSystemEntity.isLinkSync(y));
    Expect.isFalse(FileSystemEntity.isLinkSync(x));
    Expect.isTrue(FileSystemEntity.isDirectorySync(y));
    Expect.isTrue(FileSystemEntity.isDirectorySync(x));
    Expect.equals(FileSystemEntityType.DIRECTORY,
                  FileSystemEntity.typeSync(y));
    Expect.equals(FileSystemEntityType.DIRECTORY,
                  FileSystemEntity.typeSync(x));
    Expect.equals(FileSystemEntityType.LINK,
                  FileSystemEntity.typeSync(y, followLinks: false));
    Expect.equals(FileSystemEntityType.DIRECTORY,
                  FileSystemEntity.typeSync(x, followLinks: false));

    // Test Junction pointing to a missing directory.
    new Directory(x).deleteSync();
    Expect.isTrue(new Directory(y).existsSync());
    Expect.isFalse(new Directory(x).existsSync());
    Expect.isTrue(FileSystemEntity.isLinkSync(y));
    Expect.isFalse(FileSystemEntity.isLinkSync(x));
    Expect.isTrue(FileSystemEntity.isDirectorySync(y));
    Expect.isFalse(FileSystemEntity.isDirectorySync(x));
    Expect.equals(FileSystemEntityType.DIRECTORY,
                  FileSystemEntity.typeSync(y));
    Expect.equals(FileSystemEntityType.NOT_FOUND,
                  FileSystemEntity.typeSync(x));
    Expect.equals(FileSystemEntityType.LINK,
                  FileSystemEntity.typeSync(y, followLinks: false));
    Expect.equals(FileSystemEntityType.NOT_FOUND,
                  FileSystemEntity.typeSync(x, followLinks: false));

    // Delete Junction pointing to a missing directory.
    new Directory(y).deleteSync();
    Expect.isFalse(FileSystemEntity.isLinkSync(y));
    Expect.equals(FileSystemEntityType.NOT_FOUND,
                  FileSystemEntity.typeSync(y));

    new Directory(x).createSync();
    createJunction(x, y, () {
      Expect.equals(FileSystemEntityType.LINK,
                    FileSystemEntity.typeSync(y, followLinks: false));
      Expect.equals(FileSystemEntityType.DIRECTORY,
                    FileSystemEntity.typeSync(x, followLinks: false));

      // Delete Junction pointing to an existing directory.
      new Directory(y).deleteSync();
      Expect.equals(FileSystemEntityType.NOT_FOUND,
                    FileSystemEntity.typeSync(y));
      Expect.equals(FileSystemEntityType.NOT_FOUND,
                    FileSystemEntity.typeSync(y, followLinks: false));
      Expect.equals(FileSystemEntityType.DIRECTORY,
                    FileSystemEntity.typeSync(x));
      Expect.equals(FileSystemEntityType.DIRECTORY,
                    FileSystemEntity.typeSync(x, followLinks: false));
      temp.deleteSync(recursive: true);
    });
  });
}


main() {
  if (Platform.operatingSystem == 'windows') {
    testJunctionTypeDelete();
  }
}
