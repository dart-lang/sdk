// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";


createLink(String dst, String link, void callback()) {
  new Link(link).create(dst).then((_) => callback());
}


testFileExistsCreate() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';
  createLink(x, y, () {
    Expect.isFalse(new File(y).existsSync());
    Expect.isFalse(new File(x).existsSync());
    Expect.isTrue(FileSystemEntity.isLinkSync(y));
    Expect.isFalse(FileSystemEntity.isLinkSync(x));
    Expect.equals(FileSystemEntityType.NOT_FOUND, FileSystemEntity.typeSync(y));
    Expect.equals(FileSystemEntityType.NOT_FOUND, FileSystemEntity.typeSync(x));
    Expect.equals(FileSystemEntityType.LINK,
                  FileSystemEntity.typeSync(y, followLinks: false));
    Expect.equals(FileSystemEntityType.NOT_FOUND,
                  FileSystemEntity.typeSync(x, followLinks: false));

    new File(y).createSync();
    Expect.isTrue(new File(y).existsSync());
    Expect.isTrue(new File(x).existsSync());
    Expect.isTrue(FileSystemEntity.isLinkSync(y));
    Expect.isFalse(FileSystemEntity.isLinkSync(x));
    Expect.isTrue(FileSystemEntity.isFileSync(y));
    Expect.isTrue(FileSystemEntity.isFileSync(x));
    Expect.equals(FileSystemEntityType.FILE, FileSystemEntity.typeSync(y));
    Expect.equals(FileSystemEntityType.FILE, FileSystemEntity.typeSync(x));
    Expect.equals(FileSystemEntityType.LINK,
                  FileSystemEntity.typeSync(y, followLinks: false));
    Expect.equals(FileSystemEntityType.FILE,
                  FileSystemEntity.typeSync(x, followLinks: false));
    new File(x).deleteSync();
    new Directory(x).createSync();
    Expect.isTrue(FileSystemEntity.isLinkSync(y));
    Expect.isFalse(FileSystemEntity.isLinkSync(x));
    Expect.isTrue(FileSystemEntity.isDirectorySync(y));
    Expect.isTrue(FileSystemEntity.isDirectorySync(x));
    Expect.equals(FileSystemEntityType.DIRECTORY, FileSystemEntity.typeSync(y));
    Expect.equals(FileSystemEntityType.DIRECTORY, FileSystemEntity.typeSync(x));
    Expect.equals(FileSystemEntityType.LINK,
                  FileSystemEntity.typeSync(y, followLinks: false));
    Expect.equals(FileSystemEntityType.DIRECTORY,
                  FileSystemEntity.typeSync(x, followLinks: false));
    new File(y).deleteSync();
    Expect.isFalse(FileSystemEntity.isLinkSync(y));
    Expect.isFalse(FileSystemEntity.isLinkSync(x));
    Expect.equals(FileSystemEntityType.NOT_FOUND, FileSystemEntity.typeSync(y));
    Expect.equals(FileSystemEntityType.DIRECTORY, FileSystemEntity.typeSync(x));

    temp.deleteSync(recursive: true);
  });
}


testFileDelete() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';
  new File(x).createSync();
  createLink(x, y, () {
    Expect.isTrue(new File(x).existsSync());
    Expect.isTrue(new File(y).existsSync());
    new File(y).deleteSync();
    Expect.isTrue(new File(x).existsSync());
    Expect.isFalse(new File(y).existsSync());
    createLink(x, y, () {
      Expect.isTrue(new File(x).existsSync());
      Expect.isTrue(new File(y).existsSync());
      new File(y).deleteSync();
      Expect.isTrue(new File(x).existsSync());
      Expect.isFalse(new File(y).existsSync());
      temp.deleteSync(recursive: true);
    });
  });
}


testFileWriteRead() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';
  new File(x).createSync();
  createLink(x, y, () {
    var data = "asdf".codeUnits;
    var output = new File(y).openWrite(mode: FileMode.WRITE);
    output.writeBytes(data);
    output.close();
    output.done.then((_) {
      var read = new File(y).readAsBytesSync();
      Expect.listEquals(data, read);
      var read2 = new File(x).readAsBytesSync();
      Expect.listEquals(data, read2);
      temp.deleteSync(recursive: true);
    });
  });
}


