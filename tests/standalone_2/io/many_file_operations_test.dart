// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing using a lot of native port operations.

import "dart:io";

main() {
  for (var i = 0; i < 10000; i++) {
    File f = new File("xxx");
    f.exists().then((result) => null);
  }
}
