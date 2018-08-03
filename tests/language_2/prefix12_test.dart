// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

library Prefix12Test.dart;

import "package:expect/expect.dart";
import "library11.dart" as lib11;

class Prefix12Test {
  static Test1() {
    var result = 0;
    var obj = new lib11.Library11.namedConstructor(10);
    result = obj.fld;
    Expect.equals(10, result);
  }

  static Test2() {
    int result = 0;
    var obj = new lib11.Library111<int>.namedConstructor(10);
    result = obj.fld;
    Expect.equals(10, result);
  }
}

main() {
  Prefix12Test.Test1();
  Prefix12Test.Test2();
}
