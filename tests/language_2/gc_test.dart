// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing GC, issue 1469.

main() {
  var div;
  for (int i = 0; i < 200; ++i) {
    List l = new List(1000000);
    var m = 2;
    div = (_) {
      var b = l; // Was causing OutOfMemory.
    };
    var lSmall = new List(3);
    // Circular reference between new and old gen objects.
    lSmall[0] = l;
    l[0] = lSmall;
  }
}
