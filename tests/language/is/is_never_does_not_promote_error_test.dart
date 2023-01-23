// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This tests changes around promotion to `Never` that were made as part of
// https://dart-review.googlesource.com/c/sdk/+/251280
// (https://github.com/dart-lang/sdk/issues/49635): a type test of `variable is
// Never` no longer promotes the type of `variable` to `Never`.

void f(int i) {
  if (i is Never) {
    i.isEven;
    i.abs();
    i.bogus();
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'bogus' isn't defined for the class 'int'.
  }
}

main() {
  f(0);
}
