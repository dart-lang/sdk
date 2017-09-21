// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-use-osr --no-background_compilation

test(a) {
  var e;
  for (var i = 0; i < a.length; i++) {
    e = a[i];
    for (var j = 0; j < i; j++) {
      e = a[j];
    }
  }
  return e;
}

main() {
  var a = [0, 1, 2, 3, 4, 5];
  for (var i = 0; i < 20; i++) {
    test(a);
  }
}
