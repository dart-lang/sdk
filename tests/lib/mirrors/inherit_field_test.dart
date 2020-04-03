// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test inherited fields.

library test.inherit_field_test;

import 'dart:mirrors';

import 'stringify.dart';

class Foo {
  var field;
}

class Bar extends Foo {}

void main() {
  expect(
      'Variable(s(field) in s(Foo))', reflectClass(Foo).declarations[#field]);
  expect('<null>', reflectClass(Bar).declarations[#field]);
}
