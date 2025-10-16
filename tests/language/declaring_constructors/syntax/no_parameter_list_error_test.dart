// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error to have a declaring constructor in the class body, but
// no declaring parameter list, neither in the header nor in the body.

// SharedOptions=--enable-experiment=declaring-constructors

class C {
  this : assert(1 != 2);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
