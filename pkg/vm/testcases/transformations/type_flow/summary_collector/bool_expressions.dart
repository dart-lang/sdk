// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic foo() => null;
bool bar() => null;

void bool_expressions() {
  if (foo()) {}
  while (bar()) {}
  for (int i = 0; i < 10; i++) {}
  bool x = bar();
  bool y = true;
  if (x is bool) {
    y = x ? true : foo();
    y = bar() || bar();
  }
  x = foo() && foo();
  y = !y;
  assert(y);
}

main() {}
