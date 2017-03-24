// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var closure;
  for (var i = 0, fn = () => i; i < 3; i++) {
    i += 1;
    closure = fn;
  }
  var x = closure();
  if (x != 1) {
    throw "Expected 1, but got $x.";
  }
}
