// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  var number_of_ints = 134000000;
  var exception_thrown = false;
  try {
    List<int> buf = new List<int>(number_of_ints);
  } catch (OutOfMemoryException exc) {
    exception_thrown = true;
  }
  Expect.isTrue(exception_thrown);
}
