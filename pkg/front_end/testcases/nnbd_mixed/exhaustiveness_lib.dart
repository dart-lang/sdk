// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool boolSwitchStatement(bool b) {
  switch (b) {
    case true:
      return true;
    case false:
      return false;
  }
}

bool boolSwitchExpression(bool b) => switch (b) {
      true => true,
      false => false,
    };

sealed class A {}

class A1 extends A {}

class A2 extends A {}

int sealedSwitchStatement(A a) {
  switch (a) {
    case A1():
      return 0;
    case A2():
      return 1;
  }
}

int sealedSwitchExpression(A a) => switch (a) {
      A1() => 0,
      A2() => 1,
    };
