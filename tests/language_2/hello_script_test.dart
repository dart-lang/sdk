#! This is currently only a comment.
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing a simple script importing a library.
// This file contains the script (aka root library).

library HelloScriptTest.dart;

import "package:expect/expect.dart";
import "hello_script_lib.dart";

main() {
  HelloLib.doTest();
  Expect.equals(18, x);
  print("Hello done.");
}
