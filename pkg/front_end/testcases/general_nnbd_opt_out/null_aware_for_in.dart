// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class Class {}

main() {
  var o;
  if (false) {
    // ignore: unused_local_variable
    for (Class c in o?.iterable) {}
  }
}
