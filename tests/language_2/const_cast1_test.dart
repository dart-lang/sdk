// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implicit casts in constants are supported and treated as compile-time errors
/// if they are not valid.

class A {
  final int n;
  const A(dynamic input) : n = input;
}

main() {
  print(const A(2)); //# 01: ok
  print(const A('2')); //# 02: compile-time error
}
