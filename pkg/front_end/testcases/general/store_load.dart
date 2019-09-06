// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
class Foo {
  var _field;
}

class FooValue {}

class Bar {
  var _field; // Same name.
}

class BarValue {}

main() {
  var foo = new Foo();
  foo._field = new FooValue();
  var fooValue = foo._field;
  print(fooValue);

  var bar = new Bar();
  bar._field = new BarValue();
  var barValue = bar._field;
  print(barValue);
}
