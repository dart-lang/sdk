// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void f(int x, int y, int? z) {
  x++ = y;
//^^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
//^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
// ^
// [cfe] Illegal assignment to non-assignable expression.
  x++ += y;
//^^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
//^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
// ^
// [cfe] Illegal assignment to non-assignable expression.
  z++ ??= y;
//^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//^^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
//^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
// ^
// [cfe] Illegal assignment to non-assignable expression.
}

main() {
  f(1, 2, 3);
}
