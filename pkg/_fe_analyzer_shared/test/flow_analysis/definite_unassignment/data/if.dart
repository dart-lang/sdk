// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

if_condition() {
  late int v;
  if ((v = 0) >= 0) {
    v;
  } else {
    v;
  }
  v;
}

if_then(bool c) {
  late int v;
  if (c) {
    v = 0;
  }
  v;
}

if_thenElse_none(bool c) {
  late int v;
  if (c) {
  } else {}
  /*unassigned*/ v;
}

if_thenElse_else(bool c) {
  late int v;
  if (c) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}

if_thenElse_then(bool c) {
  late int v;
  if (c) {
    v = 0;
  } else {
    // not assigned
  }
  v;
}

if_thenElse_all(bool c) {
  late int v;
  if (c) {
    v = 0;
    v;
  } else {
    v = 0;
    v;
  }
  v;
}

if_thenElse_then_exit_alwaysThrows(bool c) {
  late int v;
  if (c) {
    v = 0;
  } else {
    foo();
  }
  v;
}

Never foo() {
  throw Object();
}

if_thenElse_then_exit_return(bool c) {
  late int v;
  if (c) {
    v = 0;
  } else {
    return;
  }
  v;
}

if_thenElse_then_exit_throw(bool c) {
  late int v;
  if (c) {
    v = 0;
  } else {
    throw 42;
  }
  v;
}
