// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int var64 = -1;
num var68 = 2;

@pragma("vm:always-consider-inlining")
Set<bool>? foo0_1() {
  return <bool>{
    (8 <= (((var64 + -90) * 9223372034707292160) % var68)),
  };
}

main() {
  foo0_1();
}
