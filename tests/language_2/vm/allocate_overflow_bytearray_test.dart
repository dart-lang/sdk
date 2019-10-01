// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:expect/expect.dart';

const interestingLengths = <int>[
  0x3FFFFFFF00000000,
  0x3FFFFFFFFFFFFFF0,
  0x3FFFFFFFFFFFFFFE,
  0x3FFFFFFFFFFFFFFF,
  0x7FFFFFFF00000000,
  0x7FFFFFFFFFFFFFF0,
  0x7FFFFFFFFFFFFFFE,
  0x7FFFFFFFFFFFFFFF,
];

main() {
  for (int interestingLength in interestingLengths) {
    print(interestingLength);

    Expect.throws(() {
      var bytearray = new Uint8List(interestingLength);
      print(bytearray.first);
    }, (e) => e is OutOfMemoryError);

    Expect.throws(() {
      var bytearray = new Uint8ClampedList(interestingLength);
      print(bytearray.first);
    }, (e) => e is OutOfMemoryError);

    Expect.throws(() {
      var bytearray = new Int8List(interestingLength);
      print(bytearray.first);
    }, (e) => e is OutOfMemoryError);

    Expect.throws(() {
      var bytearray = new ByteData(interestingLength);
      print(bytearray.getUint8(0));
    }, (e) => e is OutOfMemoryError);
  }
}
