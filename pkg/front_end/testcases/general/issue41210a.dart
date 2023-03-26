// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  String method(num i);
}

abstract class Interface2 {
  String method(covariant int i);
}

mixin A implements Interface {
  String method(num i, {String s = "hello"}) => s;
}

mixin B implements Interface {
  String method(num i);
}

class C with A, B {} // error

mixin D implements Interface, Interface2 {}

class E with A, D {} // ok

mixin F implements Interface {}

class G with A, F {} // ok

main() {
  print(C().method(0));
}
