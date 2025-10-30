// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It's a compile-time error if an extension type does not contain a declaring
// constructor that has exactly one declaring parameter which is final. This is
// the test for in-body constructors.

// SharedOptions=--enable-experiment=declaring-constructors

extension type ET1 {
  this(var int i);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type ET2 {
  this(var i);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type ET3 {
  this(i);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type ET4 {
  this(final i, final x);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type ET5 {
  this(int i, int x);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type ET6 {
  this(int i);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
