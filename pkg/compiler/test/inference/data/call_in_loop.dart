// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for [ClosureCallSiteTypeInformation] in loops.

/*member: Class.:[exact=Class|powerset={N}]*/
class Class<T> {
  /*member: Class.method:[null|powerset={null}]*/
  method() {
    /*iterator: Container([exact=JSExtendableArray|powerset={I}], element: [empty|powerset=empty], length: 0, powerset: {I})*/
    /*current: [exact=ArrayIterator|powerset={N}]*/
    /*moveNext: [exact=ArrayIterator|powerset={N}]*/
    for (var a in []) {
      (T as dynamic) /*invoke: [exact=_Type|powerset={N}]*/ (a);
      (Object as dynamic) /*invoke: [exact=_Type|powerset={N}]*/ ();
      (this as dynamic) /*invoke: [exact=Class|powerset={N}]*/ ();
      (1 as dynamic) /*invoke: [exact=JSUInt31|powerset={I}]*/ ();
    }
  }
}

/*member: main:[null|powerset={null}]*/
main() {
  Class(). /*invoke: [exact=Class|powerset={N}]*/ method();
}
