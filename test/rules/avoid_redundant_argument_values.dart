// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_redundant_argument_values`

import 'package:meta/meta.dart';

class A {
  A({bool valWithDefault = true, bool val});
  void f({bool valWithDefault = true, bool val}) {}
  void g({int valWithDefault = 1, bool val}) {}
  void h({String valWithDefault = 'default', bool val}) {}
}

bool q() => true;

void ff({bool valWithDefault = true, bool val}) {}
void g({@required bool valWithDefault = true, bool val}) {}

void gg(int x, [int y = 0]) {}
void ggg([int a = 1, int b = 2]) {}
void gggg([int a = 0, int b]) {}

void h([int a, int b = 1]) {}

void main() {
  A(valWithDefault: true); //LINT
  A().f(valWithDefault: true); //LINT
  A().g(valWithDefault: 1); //LINT
  A().h(valWithDefault: 'default'); //LINT

  A().f(val: false); //OK
  A().f(val: false, valWithDefault: false); //OK

  final v = true;
  A().f(val: false, valWithDefault: v); //OK
  A().f(val: false, valWithDefault: q()); //OK

  ff(valWithDefault: true); //LINT
  ff(val: false); //OK
  ff(val: false, valWithDefault: false); //OK

  ff(val: false, valWithDefault: v); //OK
  ff(val: false, valWithDefault: q()); //OK

  void fff({bool valWithDefault = true, bool val}) {}

  fff(valWithDefault: true); //LINT
  fff(val: false); //OK
  fff(val: false, valWithDefault: false); //OK

  fff(val: false, valWithDefault: v); //OK
  fff(val: false, valWithDefault: q()); //OK

  // Required.
  g(valWithDefault: true); //OK

  // Optional positional.
  gg(1, 0); //LINT
  gg(1, 1); //OK
  gg(1); //OK

  ggg(
      1, // OK the  - first argument is required so that we can provide the second argument.
      3);
  ggg(1,
      2); // LINT

  gggg(0, 1); //OK

  h(0,
      1); //LINT
}
