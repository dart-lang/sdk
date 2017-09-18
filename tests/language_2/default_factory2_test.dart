// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check type bounds when invoking a redirecting factory method

abstract class Foo {}

abstract class IA<T> {
  factory IA() = A<T>; //# 01: compile-time error
}

class A<T extends Foo> implements IA<T> {
  factory A() {}
}

main() {
  var result = new IA<String>(); //# 01: continued
}
