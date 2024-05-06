// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

// TODO(johnniwinther): Fix inference for spec mode. List elements should not be
// [empty].

/*member: myList:Container([exact=NativeFloat32List], element: [subclass=JSNumber], length: 42)*/
var myList = Float32List(42);

/*member: myOtherList:Container([exact=NativeUint8List], element: [exact=JSUInt31], length: 32)*/
var myOtherList = Uint8List(32);

/*member: main:[subclass=JSNumber]*/
main() {
  // ignore: unused_local_variable
  var a = Float32List(9);
  return myList
          /*Container([exact=NativeFloat32List], element: [subclass=JSNumber], length: 42)*/
          [0]
      /*invoke: [subclass=JSNumber]*/
      +
      myOtherList
          /*Container([exact=NativeUint8List], element: [exact=JSUInt31], length: 32)*/
          [0];
}
