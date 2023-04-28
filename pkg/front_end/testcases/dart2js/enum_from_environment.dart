// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum A {
  a(B.a),
  b(B.b),
  ;

  final B value;

  const A(this.value);
}

class B {
  final int value;

  const B(this.value);

  static const B a = const B(const int.fromEnvironment('a'));
  static const B b = const B(const int.fromEnvironment('b'));
}

String method(A a) {
  switch (a) {
    case A.a:
      return 'a';
    case A.b:
      return 'b';
  }
}
