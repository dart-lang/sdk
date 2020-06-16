// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

// Test that constant propagation correctly updates phis when predecessor's
// reachability changes.

final keys = const ["keyA"];
final values = const ["a"];

main() {
  for (var i = 0; i < 20; i++) test(keys[0]);
}

test(key) {
  var ref = key2value(key);
  Expect.equals("a", (ref == null) ? "-" : ref);
}

key2value(key) {
  var index = indexOf(keys, key);
  return (index == -1) ? null : values[index];
}

indexOf(keys, key) {
  for (var i = keys.length - 1; i >= 0; i--) {
    var equals = keys[i] == key;
    if (equals) return i;
  }
  return -1;
}
