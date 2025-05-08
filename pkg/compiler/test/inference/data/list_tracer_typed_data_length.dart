// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

// TODO(johnniwinther): Fix inference for spec mode. List elements should not be
// [empty].

/*member: myList:Container([exact=NativeFloat32List|powerset={I}{O}{M}], element: [subclass=JSNumber|powerset={I}{O}{N}], length: 42, powerset: {I}{O}{M})*/
var myList = Float32List(42);

/*member: myOtherList:Container([exact=NativeUint8List|powerset={I}{O}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 32, powerset: {I}{O}{M})*/
var myOtherList = Uint8List(32);

/*member: main:[subclass=JSNumber|powerset={I}{O}{N}]*/
main() {
  // ignore: unused_local_variable
  var a = Float32List(9);
  return myList
      /*Container([exact=NativeFloat32List|powerset={I}{O}{M}], element: [subclass=JSNumber|powerset={I}{O}{N}], length: 42, powerset: {I}{O}{M})*/
      [0]
      /*invoke: [subclass=JSNumber|powerset={I}{O}{N}]*/
      +
      myOtherList
      /*Container([exact=NativeUint8List|powerset={I}{O}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 32, powerset: {I}{O}{M})*/
      [0];
}
