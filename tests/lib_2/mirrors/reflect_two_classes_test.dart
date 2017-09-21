// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for http://dartbug.com/23054

library index;

@MirrorsUsed(
    targets: const [Bar, Foo],
    symbols: const ['bar', 'getBar', 'foo', 'getFoo'],
    override: '*')
import 'dart:mirrors';

import 'package:expect/expect.dart';

main() {
  var bar = new Bar();
  var barMirror = reflect(bar);
  Expect.equals(42, barMirror.getField(#bar).reflectee, "bar field");
  Expect.equals(42, barMirror.invoke(#getBar, []).reflectee, "getBar Method");

  var foo = new Foo();
  var fooMirror = reflect(foo);
  Expect.equals(9, fooMirror.getField(#foo).reflectee, "foo field");
  Expect.equals(9, fooMirror.invoke(#getFoo, []).reflectee, "getFoo Method");
}

class Bar {
  int bar = 42;

  int getBar() => bar;
}

class Foo {
  int foo = 9;

  int getFoo() => foo;
}
