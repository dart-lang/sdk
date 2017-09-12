// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing that a void arrow function is allowed to return any type of value.

void foo() => 42;
void set bar(x) => 43;

main() {
  foo();
  bar = 44;
}
