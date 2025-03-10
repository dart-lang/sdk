// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We used to always nullify the element type of a list we are tracing in
// the presence of a fixed length list constructor call.

/*member: myList:Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSString|powerset=0], [subclass=JSNumber|powerset=0], powerset: 0), length: null, powerset: 0)*/
var myList = [];

/*member: otherList:Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: 2, powerset: 0)*/
var otherList = ['foo', 42];

/*member: main:[null|powerset=1]*/
main() {
  dynamic a =
      otherList
      /*Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: 2, powerset: 0)*/
      [0];
  a /*invoke: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ +=
      54;
  myList.
  /*invoke: Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSString|powerset=0], [subclass=JSNumber|powerset=0], powerset: 0), length: null, powerset: 0)*/
  add(a);
}
