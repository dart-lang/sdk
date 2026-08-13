// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formal parameter types of primary constructor are resolved within the body
// scope of the enclosing declaration.

class C(int x) {
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
  // [cfe] 'int' isn't a type.

  static const String int = 'not a type';
}

enum E(int x) {
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
  // [cfe] 'int' isn't a type.
  a(0);

  static const String int = 'not a type';
}

extension type ET(int x) {
  //              ^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
  // [cfe] 'int' isn't a type.

  static const String int = 'not a type';
}
