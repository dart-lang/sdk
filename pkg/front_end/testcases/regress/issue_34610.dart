// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A { get A.named => null; get bar => 1; }

class B { B.named : super(); get bar => 1; }

class C { C.named => null; get bar => 1; }

main() {
  try {
    print(new A.named().bar);
    throw 'expected exception';
  } catch (e) {
    // Expected Error: Constructors can't have a return type.
  }
  print(new B.named().bar);
  try {
    print(new C.named().bar);
    throw 'expected exception';
  } catch (e) {
    // Expected Error: Constructors can't have a return type.
  }
}
