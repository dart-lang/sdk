// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// We used to always nullify the element type of a list we are tracing in
// the presence of a fixed length list constructor call.

/*member: myList:Container([exact=JSExtendableArray], element: Union([exact=JSString], [subclass=JSNumber]), length: null)*/
var myList = [];

/*member: otherList:Container([exact=JSExtendableArray], element: Union([exact=JSString], [exact=JSUInt31]), length: 2)*/
var otherList = ['foo', 42];

/*member: main:[null]*/
main() {
  dynamic a = otherList
      /*Container([exact=JSExtendableArray], element: Union([exact=JSString], [exact=JSUInt31]), length: 2)*/
      [0];
  a /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ += 54;
  myList
      .
      /*invoke: Container([exact=JSExtendableArray], element: Union([exact=JSString], [subclass=JSNumber]), length: null)*/
      add(a);
}
