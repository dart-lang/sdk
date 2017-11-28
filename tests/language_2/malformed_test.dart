// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:expect/expect.dart' as prefix; // Define 'prefix'.

checkIsUnresolved(var v) {
  v is Unresolved;  //# 00: compile-time error
  v is Unresolved<int>;  //# 01: compile-time error
  v is prefix.Unresolved;  //# 02: compile-time error
  v is prefix.Unresolved<int>;  //# 03: compile-time error
}

checkIsListUnresolved(var v) {
  v is List<Unresolved>;  //# 04: compile-time error
  v is List<Unresolved<int>>;  //# 05: compile-time error
  v is List<prefix.Unresolved>;  //# 06: compile-time error
  v is List<prefix.Unresolved<int>>;  //# 07: compile-time error
  v is List<int, String>;  //# 08: compile-time error
}

checkAsUnresolved(var v) {
  v as Unresolved;  //# 09: compile-time error
  v as Unresolved<int>;  //# 10: compile-time error
  v as prefix.Unresolved;  //# 11: compile-time error
  v as prefix.Unresolved<int>;  //# 12: compile-time error
}

checkAsListUnresolved(var v) {
  v as List<Unresolved>;  //# 13: compile-time error
  v as List<Unresolved<int>>;  //# 14: compile-time error
  v as List<prefix.Unresolved>;  //# 15: compile-time error
  v as List<prefix.Unresolved<int>>;  //# 16: compile-time error
  v as List<int, String>;  //# 17: compile-time error
}

void main() {
  checkIsUnresolved('');
  checkAsUnresolved('');
  checkIsListUnresolved(new List());
  checkAsListUnresolved(new List());

  new undeclared_prefix.Unresolved();  //# 18: compile-time error
  new undeclared_prefix.Unresolved<int>();  //# 19: compile-time error

  try {
    throw 'foo';
  }
    on Unresolved  //# 20: compile-time error
    catch (e) {
  }

  try {
    throw 'foo';
  }
    on Unresolved<int>  //# 21: compile-time error
    catch (e) {
  }

  try {
    throw 'foo';
  }
    on prefix.Unresolved  //# 22: compile-time error
    catch (e) {
  }

  try {
    throw 'foo';
  }
    on prefix.Unresolved<int>  //# 23: compile-time error
    catch (e) {
  }

  try {
    throw 'foo';
  }
    on undeclared_prefix.Unresolved<int> // //# 24: compile-time error
    catch (e) {
  }
}
