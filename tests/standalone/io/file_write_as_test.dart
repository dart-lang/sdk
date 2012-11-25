// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

testWriteAsBytesSync(dir) {
  var f = new File('${dir.path}/bytes_sync.txt');
  var data = [50,50,50];
  f.writeAsBytesSync(data);
  Expect.listEquals(data, f.readAsBytesSync());
  f.writeAsBytesSync(data, FileMode.APPEND);
  var expected = [50, 50, 50, 50, 50, 50];
  Expect.listEquals(expected, f.readAsBytesSync());
}

testWriteAsStringSync(dir) {
  var f = new File('${dir.path}/string_sync.txt');
  var data = 'asdf';
  f.writeAsStringSync(data);
  Expect.equals(data, f.readAsStringSync());
  f.writeAsStringSync(data, FileMode.APPEND);
  Expect.equals('$data$data', f.readAsStringSync());
}

Future testWriteAsBytes(dir) {
  var completer = new Completer();
  var f = new File('${dir.path}/bytes.txt');
  var data = [50,50,50];
  f.writeAsBytes(data).then((file){
    Expect.equals(f, file);
    f.readAsBytes().then((bytes) {
      Expect.listEquals(data, bytes);
      f.writeAsBytes(data, FileMode.APPEND).then((file) {
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
  f.writeAsString(data).then((file){
    Expect.equals(f, file);
    f.readAsString().then((str) {
      Expect.equals(data, str);
      f.writeAsString(data, FileMode.APPEND).then((file) {
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
  var port = new ReceivePort();
  var tempDir = new Directory('').createTempSync();
  testWriteAsBytesSync(tempDir);
  testWriteAsStringSync(tempDir);
  testWriteAsBytes(tempDir).chain((_) {
    return testWriteAsString(tempDir);
  }).then((_) {
    tempDir.deleteSync(recursive: true);
    port.close();
  });
}
