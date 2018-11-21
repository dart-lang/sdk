// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class next;
}

main() {
  assert1(null);
}

assert1(Class c) {
  bool b;
  assert(/*Class*/ c /*invoke: bool*/ != null);
  if (/*bool*/ b) return;
  /*Class*/ c.next;
}
