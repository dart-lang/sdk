// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test for issue 22936.

import 'package:expect/expect.dart';

bool fooCalled = false;

foo() {
  fooCalled = true;
  return null;
}

main() {
  final x = null;
  try {
    x = foo();
//  ^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Can't assign to the final variable 'x'.
  } on NoSuchMethodError {}
  Expect.isTrue(fooCalled);
}
