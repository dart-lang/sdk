// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--old_gen_heap_size=512

import "package:expect/expect.dart";

void main() {
  var number_of_ints = 134000000;
  var exception_thrown = false;
  try {
    List<int> buf = new List<int>(number_of_ints);
  } on OutOfMemoryError catch (exc) {
    exception_thrown = true;
  }
  Expect.isTrue(exception_thrown);
}
