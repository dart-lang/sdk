// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum _E {
  e1,
  e2;

  static _E get getter => e1;
  static _E method() => e2;
  factory _E.fact() => e1;
}

typedef Public_E = _E;
final Public_E v = _E.e1;

void context(_E e) {}
void contextAlias(Public_E e) {}