testDirectoryExistsCreate() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';
  createLink(x, y, () {
    Expect.isFalse(new Directory(x).existsSync());
    Expect.isFalse(new Directory(y).existsSync());
    Expect.throws(new Directory(y).createSync);
    temp.deleteSync(recursive: true);
  });
}


testDirectoryDelete() {
  var temp = new Directory('').createTempSync();
  var temp2 = new Directory('').createTempSync();
  var y = '${temp.path}${Platform.pathSeparator}y';
  var x = '${temp2.path}${Platform.pathSeparator}x';
  new File(x).createSync();
  createLink(temp2.path, y, () {
    var link = new Directory(y);
    Expect.isTrue(link.existsSync());
    Expect.isTrue(temp2.existsSync());
    link.deleteSync();
    Expect.isFalse(link.existsSync());
    Expect.isTrue(temp2.existsSync());
    createLink(temp2.path, y, () {
      Expect.isTrue(link.existsSync());
      temp.deleteSync(recursive: true);
      Expect.isFalse(link.existsSync());
      Expect.isTrue(temp2.existsSync());
      Expect.isTrue(new File(x).existsSync());
      temp2.deleteSync(recursive: true);
    });
  });
}


testDirectoryListing() {
  var keepAlive = new ReceivePort();
  var temp = new Directory('').createTempSync();
  var temp2 = new Directory('').createTempSync();
  var y = '${temp.path}${Platform.pathSeparator}y';
  var x = '${temp2.path}${Platform.pathSeparator}x';
  new File(x).createSync();
  createLink(temp2.path, y, () {
    var files = [];
    var dirs = [];
    for (var entry in temp.listSync(recursive:true)) {
      if (entry is File) {
        files.add(entry.path);
      } else {
        Expect.isTrue(entry is Directory);
        dirs.add(entry.path);
      }
    }
    Expect.equals(1, files.length);
    Expect.isTrue(files[0].endsWith('$y${Platform.pathSeparator}x'));
    Expect.equals(1, dirs.length);
    Expect.isTrue(dirs[0].endsWith(y));

    files = [];
    dirs = [];
    var lister = temp.list(recursive: true).listen(
        (entity) {
          if (entity is File) {
            files.add(entity.path);
          } else {
            Expect.isTrue(entity is Directory);
            dirs.add(entity.path);
          }
        },
        onDone: () {
          Expect.equals(1, files.length);
          Expect.isTrue(files[0].endsWith('$y${Platform.pathSeparator}x'));
          Expect.equals(1, dirs.length);
          Expect.isTrue(dirs[0].endsWith(y));
          temp.deleteSync(recursive: true);
          temp2.deleteSync(recursive: true);
          keepAlive.close();
        });
  });
}


testDirectoryListingBrokenLink() {
  var keepAlive = new ReceivePort();
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var link = '${temp.path}${Platform.pathSeparator}link';
  var doesNotExist = 'this_thing_does_not_exist';
  new File(x).createSync();
  createLink(doesNotExist, link, () {
    Expect.throws(() => temp.listSync(recursive: true),
                  (e) => e is DirectoryIOException);
    var files = [];
    var dirs = [];
    var errors = [];
    temp.list(recursive: true).listen(
        (entity) {
          if (entity is File) {
            files.add(entity.path);
          } else {
            Expect.isTrue(entity is Directory);
            dirs.add(entity.path);
          }
        },
        onError: (e) => errors.add(e),
        onDone: () {
          Expect.equals(1, files.length);
          Expect.isTrue(files[0].endsWith(x));
          Expect.equals(0, dirs.length);
          Expect.equals(1, errors.length);
          Expect.isTrue(errors[0].toString().contains(link));
          temp.deleteSync(recursive: true);
          keepAlive.close();
        });
  });
}


main() {
  testFileExistsCreate();
  testFileDelete();
  testFileWriteRead();
  testDirectoryExistsCreate();
  testDirectoryDelete();
  testDirectoryListing();
  testDirectoryListingBrokenLink();
}
