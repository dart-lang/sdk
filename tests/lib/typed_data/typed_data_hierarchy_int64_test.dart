// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import 'dart:typed_data';

import 'package:expect/expect.dart';

var inscrutable = null;

void implementsTypedData() {
  Expect.isTrue(inscrutable(Int64List(1)) is TypedData);
  Expect.isTrue(inscrutable(Uint64List(1)) is TypedData);
}

void implementsList() {
  Expect.isTrue(inscrutable(Int64List(1)) is List<int>);
  Expect.isTrue(inscrutable(Uint64List(1)) is List<int>);
}

main() {
  inscrutable = (x) => x;
  implementsTypedData();
  implementsList();
}
