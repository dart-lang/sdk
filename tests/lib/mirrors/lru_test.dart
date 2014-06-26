// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";
import "lru_expect.dart";

newLRUMapWithShift(int shift) {
  var lib = currentMirrorSystem().libraries[Uri.parse("dart:_internal")];
  var cls = lib.declarations[#LRUMap];
  return cls.newInstance(#withShift, [shift]).reflectee;
}

main() {
  expect(newLRUMapWithShift);
}
