// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

import 'opted_out_library.dart';

// Test that it is an error to call the default List constructor.
main() {
  var a = new List<int>(3); //# 01: compile-time error
  var b = new List<int?>(3); //# 02: compile-time-error
  var c = new List<int>(); //# 03: compile-time error
  var d = new List<int?>(); //# 04: compile-time error
  List<C> c = new List(5); //# 05: compile-time error
  consumeListOfStringStar(new List(3)); //# 06: compile-time error
}

class A<T> {
  var l = new List<T>(3); //# 07: compile-time error
}

class C {}
