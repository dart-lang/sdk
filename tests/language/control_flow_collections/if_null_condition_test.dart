// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  bool? nullBool;
  var a = <int>[if (nullBool) 1];
  //                ^^^^^^^^
  // [analyzer] STATIC_WARNING.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  var b = <int, int>{if (nullBool) 1: 1};
  //                     ^^^^^^^^
  // [analyzer] STATIC_WARNING.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.

  var c = <int>{if (nullBool) 1};
  //                ^^^^^^^^
  // [analyzer] STATIC_WARNING.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}
