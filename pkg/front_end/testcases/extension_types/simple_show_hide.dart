// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E1 on int show num {}

test1(E1 e1) {
  e1.ceil(); // Ok.
  e2.floor(); // Ok.
  e1.isEven; // Error.
}

extension E2 on int show num hide ceil {}

test2(E2 e2) {
  e2.ceil(); // Error.
  e2.floor(); // Ok.
  e2.isEven; // Error.
}

extension E3 on int hide isEven {}

test3(E3 e3) {
  e3.isOdd; // Ok.
  e3.isEven; // Error.
}

extension type MyInt on int show num, isEven hide floor {
  int get twice => 2 * this;
}

test() {
  MyInt m = 42;
  m.twice; // OK, in the extension type.
  m.isEven; // OK, a shown instance member.
  m.ceil(); // OK, a shown instance member.
  m.toString(); // OK, an `Object` member.
  m.floor(); // Error, hidden.
}

main() {}
