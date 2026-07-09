// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests variable assignments for const functions.

import "package:expect/expect.dart";

const var1 = varAssignmentTest(1);
int varAssignmentTest(int a) {
  int x = 4;
  {
    x = 3;
  }
  return x;
}

int function() {
  int varAssignmentTest2() {
    int x = 2;
    x += 1;
    return x;
  }

  const var2 = varAssignmentTest2();
  return var2;
}

const var3 = varAssignmentTest3(1);
const var4 = varAssignmentTest3(2);
int varAssignmentTest3(int a) {
  int x = 4;
  x = a + 1;
  return x;
}

void main() {
  Expect.equals(var1, 3);
  Expect.equals(function(), 3);
  Expect.equals(var3, 2);
  Expect.equals(var4, 3);
}
