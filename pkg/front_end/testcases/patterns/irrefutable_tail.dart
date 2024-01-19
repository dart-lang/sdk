// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  B get b;
  int get i;
}

abstract class B {
  C get c;
  int get i;
}

abstract class C {
  int get i;
}

ifCase(o) {
  if (o case A a) {
    print(a);
  }
  if (o case A(:var b)) {
    print(b);
  }
  if (o case A(b: B(:var c))) {
    print(c);
  }
  if (o case A(b: B(c: C(:var i)))) {
    print(i);
  }
  if (o case A(:var b, :var i)) {
    print(b);
    print(i);
  }
  if (o case A(i: 5, :var b)) {
    print(b);
  }
  if (o case A(:var b, i: 5)) {
    print(b);
  }
  if (o case A(:var b, i: 5) && A(b: B(:var c, i: 7))) {
    print(b);
    print(c);
  }
}

switchExpression(o) => switch (o) {
      A a => a,
      A(:var b) => b,
      A(b: B(:var c)) => c,
      A(b: B(c: C(:var i))) => i,
      A(:var b, :var i) => '$b$i',
      A(i: 5, :var b) => b,
      A(:var b, i: 5) => b,
      A(:var b, i: 5) && A(b: B(:var c, i: 7)) => '$b$c',
      _ => null,
    };

switchStatement(o) {
  dynamic v;
  switch (o) {
    case A a:
      v = a;
    case A(:var b):
      v = b;
    case A(b: B(:var c)):
      v = c;
    case A(b: B(c: C(:var i))):
      v = i;
    case A(:var b, :var i):
      v = '$b$i';
    case A(i: 5, :var b):
      v = b;
    case A(:var b, i: 5):
      v = b;
    case A(:var b, i: 5) && A(b: B(:var c, i: 7)):
      v = '$b$c';
  }
  return v;
}
