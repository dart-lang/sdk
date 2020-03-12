// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void f() {}

tryCatch_all() {
  late int v;
  try {
    f();
    v = 0;
  } catch (_) {
    v = 0;
  }
  v;
}

tryCatch_catch() {
  late int v;
  try {
    // not assigned
  } catch (_) {
    v = 0;
  }
  v;
}

tryCatch_try() {
  late int v;
  try {
    v = 0;
  } catch (_) {
    // not assigned
  }
  v;
}

tryCatchFinally_catch() {
  late int v;
  try {
    // not assigned
  } catch (_) {
    v = 0;
  } finally {
    // not assigned
  }
  v;
}

tryCatchFinally_finally() {
  late int v;
  try {
    // not assigned
  } catch (_) {
    // not assigned
  } finally {
    v = 1;
  }
  v;
}

tryCatchFinally_try() {
  late int v;
  try {
    v = 0;
  } catch (_) {
    // not assigned
  } finally {
    // not assigned
  }
  v;
}

tryFinally_finally() {
  late int v;
  try {
    // not assigned
  } finally {
    v = 0;
  }
  v;
}

tryFinally_try() {
  late int v;
  try {
    v = 0;
  } finally {
    // not assigned
  }
  v;
}
