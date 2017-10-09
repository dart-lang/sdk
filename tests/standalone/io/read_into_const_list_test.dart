// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=readline_test1.dat

// Regression test for missing immutability check in the ListSet
// methods in the API. This allowed overwriting const Lists.

import "package:expect/expect.dart";
import "dart:io";

String getFilename(String path) {
  return Platform.script.resolve(path).toFilePath();
}

void main() {
  var a = const [0];
  var b = const [0];
  Expect.identical(a, b);

  String filename = getFilename("readline_test1.dat");
  File file = new File(filename);
  file.open().then((input) {
    try {
      input.readIntoSync(a, 0, 1);
      Expect.fail("no exception thrown");
    } catch (e) {
      Expect.isTrue(e is UnsupportedError);
    }
    Expect.equals(0, a[0]);
    Expect.equals(0, b[0]);
    input.closeSync();
  });
}
