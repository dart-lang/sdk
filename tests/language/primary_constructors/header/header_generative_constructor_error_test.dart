// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A class that has a declaring header constructor cannot have any other
// non-redirecting generative constructors.

// SharedOptions=--enable-experiment=primary-constructors

class C1(var int x) {
  C1.named(this.x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C2(final int x) {
  C2.named(this.x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C3(int x) {
  C3.named(int x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
class C4() {
  C4.named(int x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C5.named(var int x) {
  C5(this.x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C6.named(final int x) {
  C6(this.x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C7.named(int x) {
  C7(int x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C8.named() {
  C8(int x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
