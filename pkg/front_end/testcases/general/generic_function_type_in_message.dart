// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

num add<A extends num, B extends num>(A a, B b) => a + b;

test() {
  int x = add;
}

main() {
  if (add(1,2) < 3) test();
}
