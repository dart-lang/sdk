// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/*element: myList:Container([null|exact=NativeFloat32List], element: [subclass=JSNumber], length: 42)*/
var myList = new Float32List(42);

/*element: myOtherList:Container([null|exact=NativeUint8List], element: [exact=JSUInt31], length: 32)*/
var myOtherList = new Uint8List(32);

/*element: main:[subclass=JSNumber]*/
main() {
  // ignore: unused_local_variable
  var a = new Float32List(9);
  return myList
          /*Container([null|exact=NativeFloat32List], element: [subclass=JSNumber], length: 42)*/
          [0] /*invoke: [subclass=JSNumber]*/ +
      myOtherList
          /*Container([null|exact=NativeUint8List], element: [exact=JSUInt31], length: 32)*/
          [0];
}
