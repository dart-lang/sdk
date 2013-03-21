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
  Expect.equals(target, new Link(link).targetSync());
  Expect.throws(() => new Link(target).targetSync());

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

  // Test FileSystemEntity.identical on files, directories, and links,
  // reached by different paths.
  Expect.isTrue(FileSystemEntity.identicalSync(createdDirectly,
                                               createdDirectly));
  Expect.isFalse(FileSystemEntity.identicalSync(createdDirectly,
                                                createdThroughLink));
  Expect.isTrue(FileSystemEntity.identicalSync(createdDirectly,
      base.append('link/createdDirectly').toNativePath()));
  Expect.isTrue(FileSystemEntity.identicalSync(createdThroughLink,
      base.append('target/createdThroughLink').toNativePath()));

  Expect.isFalse(FileSystemEntity.identicalSync(target, link));
  Expect.isTrue(FileSystemEntity.identicalSync(link, link));
  Expect.isTrue(FileSystemEntity.identicalSync(target, target));
  Expect.isTrue(FileSystemEntity.identicalSync(target,
                                               new Link(link).targetSync()));
  String absolutePath = new File(".").fullPathSync();
  Expect.isTrue(FileSystemEntity.identicalSync(".", absolutePath));

  String createdFile = base.append('target/createdFile').toNativePath();
  new File(createdFile).createSync();
  Expect.isTrue(FileSystemEntity.identicalSync(createdFile, createdFile));
  Expect.isFalse(FileSystemEntity.identicalSync(createdFile, createdDirectly));
  Expect.isTrue(FileSystemEntity.identicalSync(createdFile,
      base.append('link/createdFile').toNativePath()));
  Expect.throws(() => FileSystemEntity.identicalSync(createdFile,
      base.append('link/foo').toNativePath()));

  new Directory.fromPath(base).deleteSync(recursive: true);
}


main() {
  testCreateSync();
}
