// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test static members.

library lib;

@MirrorsUsed(targets: "lib")
import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'stringify.dart';

class Foo {
  static var hello = {
    'a': 'b',
    'c': 'd',
  };
}

void main() {
  expect('Variable(s(hello) in s(Foo), static)',
      reflectClass(Foo).declarations[#hello]);
  var reflectee = reflectClass(Foo).getField(#hello).reflectee;
  Expect.stringEquals('a, c', reflectee.keys.join(', '));
  // Call the lazy getter twice as different things probably happen in the
  // underlying implementation.
  reflectee = reflectClass(Foo).getField(#hello).reflectee;
  Expect.stringEquals('a, c', reflectee.keys.join(', '));
  var value = 'fisk';
  Foo.hello = value;
  reflectee = reflectClass(Foo).getField(#hello).reflectee;
  Expect.identical(value, reflectee);
}
