// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for [ClosureCallSiteTypeInformation] in loops.

/*member: Class.:[exact=Class|powerset={N}{O}{N}]*/
class Class<T> {
  /*member: Class.method:[null|powerset={null}]*/
  method() {
    /*iterator: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})*/
    /*current: [exact=ArrayIterator|powerset={N}{O}{N}]*/
    /*moveNext: [exact=ArrayIterator|powerset={N}{O}{N}]*/
    for (var a in []) {
      (T as dynamic) /*invoke: [exact=_Type|powerset={N}{O}{N}]*/ (a);
      (Object as dynamic) /*invoke: [exact=_Type|powerset={N}{O}{N}]*/ ();
      (this as dynamic) /*invoke: [exact=Class|powerset={N}{O}{N}]*/ ();
      (1 as dynamic) /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ();
    }
  }
}

/*member: main:[null|powerset={null}]*/
main() {
  Class(). /*invoke: [exact=Class|powerset={N}{O}{N}]*/ method();
}
