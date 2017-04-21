// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library typed_data_hierarchy_int64_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

var inscrutable = null;

void implementsTypedData() {
  Expect.isTrue(inscrutable(new Int64List(1)) is TypedData);
  Expect.isTrue(inscrutable(new Uint64List(1)) is TypedData);
}

void implementsList() {
  Expect.isTrue(inscrutable(new Int64List(1)) is List<int>);
  Expect.isTrue(inscrutable(new Uint64List(1)) is List<int>);
}

main() {
  inscrutable = (x) => x;
  implementsTypedData();
  implementsList();
}
