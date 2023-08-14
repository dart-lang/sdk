// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  int Function(int) f;

  List<num> l = [];
  var a = l.map(f);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int Function(int)' can't be assigned to the parameter type 'dynamic Function(num)'.
}
