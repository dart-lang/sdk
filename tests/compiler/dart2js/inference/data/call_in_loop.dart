// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Regression test for [ClosureCallSiteTypeInformation] in loops.

/*member: Class.:[exact=Class]*/
class Class<T> {
  /*member: Class.method:[null]*/
  method() {
    /*iterator: Container([exact=JSExtendableArray], element: [empty], length: 0)*/
    /*current: [exact=ArrayIterator]*/
    /*moveNext: [exact=ArrayIterator]*/
    for (var a in []) {
      (T as dynamic) /*invoke: [exact=_Type]*/ (a);
      (Object as dynamic) /*invoke: [exact=_Type]*/ ();
      (this as dynamic) /*invoke: [exact=Class]*/ ();
      (1 as dynamic) /*invoke: [exact=JSUInt31]*/ ();
    }
  }
}

/*member: main:[null]*/
main() {
  new Class(). /*invoke: [exact=Class]*/ method();
}
