// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An identifier expression denoting a parameter of a constant primary
// constructor that occurs in the initializer list of the body part of the
// primary constructor, or in an initializing expression of a non-late instance
// variable declaration, is potentially constant.

// SharedOptions=--enable-experiment=primary-constructors

import 'package:expect/expect.dart';

class const A(dynamic d) {
  final int i = d.length;
}

class const C(int p) {
  final int x = p;
  final int y;
  this : y = p;
}

enum const E(int p) {
  e(1);

  final int x = p;
  final int y;
  this : y = p;
}

extension type const Ext(int p) {
  this : assert(p > 0);
}

void main() {
  const A('');

  const c = C(1);
  Expect.equals(1, c.x);
  Expect.equals(1, c.y);

  var c2 = C(2);
  Expect.equals(2, c2.x);
  Expect.equals(2, c2.y);

  const e = E.e;
  Expect.equals(1, e.x);
  Expect.equals(1, e.y);

  const ext = Ext(1);
  Expect.equals(1, ext.p);

  var ext2 = Ext(2);
  Expect.equals(2, ext2.p);
}
