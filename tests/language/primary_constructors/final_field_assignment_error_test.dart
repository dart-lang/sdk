// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The modifier `final` on a parameter in a declaring constructor specifies that
// the instance variable declaration which is induced by this declaring
// constructor parameter is `final`.

// SharedOptions=--enable-experiment=primary-constructors

class C(final int x);

class D(var int x);

void main() {
  var c = C(1);
  c.x = 2;
  //^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL
  // [cfe] The setter 'x' isn't defined for the type 'C'.

  var d = D(1);
  d.x = 2;
}

