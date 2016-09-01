// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test/util/solo_test.dart literal_only_boolean_expressions`

bool variable = true;

void bad() {
  if (!true) {} // LINT
  if (true) {} // LINT
  if (true && 1 != 0) {} // LINT
  if (1 != 0 && true) {} // LINT
  if (1 < 0 && true) {} // LINT
  if (true && false) {} // LINT
  if (1 != 0) {} // LINT
  if (true && 1 != 0 || 3 < 4) {} // LINT
  if (1 != 0 || 3 < 4 && true) {} // LINT
  if (null ?? m()) {} // LINT
}

bool m() => true;
