// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:io');


createLink(String dst, String link, bool symbolic, void callback()) {
  var args = [ symbolic ? '-s' : '', dst, link ];
  var script = 'tests/standalone/io/ln.sh';
  if (!new File(script).existsSync()) {
    script = '../$script';
  }
  Process.run(script, args).then((result) {
    if (result.exitCode == 0) {
      callback();
    } else {
      throw new Exception('link creation failed');
    }
  });
}


testFileExistsCreate() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';
  createLink(x, y, true, () {
    Expect.isFalse(new File(x).existsSync());
    Expect.isFalse(new File(y).existsSync());
    new File(y).createSync();
    Expect.isTrue(new File(x).existsSync());
    Expect.isTrue(new File(y).existsSync());
    temp.deleteRecursivelySync();
  });
}


testFileDelete() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';
  new File(x).createSync();
  createLink(x, y, true, () {
    Expect.isTrue(new File(x).existsSync());
    Expect.isTrue(new File(y).existsSync());
    new File(y).deleteSync();
    Expect.isTrue(new File(x).existsSync());
    Expect.isFalse(new File(y).existsSync());
    createLink(x, y, false, () {
      Expect.isTrue(new File(x).existsSync());
      Expect.isTrue(new File(y).existsSync());
      new File(y).deleteSync();
      Expect.isTrue(new File(x).existsSync());
      Expect.isFalse(new File(y).existsSync());
      temp.deleteRecursivelySync();
    });
  });
}


testFileWriteRead() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';
  new File(x).createSync();
  createLink(x, y, true, () {
    var data = "asdf".charCodes;
    var output = new File(y).openOutputStream(FileMode.WRITE);
    output.write(data);
    output.onNoPendingWrites = () {
      output.close();
      var read = new File(y).readAsBytesSync();
      Expect.listEquals(data, read);
      var read2 = new File(x).readAsBytesSync();
      Expect.listEquals(data, read2);
      temp.deleteRecursivelySync();
    };
  });
}


testDirectoryExistsCreate() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var y = '${temp.path}${Platform.pathSeparator}y';
  createLink(x, y, true, () {
    Expect.isFalse(new Directory(x).existsSync());
    Expect.isFalse(new Directory(y).existsSync());
    Expect.throws(new Directory(y).createSync);
    temp.deleteRecursivelySync();
  });
}


testDirectoryDelete() {
  var temp = new Directory('').createTempSync();
  var temp2 = new Directory('').createTempSync();
  var y = '${temp.path}${Platform.pathSeparator}y';
  var x = '${temp2.path}${Platform.pathSeparator}x';
  new File(x).createSync();
  createLink(temp2.path, y, true, () {
    var link = new Directory(y);
    Expect.isTrue(link.existsSync());
    Expect.isTrue(temp2.existsSync());
    link.deleteSync();
    Expect.isFalse(link.existsSync());
    Expect.isTrue(temp2.existsSync());
    createLink(temp2.path, y, true, () {
      Expect.isTrue(link.existsSync());
      temp.deleteRecursivelySync();
      Expect.isFalse(link.existsSync());
      Expect.isTrue(temp2.existsSync());
      Expect.isTrue(new File(x).existsSync());
      temp2.deleteRecursivelySync();
    });
  });
}


testDirectoryListing() {
  var temp = new Directory('').createTempSync();
  var temp2 = new Directory('').createTempSync();
  var y = '${temp.path}${Platform.pathSeparator}y';
  var x = '${temp2.path}${Platform.pathSeparator}x';
  new File(x).createSync();
  createLink(temp2.path, y, true, () {
    var files = [];
    var dirs = [];
    var lister = temp.list(recursive: true);
    lister.onFile = (f) => files.add(f);
    lister.onDir = (d) => dirs.add(d);
    lister.onDone = (success) {
      Expect.isTrue(success);
      Expect.equals(1, files.length);
      Expect.isTrue(files[0].endsWith(x));
      Expect.equals(1, dirs.length);
      Expect.isTrue(dirs[0].endsWith(y));
      temp.deleteRecursivelySync();
      temp2.deleteRecursivelySync();
    };
  });
}


testDirectoryListingBrokenLink() {
  var temp = new Directory('').createTempSync();
  var x = '${temp.path}${Platform.pathSeparator}x';
  var link = '${temp.path}${Platform.pathSeparator}link';
  var doesNotExist = 'this_thing_does_not_exist';
  new File(x).createSync();
  createLink(doesNotExist, link, true, () {
    var files = [];
    var dirs = [];
    var errors = [];
    var lister = temp.list(recursive: true);
    lister.onFile = (f) => files.add(f);
    lister.onDir = (d) => dirs.add(d);
    lister.onError = (d) => errors.add(d);
    lister.onDone = (success) {
      Expect.isFalse(success);
      Expect.equals(1, files.length);
      Expect.isTrue(files[0].endsWith(x));
      Expect.equals(0, dirs.length);
      Expect.equals(1, errors.length);
      Expect.isTrue(errors[0].toString().contains(link));
      temp.deleteRecursivelySync();
    };
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
