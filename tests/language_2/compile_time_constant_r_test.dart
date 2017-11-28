// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const x =
    throw //# 01: compile-time error
    "x";

const y = const {
  0:
      throw //# 02: compile-time error
      "y"
};

main() {
  print(x);
  print(y);
  const z =
      throw //# 03: compile-time error
      1 + 1 + 1;
  print(z);
}
