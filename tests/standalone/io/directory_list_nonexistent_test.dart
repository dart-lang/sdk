// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory listing test that tests listSync on a missing directory.
//
// TODO(7157): Merge this test into directory_test.dart testListNonExistent()
// when it no longer crashes on Windows, when issue 7157 is resolved.

import "dart:io";
import "dart:isolate";

void testListNonExistent() {
  new Directory("").createTemp().then((d) {
    d.delete().then((ignore) {
      Expect.throws(() => d.listSync(), (e) => e is DirectoryIOException);
      Expect.throws(() => d.listSync(recursive: true),
                    (e) => e is DirectoryIOException);
    });
  });
}

void testListTooLongName() {
  new Directory("").createTemp().then((d) {
    var subDirName = 'subdir';
    var subDir = new Directory("${d.path}/$subDirName");
    subDir.create().then((ignore) {
      // Construct a long string of the form
      // 'tempdir/subdir/../subdir/../subdir'.
      var buffer = new StringBuffer();
      buffer.add(subDir.path);
      for (var i = 0; i < 1000; i++) {
        buffer.add("/../${subDirName}");
      }
      var long = new Directory("${buffer.toString()}");
      Expect.throws(() => long.listSync(),
                    (e) => e is DirectoryIOException);
      Expect.throws(() => long.listSync(recursive: true),
                    (e) => e is DirectoryIOException);
    });
  });
}

void main() {
  testListNonExistent();
  testListTooLongName();
}
