// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for missing immutability check in the ListSet
// methods in the API. This allowed overwriting const Lists.

#import("dart:io");

String getFilename(String path) =>
    new File(path).existsSync() ? path : 'runtime/' + path;

void main() {
  var a = const [0];
  var b = const [0];
  Expect.isTrue(a === b);

  String filename = getFilename("bin/file_test.cc");
  File file = new File(filename);
  InputStream input = file.openInputStream();
  try {
    input.readInto(a, 0, 1);
    Expect.fail("no exception thrown");
  } catch (var e) {
    Expect.isTrue(e is UnsupportedOperationException);
  }
  Expect.equals(0, a[0]);
  Expect.equals(0, b[0]);
}
