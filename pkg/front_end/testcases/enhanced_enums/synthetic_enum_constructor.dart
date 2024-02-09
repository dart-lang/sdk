// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M on Object {
  void mixinMethod() {}
}

enum E with M {
  e1,
  e2,
  e3;
}

enum F {
  f1,
  f2,
  f3,
}

enum G {
  g1,
  g2,
  g3,
  ;

  const G();
}
