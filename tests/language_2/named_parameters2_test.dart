// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.
// You may not provide the same parameter as both a positional and a named argument.

int test(int a, [int b]) {
  return a;
}

main() {
    // Parameter b passed twice, as positional and named.
    test(10, 25, b: 26); /*@compile-error=unspecified*/
}
