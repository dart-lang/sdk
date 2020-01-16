// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks for compile-time errors related to definite assignment and
// completion.

int foo() {
  int x;
  return x;
}

int bar() {}

main() {}
