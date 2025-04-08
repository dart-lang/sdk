// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

// TODO(johnniwinther): Fix inference for spec mode. List elements should not be
// [empty].

/*member: myList:Container([exact=NativeFloat32List|powerset=0], element: [subclass=JSNumber|powerset=0], length: 42, powerset: 0)*/
var myList = Float32List(42);

/*member: myOtherList:Container([exact=NativeUint8List|powerset=0], element: [exact=JSUInt31|powerset=0], length: 32, powerset: 0)*/
var myOtherList = Uint8List(32);

/*member: main:[subclass=JSNumber|powerset=0]*/
main() {
  // ignore: unused_local_variable
  var a = Float32List(9);
  return myList
      /*Container([exact=NativeFloat32List|powerset=0], element: [subclass=JSNumber|powerset=0], length: 42, powerset: 0)*/
      [0]
      /*invoke: [subclass=JSNumber|powerset=0]*/
      +
      myOtherList
      /*Container([exact=NativeUint8List|powerset=0], element: [exact=JSUInt31|powerset=0], length: 32, powerset: 0)*/
      [0];
}
