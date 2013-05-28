// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

testNormalizePath() {
  test(String expected, String path) {
    var uri = new Uri(path: path);
    Expect.equals(expected, uri.path);
    Expect.equals(expected, uri.toString());
  }

  var unreserved = "-._~0123456789"
                   "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                   "abcdefghijklmnopqrstuvwxyz";

  test("A", "%41");
  test("AB", "%41%42");
  test("%40AB", "%40%41%42");
  test("a", "%61");
  test("ab", "%61%62");
  test("%60ab", "%60%61%62");
  test(unreserved, unreserved);

  var x = new StringBuffer();
  for (int i = 32; i < 128; i++) {
    if (unreserved.indexOf(new String.fromCharCode(i)) != -1) {
      x.writeCharCode(i);
    } else {
      x.write("%");
      x.write(i.toRadixString(16));
    }
  }
  print(x.toString().toUpperCase());
  Expect.equals(x.toString().toUpperCase(),
                new Uri(path: x.toString()).toString().toUpperCase());
}

main() {
  testNormalizePath();
}
