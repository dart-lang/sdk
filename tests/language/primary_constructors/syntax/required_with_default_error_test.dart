// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error for a named parameter to be both `required` and have a
// default value.

// SharedOptions=--enable-experiment=primary-constructors

class C1({required var int x = 0});
//       ^
// [analyzer] unspecified
// [cfe] unspecified

class C2({required final int x = 0});
//       ^
// [analyzer] unspecified
// [cfe] unspecified

class C3({required int x = 0});
//       ^
// [analyzer] unspecified
// [cfe] unspecified
