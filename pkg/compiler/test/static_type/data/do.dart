// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  Class next;
}

main() {
  do1(null);
  do2(null);
}

do1(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    do {
      /*dynamic*/ c.next;
      if (/*dynamic*/ c is Class) {
        /*Class*/ c.next;
      }
      c = 0;
    } while (/*dynamic*/ c /*invoke: [dynamic]->bool*/ != null);
    /*dynamic*/ c.next;
  }
}

do2(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    do {
      /*Class*/ c.next;
    } while (/*Class*/ c /*invoke: [Class]->bool*/ != null);
    /*Class*/ c.next;
  }
}
