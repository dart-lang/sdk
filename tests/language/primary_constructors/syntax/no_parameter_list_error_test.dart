// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error if a class does not have a primary constructor, but the body
// of the class contains a primary constructor body.

// SharedOptions=--enable-experiment=primary-constructors

class C {
  this : assert(1 != 2);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
