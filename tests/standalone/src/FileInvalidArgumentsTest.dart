// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FileTest {
  static void testOpenInvalidArgs(name, [writable = false]) {
    var file = new File(name);
    try {
      file.openSync();
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('open file'));
    }

    file.errorHandler = (s) {
      Expect.isTrue(s.contains('open file'));
    };
    file.openHandler = () {
      Expect.fail('non-string name open');
    };
    file.open();
  }

  static void testExistsInvalidArgs(name) {
    var file = new File(name);
    try {
      file.existsSync();
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('is not a string'));
    }

    file.errorHandler = (s) {
      Expect.isTrue(s.contains('is not a string'));
    };
    file.existsHandler = (bool) {
      Expect.fail('non-string name exists');
    };
    file.exists();
  }

  static void testCreateInvalidArgs(name) {
    var file = new File(name);
    try {
      file.createSync();
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('Cannot create file'));
    }

    file.errorHandler = (s) {
      Expect.isTrue(s.contains('Cannot create file'));
    };
    file.createHandler = (created) {
      Expect.fail('non-string name exists');
    };
    file.create();
  }

  static void testCloseNonOpened() {
    var file = new File(0);
    try {
      file.closeSync();
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('Cannot close file'));
    }

    file.errorHandler = (s) {
      Expect.isTrue(s.contains('Cannot close file'));
    };
    file.closeHandler = () {
      Expect.fail('close non-opened file');
    };
    file.close();
  }

  static void testReadListInvalidArgs(buffer, offset, length) {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    var file = new File(filename);
    file.openSync();
    try {
      file.readListSync(buffer, offset, length);
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('Invalid arguments'));
    }

    var errors = 0;
    file.errorHandler = (s) {
      errors++;
      Expect.isTrue(s.contains('Invalid arguments'));
    };
    file.readListHandler = (bytes) {
      Expect.fail('read list invalid arguments');
    };
    file.readList(buffer, offset, length);
    file.closeHandler = () {
      Expect.equals(1, errors);
    };
    file.close();
  }

  static void testWriteByteInvalidArgs(value) {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    var file = new File(filename + "_out");
    file.openSync(true);
    try {
      file.writeByteSync(value);
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('Invalid argument'));
    }

    var errors = 0;
    file.errorHandler = (s) {
      errors++;
      Expect.isTrue(s.contains('Invalid argument'));
    };
    file.noPendingWriteHandler = (bytes) {
      Expect.fail('write list invalid argument');
    };
    file.writeByte(value);
    file.closeHandler = () {
      Expect.equals(1, errors);
    };
    file.close();
  }

  static void testWriteListInvalidArgs(buffer, offset, bytes) {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    var file = new File(filename + "_out");
    file.openSync(true);
    try {
      file.writeListSync(buffer, offset, bytes);
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('Invalid arguments'));
    }

    var errors = 0;
    file.errorHandler = (s) {
      errors++;
      Expect.isTrue(s.contains('Invalid arguments'));
    };
    file.noPendingWriteHandler = (bytes) {
      Expect.fail('write list invalid argument');
    };
    file.writeList(buffer, offset, bytes);
    file.closeHandler = () {
      Expect.equals(1, errors);
    };
    file.close();
  }

  static void testWriteStringInvalidArgs(string) {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    var file = new File(filename + "_out");
    file.openSync(true);
    try {
      file.writeString(string);
      Expect.fail('exception expected');
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('writeString failed'));
    }

    var errors = 0;
    file.errorHandler = (s) {
      errors++;
      Expect.isTrue(s.contains('writeString failed'));
    };
    file.noPendingWriteHandler = (bytes) {
      Expect.fail('write string invalid argument');
    };
    file.writeString(string);
    file.closeHandler = () {
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
      Expect.isTrue(e is FileIOException);
      Expect.isTrue(e.toString().contains('fullPath failed'));
    }

    file.errorHandler = (s) {
      Expect.isTrue(s.contains('fullPath failed'));
    };
    file.fullPathHandler = (path) {
      Expect.fail('full path invalid argument');
    };
    file.fullPath();
  }

  static String getFilename(String path) =>
      new File(path).existsSync() ? path : 'runtime/' + path;
}

main() {
  FileTest.testOpenInvalidArgs(0);
  FileTest.testOpenInvalidArgs('name', 0);
  FileTest.testExistsInvalidArgs(0);
  FileTest.testCreateInvalidArgs(0);
  FileTest.testCloseNonOpened();
  FileTest.testReadListInvalidArgs(12, 0, 1);
  FileTest.testReadListInvalidArgs(new List(10), '0', 1);
  FileTest.testReadListInvalidArgs(new List(10), 0, '1');
  FileTest.testWriteByteInvalidArgs('asdf');
  FileTest.testWriteListInvalidArgs(12, 0, 1);
  FileTest.testWriteListInvalidArgs(new List(10), '0', 1);
  FileTest.testWriteListInvalidArgs(new List(10), 0, '1');
  FileTest.testFullPathInvalidArgs(12);
}
