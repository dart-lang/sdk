// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

testWriteAsBytesSync(dir) {
  var f = new File('${dir.path}/bytes_sync.txt');
  var data = [50, 50, 50];
  f.writeAsBytesSync(data);
  Expect.listEquals(data, f.readAsBytesSync());
  f.writeAsBytesSync(data, mode: FileMode.append, flush: true);
  var expected = [50, 50, 50, 50, 50, 50];
  Expect.listEquals(expected, f.readAsBytesSync());
}

testWriteAsStringSync(dir) {
  var f = new File('${dir.path}/string_sync.txt');
  var data = 'asdf';
  f.writeAsStringSync(data);
  Expect.equals(data, f.readAsStringSync());
  f.writeAsStringSync(data, mode: FileMode.append, flush: true);
  Expect.equals('$data$data', f.readAsStringSync());
}

testWriteWithLargeList(dir) {
  // 0x100000000 exceeds the maximum of unsigned long.
  // This should no longer hang.
  // Issue: https://github.com/dart-lang/sdk/issues/40339
  var bytes;
  try {
    bytes = Uint8List(0x100000000);
  } catch (e) {
    // Create a big Uint8List may lead to OOM. This is acceptable.
    Expect.isTrue(e.toString().contains('Out of Memory'));
    return;
  }
  if (Platform.isWindows) {
    File('NUL').writeAsBytesSync(bytes);
  } else {
    File('/dev/null').writeAsBytesSync(bytes);
  }
}

Future testWriteAsBytes(dir) {
  var completer = new Completer();
  var f = new File('${dir.path}/bytes.txt');
  var data = [50, 50, 50];
  f.writeAsBytes(data).then((file) {
    Expect.equals(f, file);
    f.readAsBytes().then((bytes) {
      Expect.listEquals(data, bytes);
      f.writeAsBytes(data, mode: FileMode.append, flush: true).then((file) {
        Expect.equals(f, file);
        f.readAsBytes().then((bytes) {
          var expected = [50, 50, 50, 50, 50, 50];
          Expect.listEquals(expected, bytes);
          completer.complete(true);
        });
      });
    });
  });
  return completer.future;
}

Future testWriteAsString(dir) {
  var completer = new Completer();
  var f = new File('${dir.path}/strings.txt');
  var data = 'asdf';
  f.writeAsString(data).then((file) {
    Expect.equals(f, file);
    f.readAsString().then((str) {
      Expect.equals(data, str);
      f.writeAsString(data, mode: FileMode.append, flush: true).then((file) {
        Expect.equals(f, file);
        f.readAsString().then((str) {
          Expect.equals('$data$data', str);
          completer.complete(true);
        });
      });
    });
  });
  return completer.future;
}

main() {
  asyncStart();
  var tempDir = Directory.systemTemp.createTempSync('dart_file_write_as');
  testWriteAsBytesSync(tempDir);
  testWriteAsStringSync(tempDir);
  testWriteWithLargeList(tempDir);
  testWriteAsBytes(tempDir).then((_) {
    return testWriteAsString(tempDir);
  }).then((_) {
    tempDir.deleteSync(recursive: true);
    asyncEnd();
  });
}
