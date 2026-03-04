// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declaring parameters named `_` are allowed. Accessing `_` is valid in the
// body part of a primary constructor, or in any construct that accesses
// instance members of C/D/E/Ext, if there is an instance variable with the
// name `_`.

// SharedOptions=--enable-experiment=primary-constructors

import 'package:expect/expect.dart';

class C(var int _) {
  this {
    Expect.equals(_, 1);
  }
}

class C1(var int _, int _);
class C2(int _, var int _);
class C3(int _, var int _, int _);

class D(final int _) {
  this {
    Expect.equals(_, 1);
  }
}

class D1(final int _, int _);
class D2(int _, final int _);
class D3(int _, final int _, int _);

class E(int _, int _) {}

enum E1(final int _) {
  e(1);
}

enum Enum1(final int _, int _) {
  e(1, 2);
}
enum Enum2(int _, final int _) {
  e(1, 2);
}
enum Enum3(int _, final int _, int _) {
  e(1, 2, 3);
}

extension type Ext(int _) {
  this {
    Expect.equals(_, 1);
  }
}

void main() {
  var c = C(1);
  Expect.equals(c._, 1);

  var c1 = C1(1, 2);
  Expect.equals(c1._, 1);
  var c2 = C2(1, 2);
  Expect.equals(c2._, 2);
  var c3 = C3(1, 2, 3);
  Expect.equals(c3._, 2);

  var d = D(1);
  Expect.equals(d._, 1);

  var d1 = D1(1, 2);
  Expect.equals(d1._, 1);
  var d2 = D2(1, 2);
  Expect.equals(d2._, 2);
  var d3 = D3(1, 2, 3);
  Expect.equals(d3._, 2);

  E(1, 2);

  var e1 = E1.e;
  Expect.equals(e1._, 1);

  Expect.equals(Enum1.e._, 1);
  Expect.equals(Enum2.e._, 2);
  Expect.equals(Enum3.e._, 2);

  var ext = Ext(1);
  Expect.equals(ext._, 1);
}
