// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

import 'opted_out_library.dart';

// Test that it is an error to call the default List constructor with a length
// argument and a type argument which is potentially non-nullable.
main() {
  var a = new List<int>(3); //# 01: compile-time error
  var b = new List<String?>(3);
  List<C> c = List(5); //# 02: compile-time error
  consumeListOfStringStar(new List(3)); //# 03: compile-time error
}

class A<T> {
  var l = new List<T>(3); //# 04: compile-time error
}

class C {}
