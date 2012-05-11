// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

class FileTest {
  static void testOpenInvalidArgs(name) {
    var file = new File(name);
    try {
      file.openSync();
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is IllegalArgumentException);
    }

    var openFuture = file.open(FileMode.READ);
    openFuture.handleException((e) {
      Expect.isTrue(e is IllegalArgumentException);
      return true;
    });
    openFuture.then((opened) {
      Expect.fail('non-string name open');
    });
  }

  static void testExistsInvalidArgs(name) {
    var file = new File(name);
    try {
      file.existsSync();
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is IllegalArgumentException);
    }

    var existsFuture = file.exists();
    existsFuture.handleException((e) {
      Expect.isTrue(e is IllegalArgumentException);
      return true;
    });
    existsFuture.then((bool) {
      Expect.fail('non-string name exists');
    });
  }

  static void testCreateInvalidArgs(name) {
    var file = new File(name);
    try {
      file.createSync();
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is IllegalArgumentException);
    }

    var createFuture = file.create();
    createFuture.handleException((e) {
      Expect.isTrue(e is IllegalArgumentException);
      return true;
    });
    createFuture.then((ignore) => Expect.fail('non-string name exists'));
  }

  static void testReadListInvalidArgs(buffer, offset, length) {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    var file = (new File(filename)).openSync();
    try {
      file.readListSync(buffer, offset, length);
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('Invalid arguments'));
    }

    var errors = 0;
    var readListFuture = file.readList(buffer, offset, length);
    readListFuture.handleException((e) {
      errors++;
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('Invalid arguments'));
      file.close().then((ignore) {
        Expect.equals(1, errors);
      });
      return true;
    });
    readListFuture.then((bytes) {
      Expect.fail('read list invalid arguments');
    });
  }

  static void testWriteByteInvalidArgs(value) {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    var file = (new File(filename + "_out")).openSync(FileMode.WRITE);
    try {
      file.writeByteSync(value);
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('Invalid argument'));
    }

    var writeByteFuture = file.writeByte(value);
    writeByteFuture.then((ignore) {
      Expect.fail('write byte invalid argument');
    });
    writeByteFuture.handleException((s) {
      Expect.isTrue(s is FileIOException);
      Expect.isTrue(s.toString().contains('Invalid argument'));
      file.close();
      return true;
    });
  }

  static void testWriteListInvalidArgs(buffer, offset, bytes) {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    var file = (new File(filename + "_out")).openSync(FileMode.WRITE);
    try {
      file.writeListSync(buffer, offset, bytes);
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('Invalid arguments'));
    }

    var writeListFuture = file.writeList(buffer, offset, bytes);
    writeListFuture.then((ignore) {
      Expect.fail('write list invalid argument');
    });
    writeListFuture.handleException((s) {
      Expect.isTrue(s is FileIOException);
      Expect.isTrue(s.toString().contains('Invalid arguments'));
      file.close();
      return true;
    });
  }

  static void testWriteStringInvalidArgs(string) {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    var file = new File(filename + "_out");
    file.openSync(FileMode.WRITE);
    try {
      file.writeString(string);
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('writeString failed'));
    }

    var errors = 0;
    file.onError = (s) {
      errors++;
      Expect.isTrue(s.contains('writeString failed'));
    };
    var calls = 0;
    file.onNoPendingWrites = () {
      if (++calls > 1) Expect.fail('write list invalid argument');
    };
    file.writeString(string);
    file.onClosed = () {
      Expect.equals(1, errors);
    };
    file.close();
  }

  static void testFullPathInvalidArgs(name) {
    var file = new File(name);
    try {
      file.fullPathSync();
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is IllegalArgumentException);
    }

    var fullPathFuture = file.fullPath();
    fullPathFuture.handleException((e) {
      Expect.isTrue(e is IllegalArgumentException);
      return true;
    });
    fullPathFuture.then((path) {
      Expect.fail('full path invalid argument');
    });
  }

  static String getFilename(String path) =>
      new File(path).existsSync() ? path : 'runtime/' + path;
}

main() {
  FileTest.testOpenInvalidArgs(0);
  FileTest.testExistsInvalidArgs(0);
  FileTest.testCreateInvalidArgs(0);
  FileTest.testReadListInvalidArgs(12, 0, 1);
  FileTest.testReadListInvalidArgs(new List(10), '0', 1);
  FileTest.testReadListInvalidArgs(new List(10), 0, '1');
  FileTest.testWriteByteInvalidArgs('asdf');
  FileTest.testWriteListInvalidArgs(12, 0, 1);
  FileTest.testWriteListInvalidArgs(new List(10), '0', 1);
  FileTest.testWriteListInvalidArgs(new List(10), 0, '1');
  FileTest.testFullPathInvalidArgs(12);
}
