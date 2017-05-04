// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Bar {
  final String name;

  const Bar(this.name);
}

class Foo {
  @Bar('bar')
  int x = 40;

  @Bar('baz')
  final String y = 'hi';
}

void main() {
  dynamic f = new Foo();
  Expect.throws(() {
    f.x = 'hello';
  });
  f.x += 2;
  Expect.equals(f.x, 42);
  Expect.equals(f.y, 'hi');

  var members = reflect(f).type.declarations;
  var x = members[#x] as VariableMirror;
  var y = members[#y] as VariableMirror;
  Expect.equals(x.type.simpleName, #int);
  Expect.equals(y.type.simpleName, #String);
}
