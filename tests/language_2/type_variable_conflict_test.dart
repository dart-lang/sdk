// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we report a compile-time error when a type parameter conflicts
// with an instance or static member with the same name.

import "package:expect/expect.dart";

class G1<T> {
//       ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  var T;
  //  ^
  // [cfe] Conflicts with type variable 'T'.
}

class G2<T> {
//       ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  get T {}
  //  ^
  // [cfe] Conflicts with type variable 'T'.
}

class G3<T> {
//       ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  T() {}
//^
// [cfe] Conflicts with type variable 'T'.
}

class G4<T> {
//       ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  static var T;
  //         ^
  // [cfe] Conflicts with type variable 'T'.
}

class G5<T> {
//       ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  static get T {}
  //         ^
  // [cfe] Conflicts with type variable 'T'.
}

class G6<T> {
//       ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  static T() {}
  //     ^
  // [cfe] Conflicts with type variable 'T'.
}

class G7<T> {
//       ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  set T(_) {}
  //  ^
  // [cfe] Conflicts with type variable 'T'.
}

class G8<T> {
//       ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  static set T(x) {}
  //         ^
  // [cfe] Conflicts with type variable 'T'.
}

main() {
  new G1<int>();
  new G2<int>();
  new G3<int>();
  new G4<int>();
  new G5<int>();
  new G6<int>();
  new G7<int>();
  new G8<int>();
}
