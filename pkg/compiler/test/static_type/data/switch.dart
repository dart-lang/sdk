// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  Class next;
}

main() {
  switch1(null);
  switch2(null);
  switch3(null);
}

switch1(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    switch (/*Class*/ c) {
      label:
      case 0:
        /*dynamic*/ c.next;
        break;
      case 1:
        /*dynamic*/ c.next;
        if (/*dynamic*/ c is Class) {
          /*Class*/ c.next;
        }
        c = 0;
        continue label;
    }
    /*dynamic*/ c.next;
  }
}

switch2(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    switch (/*Class*/ c) {
      case 0:
        /*Class*/ c.next;
        break;
      case 1:
        /*Class*/ c.next;
        c = 0;
        break;
    }
    /*dynamic*/ c.next;
  }
}

switch3(dynamic c) {
  /*dynamic*/ c.next;
  switch (/*dynamic*/ c) {
    case 0:
      if (/*dynamic*/ c is! Class) return;
      /*Class*/ c.next;
      break;
    case 1:
      /*dynamic*/ c.next;
      break;
  }
  /*dynamic*/ c.next;
}
