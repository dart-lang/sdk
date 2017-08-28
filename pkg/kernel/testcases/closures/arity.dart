// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that closures check their argument count.
//
main() {
  var closures = [
    (x, y, [z]) {},
    (x, y, z) {},
    (x, y, {z}) {},
    (x, y, z, w, v) {}
  ];
  for (var c in closures) {
    bool ok = false;
    try {
      c(1, 2, 3, 4);
    } on NoSuchMethodError catch (_) {
      ok = true;
    }
    if (!ok) {
      throw new Exception("Expected an error!");
    }
  }

  (x, y, [z]) {}(1, 2);
  (x, y, [z]) {}(1, 2, 3);
}
