// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We used to always nullify the element type of a list we are tracing in
// the presence of a fixed length list constructor call.

/*member: myList:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSString|powerset={I}{O}{I}], [subclass=JSNumber|powerset={I}{O}{N}], powerset: {I}{O}{IN}), length: null, powerset: {I}{G}{M})*/
var myList = [];

/*member: otherList:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN}), length: 2, powerset: {I}{G}{M})*/
var otherList = ['foo', 42];

/*member: main:[null|powerset={null}]*/
main() {
  dynamic a =
      otherList
      /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN}), length: 2, powerset: {I}{G}{M})*/
      [0];
  a /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ +=
      54;
  myList.
  /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSString|powerset={I}{O}{I}], [subclass=JSNumber|powerset={I}{O}{N}], powerset: {I}{O}{IN}), length: null, powerset: {I}{G}{M})*/
  add(a);
}
