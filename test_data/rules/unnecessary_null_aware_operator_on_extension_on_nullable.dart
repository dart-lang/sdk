// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N unnecessary_null_aware_operator_on_extension_on_nullable`

extension E on int? {
  int get foo => 1;
  void set foo(int v) {}
  String operator [](int i) => '';
  void operator []=(int i, String v) {}
  int m() => 1;
}

f(int? i) {
  i?.foo; // LINT
  i.foo; // OK
  E(i)?.foo; // LINT
  E(i).foo; // OK

  i?.foo = 1; // LINT
  i.foo = 1; // OK
  E(i)?.foo = 1; // LINT
  E(i).foo = 1; // OK

  i?[0]; // LINT
  i[0]; // OK
  E(i)?[0]; // LINT
  E(i)[0]; // OK

  i?[0] = ''; // LINT
  i[0] = ''; // OK
  E(i)?[0] = ''; // LINT
  E(i)[0] = ''; // OK

  i?.m(); // LINT
  i.m(); // OK
  E(i)?.m(); // LINT
  E(i).m(); // OK
}
