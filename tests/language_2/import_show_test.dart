// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library import_show_test;

import "package:expect/expect.dart";
import "import_show_lib.dart" show theEnd;

main() {
  var foo = theEnd;
  Expect.equals("http://www.endoftheinternet.com/", foo);
}
