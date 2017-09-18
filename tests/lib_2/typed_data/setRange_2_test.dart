// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';
import 'setRange_lib.dart';

sameElementSizeTest() {
  // Views of elements with the same size but different 'types'.
  checkSameSize(makeInt16List, makeInt16View, makeUint16View);
  checkSameSize(makeInt16List, makeUint16View, makeInt16View);
}

main() {
  sameElementSizeTest();
}
