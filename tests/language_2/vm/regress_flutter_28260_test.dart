// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=10

// Bug cid ranges (https://github.com/flutter/flutter/issues/28260).

import 'dart:typed_data';

import "package:expect/expect.dart";

foo() {
  ByteBuffer a = null;
  var dataMap = Map<String, dynamic>();
  dataMap['data'] = a;
  return (dataMap['data'] is ByteBuffer);
}

void main() {
  for (int i = 0; i < 20; i++) {
    Expect.equals(false, foo());
  }
}
