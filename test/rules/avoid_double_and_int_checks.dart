// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_double_and_int_checks`

lint_for_double_before_int_check(m) {
  if (m is double) // LINT
  {} else if (m is int) {}
}
no_lint_for_only_double_check(m) {
  if (m is double) // OK
  {}
}
no_lint_for_int_before_double_check(m) {
  if (m is int) // OK
  {} else if (m is double) {}
  {}
}
