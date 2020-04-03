// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef int Adder(int a, int b);

class Mock {
  noSuchMethod(i) => null;
}

class MockAdder extends Mock {
  int call(int a, int b);
}

main() {
  Adder adder = new MockAdder();
}
