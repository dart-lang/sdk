// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Iterable<Class> next;
}

main() {
  forIn1(null);
  forIn2(null);
}

forIn1(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    // ignore: unused_local_variable
    for (var b in /*Class*/ c.next) {
      /*dynamic*/ c.next;
      if (/*dynamic*/ c is Class) {
        /*Class*/ c.next;
      }
      c = 0;
    }
    /*dynamic*/ c.next;
  }
}

forIn2(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    // ignore: unused_local_variable
    for (var b in /*Class*/ c.next) {
      /*Class*/ c.next;
    }
    /*Class*/ c.next;
  }
}
