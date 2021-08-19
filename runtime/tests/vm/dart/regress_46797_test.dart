// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=100

int var74 = -43;

@pragma("vm:never-inline")
foo(int var74) {
  if (var74 >>> 0xC == 675872701) {
    print("side-effect");
  }
}

main() {
  for (var i = 0; i < 200; i++) {
    foo(43);
  }
  foo(-43);
}
