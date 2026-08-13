// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `id()` calls the `call()` method of the type of `id` if `id` is a getter or
// field. It's a compile-time error if that `call` method does not exist.

class C {
  const C();
  static C get id1 => const C();
  static C id2 = const C();
}

void main() {
  C c1 = .id1();
  //     ^
  // [analyzer] unspecified
  // [cfe] The method 'call' isn't defined for the type 'C'.

  C c2 = .id2();
  //     ^
  // [analyzer] unspecified
  // [cfe] The method 'call' isn't defined for the type 'C'.
}
