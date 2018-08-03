// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test program that creates an object by invoking a constor without
/// initializers.
main() {
  var objA = new A(37, 'test');
  print(objA.a);
  print(objA.b);
}

class A {
  int a;
  String b;

  A(int a, String b) {
    this.a = a;
    this.b = b;
  }
}
