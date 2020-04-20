// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  Class next;
}

main() {
  if1(null, null);
  if2(null, null);
  if3(null, null);
}

if1(dynamic c1, dynamic c2) {
  /*dynamic*/ c1.next;
  /*dynamic*/ c2.next;
  if (/*dynamic*/ c1 is Class) {
    /*Class*/ c1.next;
    /*dynamic*/ c2.next;
    if (/*dynamic*/ c2 is Class) {
      /*Class*/ c1.next;
      /*Class*/ c2.next;
    } else {
      /*Class*/ c1.next;
      /*dynamic*/ c2.next;
    }
  } else {
    /*dynamic*/ c1.next;
    /*dynamic*/ c2.next;
    if (/*dynamic*/ c2 is Class) {
      /*dynamic*/ c1.next;
      /*Class*/ c2.next;
    } else {
      /*dynamic*/ c1.next;
      /*dynamic*/ c2.next;
    }
  }
}

if2(Class c1, Class c2) {
  /*Class*/ c1.next;
  /*Class*/ c2.next;
  if (/*Class*/ c1 is Class) {
    /*Class*/ c1.next;
    /*Class*/ c2.next;
    if (/*Class*/ c2 is Class) {
      /*Class*/ c1.next;
      /*Class*/ c2.next;
    } else {
      /*Class*/ c1.next;
      /*Null*/ c2.next;
    }
  } else {
    /*Null*/ c1.next;
    /*Class*/ c2.next;
    if (/*Class*/ c2 is Class) {
      /*Null*/ c1.next;
      /*Class*/ c2.next;
    } else {
      /*Null*/ c1.next;
      /*Null*/ c2.next;
    }
  }
}

if3(dynamic c1, dynamic c2) {
  /*dynamic*/ c1.next;
  /*dynamic*/ c2.next;
  if (/*dynamic*/ c1 is! Class) {
    /*dynamic*/ c1.next;
    /*dynamic*/ c2.next;
    if (/*dynamic*/ c2 is! Class) {
      /*dynamic*/ c1.next;
      /*dynamic*/ c2.next;
    } else {
      /*dynamic*/ c1.next;
      /*Class*/ c2.next;
    }
  } else {
    /*Class*/ c1.next;
    /*dynamic*/ c2.next;
    if (/*dynamic*/ c2 is! Class) {
      /*Class*/ c1.next;
      /*dynamic*/ c2.next;
    } else {
      /*Class*/ c1.next;
      /*Class*/ c2.next;
    }
  }
}
