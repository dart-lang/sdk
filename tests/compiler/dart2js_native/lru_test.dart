// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show LRUMap;
import "../../lib/mirrors/lru_expect.dart";

main() {
  expect((shift) => new LRUMap.withShift(shift));
}
