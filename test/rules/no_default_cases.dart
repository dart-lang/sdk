// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N no_default_cases`

// Enum-like
class EL {
  final int i;
  const EL._(this.i);

  static const e = EL._(1);
  static const f = EL._(2);
  static const g = EL._(3);
}

void el(EL e) {
  switch(e) {
    case EL.e :
      print('e');
      break;
    default : // LINT
      print('default');
  }
}

enum E {
  e, f, g,
}

void e(E e) {
  switch(e) {
    case E.e :
      print('e');
      break;
    default : // LINT
      print('default');
  }
}

void i(int i) {
  switch(i) {
    case 1 :
      print('1');
      break;
    default : // OK
      print('default');
  }
}
