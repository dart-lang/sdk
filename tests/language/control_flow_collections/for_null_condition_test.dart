// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  // Null condition expression.
  bool? nullBool = null;
  var a = <int>[for (; nullBool;) 1];
  //                   ^^^^^^^^
  // [analyzer] STATIC_WARNING.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  var b = <int, int>{for (; nullBool;) 1: 1};
  //                        ^^^^^^^^
  // [analyzer] STATIC_WARNING.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  var c = <int>{for (; nullBool;) 1};
  //                   ^^^^^^^^
  // [analyzer] STATIC_WARNING.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}
