// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
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
  }).catchError((error) {
    errors++;
    Expect.isTrue(error is FileIOException);
    Expect.isTrue(error.toString().contains('Invalid arguments'));
    file.close().then((ignore) {
      Expect.equals(1, errors);
      port.close();
    });
  });
}

void testReadIntoInvalidArgs(buffer, start, end) {
  var port = new ReceivePort();
  String filename = getFilename("tests/vm/data/fixed_length_file");
  var file = (new File(filename)).openSync();
  try {
    file.readIntoSync(buffer, start, end);
    Expect.fail('exception expected');
  } catch (e) {
    Expect.isTrue(e is FileIOException);
    Expect.isTrue(e.toString().contains('Invalid arguments'));
  }

  var errors = 0;
  var readIntoFuture = file.readInto(buffer, start, end);
  readIntoFuture.then((bytes) {
    Expect.fail('exception expected');
  }).catchError((error) {
    errors++;
    Expect.isTrue(error is FileIOException);
    Expect.isTrue(error.toString().contains('Invalid arguments'));
    file.close().then((ignore) {
      Expect.equals(1, errors);
      port.close();
    });
  });
}

void testWriteByteInvalidArgs(value) {
  var port = new ReceivePort();
  String filename = getFilename("tests/vm/data/fixed_length_file");
  var file = (new File("${filename}_out")).openSync(mode: FileMode.WRITE);
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
  }).catchError((error) {
    Expect.isTrue(error is FileIOException);
    Expect.isTrue(error.toString().contains('Invalid argument'));
    file.close().then((ignore) {
      port.close();
    });
  });
}

void testWriteFromInvalidArgs(buffer, start, end) {
  var port = new ReceivePort();
  String filename = getFilename("tests/vm/data/fixed_length_file");
  var file = (new File("${filename}_out")).openSync(mode: FileMode.WRITE);
  try {
    file.writeFromSync(buffer, start, end);
    Expect.fail('exception expected');
  } catch (e) {
    Expect.isTrue(e is FileIOException);
    Expect.isTrue(e.toString().contains('Invalid arguments'));
  }

  var writeFromFuture = file.writeFrom(buffer, start, end);
  writeFromFuture.then((ignore) {
    Expect.fail('exception expected');
  }).catchError((error) {
    Expect.isTrue(error is FileIOException);
    Expect.isTrue(error.toString().contains('Invalid arguments'));
    file.close().then((ignore) {
      port.close();
    });
  });
}

void testWriteStringInvalidArgs(string, encoding) {
  var port = new ReceivePort();
  String filename = getFilename("tests/vm/data/fixed_length_file");
  var file = new File("${filename}_out").openSync(mode: FileMode.WRITE);
  try {
    file.writeStringSync(string, encoding: encoding);
    Expect.fail('exception expected');
  } catch (e) {
    Expect.isTrue(e is FileIOException);
  }

  var writeStringFuture = file.writeString(string, encoding: encoding);
  writeStringFuture.then((ignore) {
    Expect.fail('exception expected');
  }).catchError((error) {
    Expect.isTrue(error is FileIOException);
    file.close().then((ignore) {
      port.close();
    });
  });
}

String getFilename(String path) {
  return new File(path).existsSync() ? path : 'runtime/$path';
}

main() {
  testReadInvalidArgs('asdf');
  testReadIntoInvalidArgs(12, 0, 1);
  testReadIntoInvalidArgs(new List(10), '0', 1);
  testReadIntoInvalidArgs(new List(10), 0, '1');
  testWriteByteInvalidArgs('asdf');
  testWriteFromInvalidArgs(12, 0, 1);
  testWriteFromInvalidArgs(new List(10), '0', 1);
  testWriteFromInvalidArgs(new List(10), 0, '1');
  testWriteStringInvalidArgs("Hello, world", 42);
}
