// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {}

void f(num x) {
  if (x is double) {
    // DRY_RUN: 13, Explicit check for double or int.
  } else if (x is int) {}
  // Users are allowed to ignore lints still.
  if (x is double) {
    // ignore: avoid_double_and_int_checks
  } else if (x is int) {}
}
