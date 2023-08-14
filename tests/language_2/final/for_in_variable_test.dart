// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

main() {
  for (final i in [1, 2, 3]) {
    i = 4;
//  ^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Can't assign to the final variable 'i'.
  }
}
