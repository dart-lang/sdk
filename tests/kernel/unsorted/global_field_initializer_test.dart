// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

var intField = 1;
var doubleField = 3.1415;
var stringField = "hello";
var nullField = null;
var nullField2;
var composed = "hello" + " " + "world";

class A {
  static var intField = 1;
  static var doubleField = 3.1415;
  static var stringField = "hello";
  static var nullField = null;
  static var nullField2;
  static var composed = "hello" + " " + "world";
}

main() {
  Expect.isTrue(intField == 1);
  Expect.isTrue(doubleField == 3.1415);
  Expect.isTrue(stringField == "hello");
  Expect.isTrue(nullField == null);
  Expect.isTrue(nullField2 == null);
  Expect.isTrue(composed == "hello world");

  Expect.isTrue(A.intField == 1);
  Expect.isTrue(A.doubleField == 3.1415);
  Expect.isTrue(A.stringField == "hello");
  Expect.isTrue(A.nullField == null);
  Expect.isTrue(A.nullField2 == null);
  Expect.isTrue(A.composed == "hello world");
}
