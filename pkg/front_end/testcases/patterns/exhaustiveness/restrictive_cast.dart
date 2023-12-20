// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class S {
  bool get b;
}

class A implements S {
  final bool b;

  A(this.b);
}

class B implements S {
  final bool b;

  B(this.b);
}

class C implements A, B {
  bool get b => false;
}

int? value = 1;

int? method(S s) => switch (s) /* Error */ {
      A(b: true) as A => 0,
      B(b: true) as B => value,
    };

test() {
  print(method(C()));
}
