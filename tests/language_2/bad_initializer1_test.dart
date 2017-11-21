// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Variable initializer must not reference the initialized variable.

main() {
  const elems = const [
    const [
      1,
      2.0,
      true,
      false,
      0xffffffffff,
      elems //# 01: compile-time error
    ],
    "a",
    "b"
  ];
}
