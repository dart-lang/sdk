// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing File.copy*

import 'dart:io';

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

const FILE_CONTENT1 = 'some string';
const FILE_CONTENT2 = 'some other string';

void testCopySync() {
  var tmp = Directory.systemTemp.createTempSync('dart-file-copy');

  var file1 = new File('${tmp.path}/file1');
  file1.writeAsStringSync(FILE_CONTENT1);
  Expect.equals(FILE_CONTENT1, file1.readAsStringSync());

  // Copy to new file works.
  var file2 = file1.copySync('${tmp.path}/file2');
  Expect.equals(FILE_CONTENT1, file1.readAsStringSync());
  Expect.equals(FILE_CONTENT1, file2.readAsStringSync());

  // Override works for files.
  file2.writeAsStringSync(FILE_CONTENT2);
  file2.copySync(file1.path);
  Expect.equals(FILE_CONTENT2, file1.readAsStringSync());
  Expect.equals(FILE_CONTENT2, file2.readAsStringSync());

  // Fail when coping to directory.
  var dir = new Directory('${tmp.path}/dir')..createSync();
  Expect.throws(() => file1.copySync(dir.path));
  Expect.equals(FILE_CONTENT2, file1.readAsStringSync());

  tmp.deleteSync(recursive: true);
}

void testCopy() {
  asyncStart();
  var tmp = Directory.systemTemp.createTempSync('dart-file-copy');

  var file1 = new File('${tmp.path}/file1');
  file1.writeAsStringSync(FILE_CONTENT1);
  Expect.equals(FILE_CONTENT1, file1.readAsStringSync());

  // Copy to new file works.
  file1.copy('${tmp.path}/file2').then((file2) {
    Expect.equals(FILE_CONTENT1, file1.readAsStringSync());
    Expect.equals(FILE_CONTENT1, file2.readAsStringSync());

    // Override works for files.
    file2.writeAsStringSync(FILE_CONTENT2);
    return file2.copy(file1.path).then((_) {
      Expect.equals(FILE_CONTENT2, file1.readAsStringSync());
      Expect.equals(FILE_CONTENT2, file2.readAsStringSync());

      // Fail when coping to directory.
      var dir = new Directory('${tmp.path}/dir')..createSync();

      return file1
          .copy(dir.path)
          .then((_) => Expect.fail('expected error'), onError: (_) {})
          .then((_) {
        Expect.equals(FILE_CONTENT2, file1.readAsStringSync());
      });
    });
  }).whenComplete(() {
    tmp.deleteSync(recursive: true);
    asyncEnd();
  });
}

main() {
  testCopySync();
  testCopy();
}
