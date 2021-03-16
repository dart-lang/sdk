// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

// Regression test for issue 32853.


int foo<T extends Comparable<T>>(T a, T b) => a.compareTo(b);

main() {
  int Function<T extends Comparable<T>>(T, T) f = foo;
  print(f<num>(1, 2));
}