// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  Class next;
}

main() {
  null1(null);
  null2(null);
  null3(null);
  null4(null);
  null5(null);
  null6(null);
  null7(null);
  null8(null);
}

null1(dynamic c) {
  /*dynamic*/ c.next;
  /*dynamic*/ c /*invoke: [dynamic]->bool*/ != null;
  /*dynamic*/ c.next;
}

null2(dynamic c) {
  /*dynamic*/ c.next;
  /*dynamic*/ c /*invoke: [dynamic]->bool*/ == null;
  /*dynamic*/ c.next;
}

null3(dynamic c) {
  if (/*dynamic*/ c /*invoke: [dynamic]->bool*/ == null) return;
  /*dynamic*/ c.next;
}

null4(dynamic c) {
  if (/*dynamic*/ c /*invoke: [dynamic]->bool*/ != null) return;
  /*Null*/ c.next;
}

null5(dynamic c) {
  if (/*dynamic*/ c /*invoke: [dynamic]->bool*/ != null) {
    /*dynamic*/ c.next;
  }
}

null6(dynamic c) {
  if (/*dynamic*/ c /*invoke: [dynamic]->bool*/ == null) {
    /*Null*/ c.next;
  }
}

null7(dynamic c) {
  while (/*dynamic*/ c /*invoke: [dynamic]->bool*/ != null) {
    /*dynamic*/ c.next;
  }
}

null8(dynamic c) {
  while (/*dynamic*/ c /*invoke: [dynamic]->bool*/ == null) {
    /*Null*/ c.next;
  }
}
