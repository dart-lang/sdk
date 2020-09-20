// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin Mixin // cannot `extend` anything.
  extends M //# 01: compile-time error
  extends Object //# 02: compile-time error
{}

// You cannot extend a mixin.
class Class // cannot extend a mixin
  extends Mixin //# 03: compile-time error
{}

void main() {
  // Cannot instantiate a mixin.
  new Mixin();  //# 04: compile-time error
  new Class();
}