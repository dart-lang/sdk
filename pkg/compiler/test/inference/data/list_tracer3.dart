// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We used to always nullify the element type of a list we are tracing in
// the presence of a fixed length list constructor call.

/*member: myList:Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSString|powerset={I}], [subclass=JSNumber|powerset={I}], powerset: {I}), length: null, powerset: {I})*/
var myList = [];

/*member: otherList:Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: 2, powerset: {I})*/
var otherList = ['foo', 42];

/*member: main:[null|powerset={null}]*/
main() {
  dynamic a =
      otherList
      /*Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: 2, powerset: {I})*/
      [0];
  a /*invoke: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ +=
      54;
  myList.
  /*invoke: Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSString|powerset={I}], [subclass=JSNumber|powerset={I}], powerset: {I}), length: null, powerset: {I})*/
  add(a);
}
