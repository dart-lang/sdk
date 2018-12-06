// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N literal_only_boolean_expressions`

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
  while(!true) {} //LINT
  do {} while(false); // LINT
  for ( ; true; ) { } //LINT
}

bool m() => true;

void bug658() {
  String text;
  if ((text?.length ?? 0) != 0) {}
}
