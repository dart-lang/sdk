// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Mixin {}

class A {
  const A();
}

class B extends A
    with Mixin //# 01: compile-time error
{
  const B();
}

main() {
  var a = const B();
}
