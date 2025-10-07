// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

test() {
  var f = () sync* {
    yield 1;
    yield* [3, 4.0];
  };
  Iterable<num> g = f();
}

main() {}
