// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that switches using only values with primitive equality (excluding
// the exceptions Symbol and Type) are lowered correctly. These are special
// cased by the CFE.

import 'package:expect/expect.dart';

abstract class I {}

enum A implements I {
  a,
  b,
  c,
}

enum B implements I {
  a,
  b,
  c,
}

int switchExpressionA(A a) => switch (a) {
      A.a => 0,
      A.b => 1,
      A.c => 2,
    };

int switchStatementA(A a) {
  switch (a) {
    case A.a:
      return 0;
    case A.b:
      return 1;
    case A.c:
      return 2;
  }
}

int switchExpressionB(B b) => switch (b) {
      B.a => 3,
      B.b => 4,
      B.c => 5,
    };

int switchStatementB(B b) {
  switch (b) {
    case B.a:
      return 3;
    case B.b:
      return 4;
    case B.c:
      return 5;
  }
}

int switchExpressionI(I i) => switch (i) {
      A.a => 0,
      A.b => 1,
      A.c => 2,
      B.a => 3,
      B.b => 4,
      B.c => 5,
      _ => -1,
    };

int switchStatementI(I i) {
  switch (i) {
    case A.a:
      return 0;
    case A.b:
      return 1;
    case A.c:
      return 2;
    case B.a:
      return 3;
    case B.b:
      return 4;
    case B.c:
      return 5;
    default:
      return -1;
  }
}

main() {
  Expect.equals(0, switchExpressionA(A.a));
  Expect.equals(1, switchExpressionA(A.b));
  Expect.equals(2, switchExpressionA(A.c));

  Expect.equals(0, switchStatementA(A.a));
  Expect.equals(1, switchStatementA(A.b));
  Expect.equals(2, switchStatementA(A.c));

  Expect.equals(3, switchExpressionB(B.a));
  Expect.equals(4, switchExpressionB(B.b));
  Expect.equals(5, switchExpressionB(B.c));

  Expect.equals(3, switchStatementB(B.a));
  Expect.equals(4, switchStatementB(B.b));
  Expect.equals(5, switchStatementB(B.c));

  Expect.equals(0, switchExpressionI(A.a));
  Expect.equals(1, switchExpressionI(A.b));
  Expect.equals(2, switchExpressionI(A.c));
  Expect.equals(3, switchExpressionI(B.a));
  Expect.equals(4, switchExpressionI(B.b));
  Expect.equals(5, switchExpressionI(B.c));

  Expect.equals(0, switchStatementI(A.a));
  Expect.equals(1, switchStatementI(A.b));
  Expect.equals(2, switchStatementI(A.c));
  Expect.equals(3, switchStatementI(B.a));
  Expect.equals(4, switchStatementI(B.b));
  Expect.equals(5, switchStatementI(B.c));
}
