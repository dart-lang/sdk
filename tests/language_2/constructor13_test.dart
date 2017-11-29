// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that there's no crash when constructor called with wrong
// number of args.

class Klass {
  Klass(v) {}
}

main() {
  new Klass(); //# 01: compile-time error
  new Klass(1);
  new Klass(1, 2); //# 02: compile-time error
}
