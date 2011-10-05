// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("library12.dart", prefix:"lib12");
class Prefix11NegativeTest {
  static Test1() {
    // Symbols in libraries imported by the prefixed library should not be
    // visible here.
    var result = 0;
    var obj = new lib12.Library11(1);
    result = obj.fld;
    Expect.equals(1, result);
    result += obj.func();
    Expect.equals(4, result);
  }
}

main() {
  Prefix11NegativeTest.Test1();
}
