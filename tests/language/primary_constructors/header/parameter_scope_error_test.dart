// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formal parameter types of primary constructor are resolved within the body
// scope of the enclosing declaration.

// SharedOptions=--enable-experiment=primary-constructors

class C(int x) {
//      ^
// [analyzer] unspecified
// [cfe] 'int' isn't a type.

  static const String int = 'not a type';
}

enum E(int x) {
//     ^
// [cfe] 'int' isn't a type.
// [analyzer] unspecified
  a(0);

  static const String int = 'not a type';
}

extension type ET(int x) {
//                ^
// [analyzer] unspecified
// [cfe] 'int' isn't a type.

  static const String int = 'not a type';
}
