// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extending a type parameter is not allowed.

abstract class A<T> extends T {} // //# 00: compile-time error
class A<T> extends T {} // //# 01: compile-time error

main() {
  A a = new A(); // //# 00: compile-time error
  A a = new A(); // //# 01: continued
}
