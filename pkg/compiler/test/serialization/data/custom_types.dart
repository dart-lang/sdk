// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  method() {
    Object c = this;
    return c;
  }
}

main() {
  exactInterfaceType();
  thisInterfaceType();
  doesNotCompleteType();
}

exactInterfaceType() {
  Object c = A();
  return c;
}

thisInterfaceType() {
  A().method();
}

doesNotCompleteType() {
  Object c = throw '';
  // ignore: dead_code
  return c;
}
