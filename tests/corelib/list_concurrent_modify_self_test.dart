// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:typed_data";
import "package:expect/expect.dart";

void main() {
  testConcurrentAddSelf([1, 2, 3]);
}

testConcurrentAddSelf(List list) {
  Expect.throws(() {
    list.addAll(list);
  }, (e) => e is ConcurrentModificationError, "testConcurrentAddSelf($list)");
}
