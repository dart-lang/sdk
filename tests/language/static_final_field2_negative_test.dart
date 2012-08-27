// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Disallow re-assignment of a final static variable.

class A {
  static const x = 1;
}

main() {
  A.x = 2;  // <- reassignment not allowed.
}
