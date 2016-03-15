// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflected_type_generics_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'reflected_type_helper.dart';

class A<T> {}
class G {}

main() {
  expectReflectedType(reflectType(A, [G]), new A<G>().runtimeType);
  expectReflectedType(reflectType(A, [G]), new A<G>().runtimeType);
}
