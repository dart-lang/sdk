// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";

void testReadInvalidArgs(arg) {
  var port = new ReceivePort();
  String filename = getFilename("tests/vm/data/fixed_length_file");
  var file = (new File(filename)).openSync();
  try {
    file.readSync(arg);
    Expect.fail('exception expected');
  } catch (e) {
    Expect.isTrue(e is FileIOException);
    Expect.isTrue(e.toString().contains('Invalid arguments'));
  }

  var errors = 0;
  var readFuture = file.read(arg);
  readFuture.then((bytes) {
    Expect.fail('exception expected');
  }).catchError((e) {
    errors++;
    Expect.isTrue(e.error is FileIOException);
    Expect.isTrue(e.error.toString().contains('Invalid arguments'));
    file.close().then((ignore) {
      Expect.equals(1, errors);
      port.close();
    });
  });
}

void testReadListInvalidArgs(buffer, offset, length) {
  var port = new ReceivePort();
  String filename = getFilename("tests/vm/data/fixed_length_file");
  var file = (new File(filename)).openSync();
  try {
    file.readListSync(buffer, offset, length);
    Expect.fail('exception expected');
  } catch (e) {
    Expect.isTrue(e is FileIOException);
    Expect.isTrue(e.toString().contains('Invalid arguments'));
  }

  var errors = 0;
  var readListFuture = file.readList(buffer, offset, length);
  readListFuture.then((bytes) {
    Expect.fail('exception expected');
  }).catchError((e) {
    errors++;
    Expect.isTrue(e.error is FileIOException);
    Expect.isTrue(e.error.toString().contains('Invalid arguments'));
    file.close().then((ignore) {
      Expect.equals(1, errors);
      port.close();
    });
  });
}

void testWriteByteInvalidArgs(value) {
  var port = new ReceivePort();
  String filename = getFilename("tests/vm/data/fixed_length_file");
  var file = (new File(filename.concat("_out"))).openSync(FileMode.WRITE);
  try {
    file.writeByteSync(value);
    Expect.fail('exception expected');
  } catch (e) {
    Expect.isTrue(e is FileIOException);
    Expect.isTrue(e.toString().contains('Invalid argument'));
  }

  var writeByteFuture = file.writeByte(value);
  writeByteFuture.then((ignore) {
    Expect.fail('exception expected');
  }).catchError((s) {
    Expect.isTrue(s.error is FileIOException);
    Expect.isTrue(s.error.toString().contains('Invalid argument'));
    file.close().then((ignore) {
      port.close();
    });
  });
}

void testWriteListInvalidArgs(buffer, offset, bytes) {
  var port = new ReceivePort();
  String filename = getFilename("tests/vm/data/fixed_length_file");
  var file = (new File(filename.concat("_out"))).openSync(FileMode.WRITE);
  try {
    file.writeListSync(buffer, offset, bytes);
    Expect.fail('exception expected');
  } catch (e) {
    Expect.isTrue(e is FileIOException);
    Expect.isTrue(e.toString().contains('Invalid arguments'));
  }

  var writeListFuture = file.writeList(buffer, offset, bytes);
  writeListFuture.then((ignore) {
    Expect.fail('exception expected');
  }).catchError((s) {
    Expect.isTrue(s.error is FileIOException);
    Expect.isTrue(s.error.toString().contains('Invalid arguments'));
    file.close().then((ignore) {
      port.close();
    });
  });
}

void testWriteStringInvalidArgs(string) {
  var port = new ReceivePort();
  String filename = getFilename("tests/vm/data/fixed_length_file");
  var file = new File(filename.concat("_out"));
  file.openSync(FileMode.WRITE);
  try {
    file.writeString(string);
    Expect.fail('exception expected');
  } catch (e) {
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
    port.close();
  };
  file.close();
}

String getFilename(String path) {
  return new File(path).existsSync() ? path : 'runtime/$path';
}

main() {
  testReadInvalidArgs('asdf');
  testReadListInvalidArgs(12, 0, 1);
  testReadListInvalidArgs(new List.fixedLength(10), '0', 1);
  testReadListInvalidArgs(new List.fixedLength(10), 0, '1');
  testWriteByteInvalidArgs('asdf');
  testWriteListInvalidArgs(12, 0, 1);
  testWriteListInvalidArgs(new List.fixedLength(10), '0', 1);
  testWriteListInvalidArgs(new List.fixedLength(10), 0, '1');
}
