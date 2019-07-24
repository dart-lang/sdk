// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void eqNull(int? x) {
  while (x == null) {
    x;
  }
  /*nonNullable*/ x;
}

void notEqNull(int? x) {
  while (x != null) {
    /*nonNullable*/ x;
  }
  x;
}

void while_false() {
  while (false) /*stmt: unreachable*/ {
    1;
  }
  2;
}

/*member: while_true:doesNotComplete*/
void while_true() {
  while (true) {
    1;
  }
  /*stmt: unreachable*/ 2;
  /*stmt: unreachable*/ 3;
}

void while_true_break() {
  while (true) {
    1;
    break;
    /*stmt: unreachable*/ 2;
  }
  3;
}

void while_true_breakIf(bool b) {
  while (true) {
    1;
    if (b) break;
    2;
  }
  3;
}

/*member: while_true_continue:doesNotComplete*/
void while_true_continue() {
  while (true) {
    1;
    continue;
    /*stmt: unreachable*/ 2;
  }
  /*stmt: unreachable*/ 3;
}
