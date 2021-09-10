// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.13

class Foo {
  Foo operator >>>(_) => this;
}

extension on Symbol {
  String operator >(_) => "Greater Than used";
  String call(_) => "Called";
}

abstract class Bar implements List<List<List<String>>> {}

main() {
  Foo foo = new Foo();
  foo >>> 42;
  print(foo >>> 42);
  print(foo >>>= 42);
  if ((foo >>>= 42) == foo) {
    print("same");
  }

  print(#>>>(2));
  print(#>>>);

  var x = 10 >>> 2;
  print('x: $x');
}
