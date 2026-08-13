// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C0(var this.str) {
//           ^^^^
// [analyzer] SYNTACTIC_ERROR.INITIALIZING_DECLARING_PARAMETER
// [cfe] Declaring parameters can't be initializing.
  var str;
  //  ^
  // [cfe] 'str' is already declared in this scope.
}

class C1(final this.str) {
//             ^^^^
// [analyzer] SYNTACTIC_ERROR.INITIALIZING_DECLARING_PARAMETER
// [cfe] Declaring parameters can't be initializing.
  final str;
  //    ^
  // [cfe] 'str' is already declared in this scope.
}

class C2(const this.str) {
//       ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'const' here.
  final str;
}

class S3(var str);
class C3(var super.str) extends S3;
//           ^^^^^
// [analyzer] SYNTACTIC_ERROR.SUPER_INITIALIZING_DECLARING_PARAMETER
// [cfe] Declaring parameters can't be super parameters.

class S4(final str);
class C4(final super.str) extends S4;
//             ^^^^^
// [analyzer] SYNTACTIC_ERROR.SUPER_INITIALIZING_DECLARING_PARAMETER
// [cfe] Declaring parameters can't be super parameters.


class S5(final str);
class C5(const super.str) extends S5;
//       ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'const' here.
