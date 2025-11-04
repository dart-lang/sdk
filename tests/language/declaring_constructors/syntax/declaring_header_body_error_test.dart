// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error to have a declaring parameter list both in the header and in
// the body.

// SharedOptions=--enable-experiment=declaring-constructors

class C1(var int x) {
  this(var int y);
  //    ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C2(final int x) {
  this(final int y);
  //    ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
