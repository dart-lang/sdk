// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It's an error for a class to have two or more declaring constructors.

// SharedOptions=--enable-experiment=declaring-constructors

class C {
  this(var int x);
  this.named(var int y);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type E(final int x){
  this(final int y);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type E(final int x){
  this.named(final int y);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
