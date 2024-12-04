// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests promotions with final variables are not cancelled when they are
// certainly assigned as described by:
// https://github.com/dart-lang/language/issues/1721

isInt(bool b) {
  final num x;
  if (b) {
    x = 1;
  } else {
    x = 0.1;
  }
  if (x is int) {
    // Flow analysis retains the promotion to `int`.
    () => x.isEven;
  }
}

isInt_late(bool b) {
  late final num x;
  if (b) {
    x = 1;
  } else {
    x = 0.1;
  }
  if (x is int) {
    // Flow analysis retains the promotion to `int`.
    () => x.isEven;
  }
}

notEqNull(bool b) {
  final int? x;
  if (b) {
    x = 1;
  } else {
    x = null;
  }
  if (x != null) {
    // Flow analysis retains the promotion to `int`.
    () => x.isEven;
  }
}

notEqNull_late(bool b) {
  late final int? x;
  if (b) {
    x = 1;
  } else {
    x = null;
  }
  if (x != null) {
    // Flow analysis retains the promotion to `int`.
    () => x.isEven;
  }
}
