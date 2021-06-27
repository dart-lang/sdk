// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  // The `unawaited` function is not exposed by dart:core.
  unawaited;
  // [error line 7, column 3, length 9]
  // [cfe] Getter not found: 'unawaited'.
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
}
