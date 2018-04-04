// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_double_and_int_checks`

lint_for_double_before_int_check_on_parameter(m) {
  if (m is double) {} //
  else if (m is int) {} // LINT
}

no_lint_for_only_double_check(m) {
  if (m is double) {} // OK
}

no_lint_for_int_before_double_check(m) {
  if (m is int) {} //
  else if (m is double) {} // OK
}

lint_for_double_before_int_check_on_local() {
  var m;
  if (m is double) {} //
  else if (m is int) {} // LINT
}

get g => null;
lint_for_double_before_int_check_on_getter() {
  if (g is double) {} //
  else if (g is int) {} // OK
}
