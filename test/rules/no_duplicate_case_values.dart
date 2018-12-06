// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N no_duplicate_case_values`

void switchInt() {
  const int A = 1;
  int v = 5;

  switch (v) {
    case 1: // OK
    case 2: // OK
    case A: // LINT
    case 2: // LINT
    case 3: // OK
    default:
  }
}

void switchString() {
  const String A = 'a';
  String v = 'aa';

  switch (v) {
    case 'aa':  // OK
    case 'bb':  // OK
    case A + A: // LINT
    case 'bb':  // LINT
    case A + 'b': // OK
    default:
  }
}

enum E {
  one,
  two,
  three
}

void switchEnum() {
  E v = E.one;

  switch (v) {
    case E.one:  // OK
    case E.two:  // OK
    case E.three: // OK
    case E.two:  // LINT
    default:
  }
}

class ConstClass {
  final int v;
  const ConstClass(this.v);
}

void switchConstClass() {
  ConstClass v = new ConstClass(1);

  switch (v) {
    case const ConstClass(1): // OK
    case const ConstClass(2): // OK
    case const ConstClass(3): // OK
    case const ConstClass(2): // LINT
    default:
  }
}
