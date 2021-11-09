// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int get foo => throw 42;
}

bar(int x) {}

test(A? a) {
  bar((a?.foo)!);
}

main() {}
