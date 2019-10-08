// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_print`

void main() {
  print('ha'); // LINT
  [1,2,3].forEach(print); // LINT
  Future.value('hello').then(print); // LINT
}


var x = print; // OK

void f() {
  x('ha'); // OK?
  [1,2,3].forEach(x); // OK
  Future.value('hello').then(x); // OK
}

class A {
  print() {
  }
}

void g() {
  A().print(); // OK
}
