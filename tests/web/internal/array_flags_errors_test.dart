// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show ArrayFlags, HArrayFlagsCheck;
import 'dart:typed_data';

import 'package:expect/expect.dart';

void rub(Object object, String message) {
  try {
    // Always fail, using non-standard operation name and verb.
    HArrayFlagsCheck(object, ArrayFlags.unmodifiable,
        ArrayFlags.fixedLengthCheck, 'rub', 'burnish');
    Expect.fail('HArrayFlagsCheck should always throw');
  } catch (e) {
    Expect.equals(message, e.toString());
  }
}

main() {
  rub(const [], "Unsupported operation: 'rub': Cannot burnish a constant list");
  rub(List.unmodifiable([]),
      "Unsupported operation: 'rub': Cannot burnish an unmodifiable list");
  rub(List.filled(0, 0),
      "Unsupported operation: 'rub': Cannot burnish a fixed-length list");
  rub([], "Unsupported operation: 'rub': Cannot burnish a list");

  rub(Uint8List(10).asUnmodifiableView(),
      "Unsupported operation: 'rub': Cannot burnish an unmodifiable list");

  rub(ByteData(10).asUnmodifiableView(),
      "Unsupported operation: 'rub': Cannot burnish an unmodifiable ByteData");
}
