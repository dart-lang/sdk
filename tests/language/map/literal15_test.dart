// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the use of `null` keys in const maps.

library map_literal15_test;

import "package:expect/expect.dart";

void main() {
  var m1 = const <String, int>{null: 10, 'null': 20};
  //                           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_KEY_TYPE_NOT_ASSIGNABLE
  // [cfe] The value 'null' can't be assigned to a variable of type 'String' because 'String' is not nullable.

  var m2 = const <Comparable, int>{null: 10, 'null': 20};
  //                               ^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_KEY_TYPE_NOT_ASSIGNABLE
  // [cfe] The value 'null' can't be assigned to a variable of type 'Comparable<dynamic>' because 'Comparable<dynamic>' is not nullable.
}
