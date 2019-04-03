// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_const`

//ignore_for_file: unused_local_variable

class A {
  const A([o]);
}

main() {
  const A(); // OK
  A(); // OK

  const A([]); // OK
  A([]); // OK
  A(const []); // OK

  const A(A()); // OK
  A(const A()); // OK
  A(A()); // OK

  final v1 = A(); // OK
  const v3 = const A(); // LINT
  const v4 = A(); // OK
  final v5 = const A([]); // OK
  const v6 = const A([]); // LINT
  const v7 = A([]); // OK
  final v8 = A(const []); // OK
  final v9 = const A(const []); // LINT
  final v10 = const A([]); // OK
  final v11 = const A(const {}); // LINT
  final v12 = const A({}); // OK
}
