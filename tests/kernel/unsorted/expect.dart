// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

// We use this class until we support more language features to use
// `package:expect`.
class Expect {
  static void isTrue(bool condition) {
    if (!condition) {
      print("Expect.isTrue(cond) failed. io.exit(1)ing");
      io.exit(1);
    }
  }
}
