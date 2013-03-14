// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";

// Test the dart:io Link class.

testCreateSync() {
  Path base = new Path(new Directory('').createTempSync().path);
  String link = base.append('link').toNativePath();
  String target = base.append('target').toNativePath();
  new Directory(target).createSync();
  new Link(link).createSync(target);

  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(link));
  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(target));
  Expect.equals(FileSystemEntityType.LINK,
                FileSystemEntity.typeSync(link, followLinks: false));
  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(target, followLinks: false));
  Expect.isTrue(FileSystemEntity.isLinkSync(link));
  Expect.isFalse(FileSystemEntity.isLinkSync(target));
  Expect.isTrue(new Directory(link).existsSync());
  Expect.isTrue(new Directory(target).existsSync());
  Expect.isTrue(new Link(link).existsSync());
  Expect.isFalse(new Link(target).existsSync());

  String createdThroughLink =
      base.append('link/createdThroughLink').toNativePath();
  String createdDirectly = base.append('target/createdDirectly').toNativePath();
  new Directory(createdThroughLink).createSync();
  new Directory(createdDirectly).createSync();
  Expect.isTrue(new Directory(createdThroughLink).existsSync());
  Expect.isTrue(new Directory(createdDirectly).existsSync());
  Expect.isTrue(new Directory.fromPath(base.append('link/createdDirectly'))
                .existsSync());
  Expect.isTrue(new Directory.fromPath(base.append('target/createdThroughLink'))
                .existsSync());
  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(createdThroughLink,
                                          followLinks: false));
  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(createdDirectly, followLinks: false));

  new Directory.fromPath(base).deleteSync(recursive: true);
}


main() {
  testCreateSync();
}
