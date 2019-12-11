// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var trace = "";

main() {
  var x = 0;
  try {
    try {
      throw x++; // 1
    } on int catch (e) {
      trace += "$e";
      trace += "-$x";
      x++; // 2
      try {
        x++; // 3
        rethrow;
      } finally {
        trace += "-f";
        x++; // 4
      }
    }
  } catch (e) {
    trace += "-c";
    trace += "-$e";
    trace += "-$x";
  }
  Expect.equals("0-1-f-c-0-4", trace);
}
