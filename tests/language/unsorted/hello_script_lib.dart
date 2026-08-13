// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing a simple script importing a library.
// This file contains the library.

library HelloScriptLib;

import "package:expect/expect.dart";
part "hello_script_lib_source.dart";

class HelloLib {
  static doTest() {
    x = 17;
    Expect.equals(17, x++);
    print("Hello from Lib!");
  }
}
