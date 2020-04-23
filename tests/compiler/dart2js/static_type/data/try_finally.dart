// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  Iterable<Class> next;
}

main() {
  tryFinally1(null);
  tryFinally2(null);
}

tryFinally1(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    try {
      /*Class*/ c.next;
      c = 0;
      if (/*dynamic*/ c is Class) {
        /*Class*/ c.next;
      }
    } finally {
      /*dynamic*/ c.next;
    }
    /*dynamic*/ c.next;
  }
}

tryFinally2(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    try {
      /*Class*/ c.next;
    } finally {
      /*Class*/ c.next;
    }
    /*Class*/ c.next;
  }
}
