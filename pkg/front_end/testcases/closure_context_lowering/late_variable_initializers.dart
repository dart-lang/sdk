// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that the variable used in an initializer of a late variable
// is marked as direct-captured.
test1(int directCaptured) {
  late int first = directCaptured++;
  late int second = directCaptured++;
  return [first, second, directCaptured];
}

// The test checks that a variable used in an initializer of a late variable and
// also assert-captured elsewhere is marked as direct-captured.
test2(int directCaptured) {
  assert((() => directCaptured == 0)());
  late int variable = directCaptured;
  return variable;
}

// The test checks that a variable used in an initializer of a late variable
// inside of an assert is marked as assert-captured.
test3(int assertCaptured) {
  assert(
    (() {
      late bool isZero = assertCaptured == 0;
      return isZero;
    })(),
  );
}

// The test checks that a variable is marked as direct-captured when it's
// assert-captured in one scope and used in an initializer of a late variable in
// another scope.
test4(int directCaptured) {
  if (directCaptured > 0) {
    late int value = directCaptured--;
    return value;
  } else {
    assertIsZero() {
      assert(directCaptured == 0);
    }
    assertIsZero();
    return 0;
  }
}
