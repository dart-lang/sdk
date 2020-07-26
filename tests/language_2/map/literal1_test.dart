// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// A type mismatch in a constant map literal is a compile-time error.

main() {
  var m = const
      <String, String>
    {"a": 0};
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.MAP_VALUE_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.
}
