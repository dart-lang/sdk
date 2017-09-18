// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks for a regression found in Dart Editor: the
// analyzer was treating [Type] as more specific than any type
// variable (generic parameter).
//
// https://code.google.com/p/dart/issues/detail?id=18628

class C<T> {
  // This line is supposed to cause the warning; the other commented
  // line just doesn't make sense without this line.
  T t = int; //# 01: compile-time error
}

main() {
  C<Type> c = new C<Type>();
  print(c.t); //# 01: compile-time error
}
