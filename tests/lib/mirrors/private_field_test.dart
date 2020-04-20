// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.mixin;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'private_field_helper.dart';

class Foo extends Bar {
  int _field = 42;

  static int _staticField = 99;
}

var privateSymbol = #_field;
var publicSymbol = #field;

main() {
  Expect.equals(publicSymbol, publicSymbol2);
  Expect.notEquals(privateSymbol, privateSymbol2);

  var foo = new Foo();
  var m = reflect(foo);
  m.setField(privateSymbol, 38);
  Expect.equals(38, foo._field);
  m.setField(privateSymbol2, "world");
  Expect.equals("world", foo.field);
  Expect.equals("world", m.getField(publicSymbol).reflectee);

  var type = reflectClass(Foo);
  Expect.equals(99, type.getField(#_staticField).reflectee);
}
