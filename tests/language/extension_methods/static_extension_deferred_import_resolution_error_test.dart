// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "helpers/on_object.dart" deferred as p1 hide OnObject;

void main() {
  Object o = 1;
  OnObject(o).onObject;
//^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_FUNCTION
// [cfe] Method not found: 'OnObject'.
  o.onObject;
  //^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'onObject' isn't defined for the class 'Object'.
}
