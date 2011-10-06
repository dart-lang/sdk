// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#library("Prefix12NegativeTest.dart");
#import("library12.dart", prefix:"lib12");

class Prefix12NegativeTest {
  static Test1() {
    // Symbols in libraries imported by the prefixed library should not be
    // visible here.
    var obj = lib12.top_level11;
    Expect.equals(100, obj);
  }
}

main() {
  Prefix12NegativeTest.Test1();
}
