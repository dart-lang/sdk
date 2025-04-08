// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for [ClosureCallSiteTypeInformation] in loops.

/*member: Class.:[exact=Class|powerset=0]*/
class Class<T> {
  /*member: Class.method:[null|powerset=1]*/
  method() {
    /*iterator: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)*/
    /*current: [exact=ArrayIterator|powerset=0]*/
    /*moveNext: [exact=ArrayIterator|powerset=0]*/
    for (var a in []) {
      (T as dynamic) /*invoke: [exact=_Type|powerset=0]*/ (a);
      (Object as dynamic) /*invoke: [exact=_Type|powerset=0]*/ ();
      (this as dynamic) /*invoke: [exact=Class|powerset=0]*/ ();
      (1 as dynamic) /*invoke: [exact=JSUInt31|powerset=0]*/ ();
    }
  }
}

/*member: main:[null|powerset=1]*/
main() {
  Class(). /*invoke: [exact=Class|powerset=0]*/ method();
}
