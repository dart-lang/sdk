// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands can access private enums in the same library.

import 'package:expect/expect.dart';

enum _E {
  e1,
  e2;

  static _E get getter => e1;
  static _E method() => e2;
  factory _E.fact() => e1;
}

typedef Public_E = _E;
final Public_E v = _E.e1;

void check(_E e, _E expected) {
  Expect.equals(e, expected);
}

void checkAlias(Public_E e, Public_E expected) {
  Expect.equals(e, expected);
}

void main() {
  check(v, _E.e1);
  checkAlias(v, _E.e1);

  check(.e2, _E.e2);
  checkAlias(.e2, _E.e2);

  check(.getter, _E.e1);
  checkAlias(.getter, _E.e1);

  check(.method(), _E.e2);
  checkAlias(.method(), _E.e2);

  check(.fact(), _E.e1);
  checkAlias(.fact(), _E.e1);

  check(Public_E.e1, _E.e1);
  checkAlias(Public_E.e1, _E.e1);
}
