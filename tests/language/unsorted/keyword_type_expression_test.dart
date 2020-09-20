// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a keyword can't be used as type.  Serves as regression test for
// crashes in dart2js.

in greeting = "fisk"; // //# 01: syntax error

main(
in greeting // //# 02: syntax error
    ) {
  in greeting = "fisk"; // //# 03: syntax error
  print(greeting); // //# 01: continued
}
