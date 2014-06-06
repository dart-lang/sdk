// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";
import "package:expect/expect.dart";

newLRUMapWithShift(int shift) {
  var lib = currentMirrorSystem().libraries[Uri.parse("dart:_internal")];
  var cls = lib.declarations[#LRUMap];
  return cls.newInstance(#withShift, [shift]).reflectee;
}

main() {
  Expect.throws(() => newLRUMapWithShift(0), (e) => e is Exception);

  for (int shift = 1; shift < 5; shift++) {
    var map = newLRUMapWithShift(shift);
    var capacity = (1 << shift) * 3 ~/ 4;
    for (int value = 0; value < 100; value++) {
      var key = "$value";
      map[key] = value;
      Expect.equals(value, map[key]);
    }
    for (int value = 0; value < 100 - capacity - 1; value++) {
      var key = "$value";
      Expect.equals(null, map[key]);
    }
    for (int value = 100 - capacity; value < 100; value++) {
      var key = "$value";
      Expect.equals(value, map[key]);
    }
  }
}