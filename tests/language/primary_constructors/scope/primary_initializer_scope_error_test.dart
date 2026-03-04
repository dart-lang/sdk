// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=primary-constructors

// Late variables cannot access primary constructor parameters.
class LateError(int x) {
  late int y = x;
  //           ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

// In non-primary constructors, the parameter `x` is not in scope.
class NotPrimaryConstructor {
  int y = x;
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified
  int z = x + 1;
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified
  NotPrimaryConstructor(int x);
}

// A compile-time error occurs if an assignment to a primary parameter occurs
// in the initializing expression of a non-late instance variable.
class AssignToParameter(int x) {
  int y = x++;
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

// A compile-time error occurs if an assignment to a primary parameter occurs
// in the initializer list of the body part of a primary constructor
class AssignToParameterInitializer(int x) {
  final int y;
  this : y = x++;
  //         ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
