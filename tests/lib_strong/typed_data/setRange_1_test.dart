// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';
import 'setRange_lib.dart';

sameTypeTest() {
  checkSameSize(makeInt16List, makeInt16View, makeInt16View);
  checkSameSize(makeUint16List, makeUint16View, makeUint16View);
}

main() {
  sameTypeTest();
}
